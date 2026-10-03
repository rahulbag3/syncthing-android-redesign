$ErrorActionPreference = 'Stop'
$pkg = 'com.rahulbag3.syncthingfork.debug'
$outDir = 'C:\Users\Rahul\OneDrive\Desktop\LiquidMonitor-v0.1-source\backup\LiquidMonitor-v0.1\syncthing-android\app\src\main\play\listings\en-US\graphics\phone-screenshots'

function Tap([int]$x, [int]$y) {
  adb shell input tap $x $y 2>&1 | Out-Null
  Start-Sleep -Seconds 5
}

# Captured from the emulator (1080x2400). Coordinates come from uiautomator
# dumps, not from the scaled screenshots, which are a different size.
function Capture([string]$name) {
  $remote = "/sdcard/shot_$name.png"
  $local = Join-Path $outDir "$name.png"
  adb shell screencap -p $remote 2>&1 | Out-Null
  adb pull $remote $local 2>&1 | Out-Null
  if (-not (Test-Path $local)) { throw "failed to capture $name" }
  Write-Output "  captured $name.png"
}

# Make sure we are on MainActivity before tapping anything. Pressing BACK
# blindly can drop out of the launcher onto a stale editor screen.
function Ensure-Main {
  for ($i = 0; $i -lt 6; $i++) {
    $top = (adb shell dumpsys activity activities 2>&1 | Out-String)
    if ($top -match "$pkg/([\w\.]+)Activities\.MainActivity") { return }
    adb shell am start -n "$pkg/com.nutomic.syncthingandroid.activities.MainActivity" 2>&1 | Out-Null
    Start-Sleep -Seconds 6
  }
  throw 'could not reach MainActivity'
}

function Tap-Tab([int]$x) {
  Ensure-Main
  adb shell input tap $x 2221 2>&1 | Out-Null
  Start-Sleep -Seconds 4
  Ensure-Main
}

# ---------------------------------------------------------------------------
# Syncthing device IDs
#
# A device ID is 32 raw bytes -> base32 (52 chars, uppercase A-Z and 2-7).
# It is then split into 4 blocks of 13 characters, each block gets a Luhn-32
# check character appended (56 chars total), and finally chunkified into
# 8 dash-separated groups of 7. Made-up IDs are rejected by the API unless the
# check digits are correct, so they have to be generated rather than typed.
# Reference: lib/protocol/deviceid.go and lib/protocol/luhn.go
# ---------------------------------------------------------------------------
$script:luhnBase32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

function Get-Codepoint32([char]$c) {
  if ($c -ge 'A' -and $c -le 'Z') { return [int][char]$c - [int][char]'A' }
  if ($c -ge '2' -and $c -le '7') { return [int][char]$c + 26 - [int][char]'2' }
  throw "character '$c' is not in the device ID alphabet"
}

function Get-Luhn32([string]$s) {
  $factor = 1
  $sum = 0
  foreach ($ch in $s.ToCharArray()) {
    $addend = $factor * (Get-Codepoint32 $ch)
    if ($factor -eq 2) { $factor = 1 } else { $factor = 2 }
    $addend = [int]([math]::Floor($addend / 32) + ($addend % 32))
    $sum += $addend
  }
  return $script:luhnBase32[(32 - ($sum % 32)) % 32]
}

function Format-DeviceId([string]$seed52) {
  if ($seed52.Length -ne 52) { throw "seed must be 52 characters, got $($seed52.Length)" }
  $sb = New-Object System.Text.StringBuilder
  for ($i = 0; $i -lt 4; $i++) {
    $block = $seed52.Substring($i * 13, 13)
    [void]$sb.Append($block)
    [void]$sb.Append((Get-Luhn32 $block))
  }
  $id = $sb.ToString()
  $chunks = for ($i = 0; $i -lt 8; $i++) { $id.Substring($i * 7, 7) }
  return ($chunks -join '-')
}

function Test-DeviceIdFormat([string]$deviceId) {
  $id = $deviceId.Replace('-', '')
  if ($id.Length -ne 56) { throw "expected 56 characters, got $($id.Length)" }
  for ($i = 0; $i -lt 4; $i++) {
    $block = $id.Substring($i * 14, 13)
    $check = $id.Substring($i * 14 + 13, 1)
    if ((Get-Luhn32 $block) -ne $check) { throw "check digit $i mismatch in $deviceId" }
  }
  return $true
}

# self-test against this device's own (genuine) ID before trusting the code
Test-DeviceIdFormat 'T367QGM-ASRRR7J-T4HU65T-3ARIRKJ-5N4OUST-EXURNLH-NIMIV5A-MPODEAJ'
Write-Output 'device ID generator self-test passed'
$cfg = (adb shell run-as $pkg cat files/config.xml | Out-String)
$key = [regex]::Match($cfg, '<apikey>([^<]+)</apikey>').Groups[1].Value
$guiPort = [regex]::Match($cfg, '<address>127\.0\.0\.1:(\d+)</address>').Groups[1].Value
if (-not $key) { throw 'apikey not found' }
Write-Output "apikey=$key guiPort=$guiPort"

adb forward tcp:18384 "tcp:$guiPort" | Out-Null
Start-Sleep -Seconds 2
# curl -k: the GUI serves HTTPS with a self-signed certificate
$base = "https://127.0.0.1:18384/rest"
function ApiGet($path) {
  $json = curl.exe -sk -H "X-API-Key: $key" "$base$path" | Out-String
  if (-not $json.Trim()) { throw "empty response for $path" }
  return ($json | ConvertFrom-Json)
}
function ApiPut($path, $obj) {
  $tmpFile = Join-Path $env:TEMP 'api_body.json'
  [System.IO.File]::WriteAllText($tmpFile, ($obj | ConvertTo-Json -Depth 8 -Compress))
  # this Syncthing version only allows PUT on config endpoints (POST returns 405)
  $code = curl.exe -sk -o NUL -w '%{http_code}' -X PUT -H "X-API-Key: $key" -H 'Content-Type: application/json' --data-binary "@$tmpFile" "$base$path"
  if ($code.Trim() -ne '200') {
    $detail = curl.exe -sk -X PUT -H "X-API-Key: $key" -H 'Content-Type: application/json' --data-binary "@$tmpFile" "$base$path"
    throw "PUT $path failed with HTTP $($code.Trim()): $detail"
  }
}

# 52 base32 characters per device; only A-Z and 2-7 are legal
$devices = @(
  @{ seed='SJRNEUAUNLXFTBBZHH3TGNA6YNON4FQ3G6ZOZ7Z2LKDNUF2GVH57'; name='Anna'  },
  @{ seed='CC7FJTVWGSXI337UIT7INAH3KSJSTHXUIRYD6TEGKCUYS3SYGF6C'; name='Dad'   },
  @{ seed='IURC2E3WJCC63D7JC3VUOY6LMOJPARMNJVLTAWJ2YO5H7V5P3IVK'; name='Felix' },
  @{ seed='QJTQVFVL2MWXWUUGXLJLS24A3XLWQ2TX3B5AB352A57LXFQKBXXP'; name='Kevin' },
  @{ seed='7KXWMTV6272AY74UXUE3OOLU2QJVGAUZCEXRKHTNG7ABC7TXJ3TM'; name='Mum'   }
)

$status = ApiGet '/system/status'
$self = $status.myID
Write-Output "selfDeviceID=$self"

$idOf = @{}
foreach ($d in $devices) {
  $id = Format-DeviceId $d.seed
  Test-DeviceIdFormat $id
  $idOf[$d.name] = $id
  ApiPut "/config/devices/$id" @{
    deviceID = $id
    name     = $d.name
    addresses = @('dynamic')
    compression = 'metadata'
    introducer = $false
    autoAcceptFolders = $true
    untrusted = $false
  }
  Write-Output "  added device: $($d.name) = $id"
}

$folderSpecs = @(
  @{ id='documents'; label='Documents'; path='/sdcard/Documents'; share=@('Anna','Felix','Kevin') },
  @{ id='pictures';  label='Pictures';  path='/sdcard/Pictures';  share=@('Anna','Felix','Kevin','Mum') },
  @{ id='music';     label='Music';     path='/sdcard/Music';     share=@('Felix','Kevin') }
)

foreach ($f in $folderSpecs) {
  $shareIds = @(@{ deviceID = $self }) + ($f.share | ForEach-Object { @{ deviceID = $idOf[$_] } })
  ApiPut "/config/folders/$($f.id)" @{
    id       = $f.id
    label    = $f.label
    path     = $f.path
    type     = 'sendreceive'
    devices  = $shareIds
    rescanIntervalS = 3600
    fsWatcherEnabled = $true
    fsWatcherDelayS = 10
    ignorePerms = $true
    autoNormalize = $true
    versioning = @{ type='trashcan'; params=@{ cleanoutDays='14' } }
  }
  Write-Output "  added folder: $($f.label) -> $($f.path) (shared with $($f.share -join ', '))"
}

# verify through the API
$vDev = ApiGet '/config/devices'
$vFld = ApiGet '/config/folders'
Write-Output "VERIFY devices=$(@($vDev).Count) folders=$(@($vFld).Count)"
foreach ($f in $vFld) { Write-Output ("  folder: " + $f.label + " -> " + $f.path) }
foreach ($d in $vDev) { Write-Output ("  device: " + $d.name) }

if (@($vFld).Count -lt 3) { throw 'folders did not persist' }
if (@($vDev).Count -lt 6) { throw 'devices did not persist' }

# ---------------------------------------------------------------------------
# Screenshots
#
# Play requires 320-3840 px on the long edge; these are captured at the
# emulator's native 1080x2400, which is well inside that range.
# ---------------------------------------------------------------------------
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# Folder cards on the FOLDERS tab are not clickable in this build (tapping the
# folder icon opens the system directory picker instead), so the sixth shot is
# Settings, reached from the drawer. Drawer rows sit at these real-pixel
# coordinates on the 1080x2400 emulator:
#   Show device ID 275,318   Recent changes 282,441   Settings 219,2016
adb shell am force-stop $pkg 2>&1 | Out-Null
Start-Sleep -Seconds 3
adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
Start-Sleep -Seconds 16
Ensure-Main

Tap-Tab 190             # FOLDERS
Capture '1-folders'

Tap-Tab 540             # DEVICES
Capture '2-devices'

Tap-Tab 858             # STATUS
Capture '3-status'

# navigation drawer
Tap-Tab 190
Tap 62 114
Capture '4-drawer'

# "Show device ID" opens the QR dialog; close it with Finish afterwards
Tap 275 318
Capture '5-device-id-qr'
Tap 751 1571

# Settings
Tap 62 114
Tap 219 2016
Capture '6-settings'

Write-Output "screenshots written to $outDir"