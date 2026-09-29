package com.nutomic.syncthingandroid.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// ============================================================
//  Syncthing Redesign - Compose design tokens
//  These mirror values/colors.xml so the Compose screens
//  (drawer, settings, onboarding) match the XML screens.
//  Dynamic colour is deliberately not used so the brand
//  palette looks identical on every device.
// ============================================================

private val BrandTeal = Color(0xFF00696B)
private val BrandTealLight = Color(0xFF80D4D6)
private val BrandTealContainer = Color(0xFF9CF1F3)
private val BrandTealContainerDark = Color(0xFF004F50)

private val LightColors = lightColorScheme(
    primary = BrandTeal,
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = BrandTealContainer,
    onPrimaryContainer = Color(0xFF002020),
    inversePrimary = BrandTeal,

    secondary = Color(0xFF4A6364),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFCCE8E9),
    onSecondaryContainer = Color(0xFF051F20),

    tertiary = Color(0xFF4B607C),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFD3E4FF),
    onTertiaryContainer = Color(0xFF061C35),

    error = Color(0xFFBA1A1A),
    onError = Color(0xFFFFFFFF),
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),

    background = Color(0xFFF2F7F7),
    onBackground = Color(0xFF191C1C),
    surface = Color(0xFFF2F7F7),
    onSurface = Color(0xFF191C1C),
    surfaceVariant = Color(0xFFDAE5E5),
    onSurfaceVariant = Color(0xFF3F4949),
    surfaceContainer = Color(0xFFFFFFFF),
    surfaceContainerHigh = Color(0xFFE7EEEE),

    outline = Color(0xFF6F7979),
    outlineVariant = Color(0xFFC6D1D1),
    scrim = Color(0xFF000000),
    inverseSurface = Color(0xFF2D3131),
    inverseOnSurface = Color(0xFFEFF1F1),
)

private val DarkColors = darkColorScheme(
    primary = BrandTealLight,
    onPrimary = Color(0xFF003737),
    primaryContainer = BrandTealContainerDark,
    onPrimaryContainer = BrandTealContainer,
    inversePrimary = BrandTealContainer,

    secondary = Color(0xFFB0CCCD),
    onSecondary = Color(0xFF1B3536),
    secondaryContainer = Color(0xFF324B4C),
    onSecondaryContainer = Color(0xFFCCE8E9),

    tertiary = Color(0xFFB3C8E8),
    onTertiary = Color(0xFF1C314B),
    tertiaryContainer = Color(0xFF334863),
    onTertiaryContainer = Color(0xFFD3E4FF),

    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),

    background = Color(0xFF0E1415),
    onBackground = Color(0xFFDEE3E3),
    surface = Color(0xFF0E1415),
    onSurface = Color(0xFFDEE3E3),
    surfaceVariant = Color(0xFF3F4949),
    onSurfaceVariant = Color(0xFFBEC9C9),
    surfaceContainer = Color(0xFF171F20),
    surfaceContainerHigh = Color(0xFF222B2B),

    outline = Color(0xFF899393),
    outlineVariant = Color(0xFF3F4949),
    scrim = Color(0xFF000000),
    inverseSurface = Color(0xFFDEE3E3),
    inverseOnSurface = Color(0xFF2D3131),
)


/**
 * Slightly tightened Material 3 type scale. Titles get more weight and a
 * touch of negative tracking so headings read as headings, while body text
 * keeps generous line height for the dense sync information rows.
 */
private val AppTypography = Typography(
    headlineMedium = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 26.sp,
        lineHeight = 34.sp,
        letterSpacing = (-0.2).sp,
    ),
    headlineSmall = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 22.sp,
        lineHeight = 30.sp,
    ),
    titleLarge = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 28.sp,
    ),
    titleMedium = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.1.sp,
    ),
    titleSmall = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
    ),
    bodyLarge = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp,
    ),
    bodyMedium = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 21.sp,
        letterSpacing = 0.2.sp,
    ),
    bodySmall = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 17.sp,
        letterSpacing = 0.3.sp,
    ),
    labelLarge = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
    ),
    labelMedium = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp,
    ),
    labelSmall = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 15.sp,
        letterSpacing = 0.5.sp,
    ),
)

/** Generously rounded shape scale - the app leans on cards and pills. */
private val AppShapes = Shapes(
    extraSmall = RoundedCornerShape(6.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(18.dp),
    large = RoundedCornerShape(24.dp),
    extraLarge = RoundedCornerShape(32.dp),
)

@Composable
fun ApplicationTheme(
    content: @Composable () -> Unit
) {
    val colorScheme =
        if (isSystemInDarkTheme()) DarkColors else LightColors

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}