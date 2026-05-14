import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PetTool {
  const PetTool({
    required this.icon,
    required this.labelKey,
    required this.routeBuilder,
  });

  final IconData icon;
  final String labelKey;
  final String Function(String petId) routeBuilder;

  String label() => labelKey.tr();
  String route(String petId) => routeBuilder(petId);

  static List<PetTool> all() => const [
        PetTool(
          icon: Icons.vaccines_outlined,
          labelKey: 'tools.vaccination',
          routeBuilder: _buildVaccinationRoute,
        ),
        PetTool(
          icon: Icons.content_cut_outlined,
          labelKey: 'tools.grooming',
          routeBuilder: _buildGroomingRoute,
        ),
        PetTool(
          icon: Icons.warning_amber_outlined,
          labelKey: 'tools.allergy',
          routeBuilder: _buildAllergyRoute,
        ),
        PetTool(
          icon: Icons.calculate_outlined,
          labelKey: 'tools.food_calc',
          routeBuilder: _buildFoodCalcRoute,
        ),
        PetTool(
          icon: Icons.phone_outlined,
          labelKey: 'tools.emergency',
          routeBuilder: _buildEmergencyRoute,
        ),
        PetTool(
          icon: Icons.description_outlined,
          labelKey: 'tools.report',
          routeBuilder: _buildReportRoute,
        ),
        PetTool(
          icon: Icons.monitor_weight_outlined,
          labelKey: 'tools.weight_guide',
          routeBuilder: _buildWeightGuideRoute,
        ),
      ];
}

String _buildVaccinationRoute(String petId) => '/pets/$petId/vaccination';
String _buildGroomingRoute(String petId) => '/pets/$petId/grooming';
String _buildAllergyRoute(String petId) => '/pets/$petId/allergies';
String _buildFoodCalcRoute(String petId) => '/pets/$petId/food-calculator';
String _buildEmergencyRoute(String petId) => '/pets/$petId/emergency-contacts';
String _buildReportRoute(String petId) => '/pets/$petId/report';
String _buildWeightGuideRoute(String petId) => '/pets/$petId/weight-guide';
