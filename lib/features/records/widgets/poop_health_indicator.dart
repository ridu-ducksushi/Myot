import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 배변 건강 상태 레벨
enum PoopHealthLevel { normal, caution, danger }

/// 재사용 가능한 배변 건강 상태 배지 위젯
class PoopHealthIndicator extends StatelessWidget {
  const PoopHealthIndicator({super.key, required this.level});

  final PoopHealthLevel level;

  static PoopHealthLevel evaluate(Map<String, dynamic>? value) {
    if (value == null) return PoopHealthLevel.normal;

    final color = value['color'] as String? ?? 'brown';
    final hasBlood = value['has_blood'] as bool? ?? false;
    final hasMucus = value['has_mucus'] as bool? ?? false;
    final consistency = value['consistency'] as String? ?? 'normal';

    // 위험: 붉은/검은색 또는 혈변
    if (color == 'red' || color == 'black' || hasBlood) {
      return PoopHealthLevel.danger;
    }

    // 주의: 노란색/녹색 또는 묽은/딱딱한 농도 또는 점액
    if (color == 'yellow' || color == 'green' || hasMucus) {
      return PoopHealthLevel.caution;
    }
    if (consistency == 'liquid' || consistency == 'hard' ||
        consistency == 'mucus' || consistency == 'soft') {
      return PoopHealthLevel.caution;
    }

    return PoopHealthLevel.normal;
  }

  Color _backgroundColor() {
    switch (level) {
      case PoopHealthLevel.normal:
        return const Color(0xFFE8F5E9);
      case PoopHealthLevel.caution:
        return const Color(0xFFFFF8E1);
      case PoopHealthLevel.danger:
        return const Color(0xFFFFEBEE);
    }
  }

  Color _foregroundColor() {
    switch (level) {
      case PoopHealthLevel.normal:
        return const Color(0xFF2E7D32);
      case PoopHealthLevel.caution:
        return const Color(0xFFF57F17);
      case PoopHealthLevel.danger:
        return const Color(0xFFC62828);
    }
  }

  IconData _icon() {
    switch (level) {
      case PoopHealthLevel.normal:
        return Icons.check_circle;
      case PoopHealthLevel.caution:
        return Icons.warning_amber;
      case PoopHealthLevel.danger:
        return Icons.error;
    }
  }

  String _labelKey() {
    switch (level) {
      case PoopHealthLevel.normal:
        return 'poop_detail.health_normal';
      case PoopHealthLevel.caution:
        return 'poop_detail.health_caution';
      case PoopHealthLevel.danger:
        return 'poop_detail.health_danger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), color: _foregroundColor(), size: 14),
          const SizedBox(width: 4),
          Text(
            _labelKey().tr(),
            style: TextStyle(
              color: _foregroundColor(),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
