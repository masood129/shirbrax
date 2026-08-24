import 'package:flutter/material.dart';

/// ShirBrax Color System — Material 3 tokens
/// Design: Vibrant & Block-based | Primary: Rose Red
abstract class AppColors {
  // ─── Brand Primaries ──────────────────────────────────────
  static const primary = Color(0xFFE11D48);       // رز قرمز
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFFE4E8);
  static const onPrimaryContainer = Color(0xFF881337);

  // ─── Secondary ────────────────────────────────────────────
  static const secondary = Color(0xFFFB7185);
  static const onSecondary = Color(0xFF0F172A);
  static const secondaryContainer = Color(0xFFFFD9DC);
  static const onSecondaryContainer = Color(0xFF881337);

  // ─── Accent / CTA ─────────────────────────────────────────
  static const accent = Color(0xFF2563EB);
  static const onAccent = Color(0xFFFFFFFF);
  static const accentContainer = Color(0xFFDBEAFE);
  static const onAccentContainer = Color(0xFF1D4ED8);

  // ─── Background & Surface ─────────────────────────────────
  static const background = Color(0xFFFFF1F2);
  static const onBackground = Color(0xFF1A0A0D);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1A0A0D);
  static const surfaceVariant = Color(0xFFF0ECF2);
  static const onSurfaceVariant = Color(0xFF475569);

  // ─── Dark Mode ────────────────────────────────────────────
  static const darkBackground = Color(0xFF0D0408);
  static const darkSurface = Color(0xFF1A0C10);
  static const darkSurfaceVariant = Color(0xFF2D1520);
  static const darkOnSurface = Color(0xFFF8E4E7);
  static const darkOnSurfaceVariant = Color(0xFFCDB5BA);

  // ─── Semantic ─────────────────────────────────────────────
  static const error = Color(0xFFDC2626);
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF16A34A);
  static const onSuccess = Color(0xFFFFFFFF);
  static const warning = Color(0xFFD97706);
  static const onWarning = Color(0xFFFFFFFF);
  static const info = Color(0xFF2563EB);

  // ─── Neutral ──────────────────────────────────────────────
  static const border = Color(0xFFFECDD3);
  static const muted = Color(0xFFF0ECF2);
  static const mutedForeground = Color(0xFF475569);
  static const divider = Color(0xFFFFE4E8);

  // ─── Gradients ────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
  );

  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
  );

  static const gradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D0408), Color(0xFF1A0C10)],
  );
}
