import 'package:flutter/material.dart';

class AppGradients {
  const AppGradients._();

  static LinearGradient softBackground(ColorScheme cs) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cs.primaryContainer.withOpacity(0.35),
          cs.surface,
        ],
        stops: const [0.0, 0.45],
      );

  static List<BoxShadow> softCardShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.primary.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> softTileShadow(ColorScheme cs) => [
        BoxShadow(
          color: cs.primary.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];
}
