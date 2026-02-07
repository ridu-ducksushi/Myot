import 'package:flutter/material.dart';

enum AppThemePalette {
  pink(
    seedColor: Color(0xFFF48FB1),
    persistenceKey: 'pink',
    displayNameKey: 'settings.theme_color_pink',
  ),
  mintGreen(
    seedColor: Color(0xFFA0D9C1),
    persistenceKey: 'mint_green',
    displayNameKey: 'settings.theme_color_mint_green',
  ),
  lavender(
    seedColor: Color(0xFFB8A9D4),
    persistenceKey: 'lavender',
    displayNameKey: 'settings.theme_color_lavender',
  ),
  peach(
    seedColor: Color(0xFFF5C5A3),
    persistenceKey: 'peach',
    displayNameKey: 'settings.theme_color_peach',
  ),
  skyBlue(
    seedColor: Color(0xFFA3C9F5),
    persistenceKey: 'sky_blue',
    displayNameKey: 'settings.theme_color_sky_blue',
  ),
  lemonYellow(
    seedColor: Color(0xFFF5E6A3),
    persistenceKey: 'lemon_yellow',
    displayNameKey: 'settings.theme_color_lemon_yellow',
  );

  const AppThemePalette({
    required this.seedColor,
    required this.persistenceKey,
    required this.displayNameKey,
  });

  final Color seedColor;
  final String persistenceKey;
  final String displayNameKey;

  static AppThemePalette fromPersistenceKey(String key) {
    return AppThemePalette.values.firstWhere(
      (p) => p.persistenceKey == key,
      orElse: () => AppThemePalette.pink,
    );
  }
}
