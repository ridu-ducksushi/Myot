import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/utils/app_logger.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _currentPetId;

  // In-memory route history for tab navigation (stores previous locations)
  final List<String> _routeHistory = <String>[];

  @override
  void initState() {
    super.initState();
    _loadLastSelectedPetId();
    _loadRouteHistory();
  }

  Future<void> _loadLastSelectedPetId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('last_selected_pet_id');
      if (mounted && saved != null && saved.isNotEmpty) {
        setState(() => _currentPetId = saved);
      }
    } catch (_) {}
  }

  Future<void> _loadRouteHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('route_history');
      if (saved != null && saved.isNotEmpty) {
        _routeHistory.addAll(saved);
        AppLogger.d('Home', 'Loaded history: $_routeHistory');
      }
    } catch (_) {}
  }

  Future<void> _saveRouteHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('route_history', _routeHistory);
    } catch (_) {}
  }

  Future<void> _saveLastSelectedPetId(String petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_pet_id', petId);
    } catch (_) {}
  }

  void _onPopInvoked(bool didPop) async {
    if (didPop) return;

    final location = GoRouterState.of(context).matchedLocation;
    AppLogger.d('Home', 'Back pressed from: $location');
    AppLogger.d('Home', 'History: $_routeHistory');

    // If we have history, go back to the last location
    if (_routeHistory.isNotEmpty) {
      final target = _routeHistory.removeLast();
      await _saveRouteHistory(); // Save after removing
      AppLogger.d('Home', 'Navigating to: $target');
      context.go(target);
      return;
    }

    AppLogger.w('Home', 'No history available');

    // Check if we're on a pet detail page (profile tab)
    final isPetDetailPage = location.startsWith('/pets/') &&
                            !location.endsWith('/records') &&
                            !location.endsWith('/health') &&
                            location.split('/').length == 3;

    if (isPetDetailPage) {
      AppLogger.d('Home', 'From pet detail to pet list: /');
      context.go('/');
      return;
    }

    // If on settings and no history, go to a safe pet route or root
    if (location == '/settings' || location.startsWith('/settings')) {
      try {
        String? petId = _currentPetId;
        if (petId == null || petId.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          petId = prefs.getString('last_selected_pet_id');
        }
        if (petId != null && petId.isNotEmpty) {
          AppLogger.d('Home', 'Fallback to pet detail: /pets/$petId');
          context.go('/pets/$petId');
        } else {
          AppLogger.d('Home', 'Fallback to root: /');
          context.go('/');
        }
        return;
      } catch (_) {
        context.go('/');
        return;
      }
    }

    AppLogger.d('Home', 'Allowing system back');
  }

  Widget _buildTabIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Icon(
      icon,
      size: 28,
      color: isSelected 
          ? colorScheme.onPrimaryContainer 
          : colorScheme.onSurfaceVariant.withOpacity(0.6),
    );
  }
  
  Widget _buildTabItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.primaryContainer 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected 
                ? colorScheme.onPrimaryContainer 
                : colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isSelected ? 12 : 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                  ? colorScheme.onPrimaryContainer 
                  : colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTap(int index) {
    // Skip if already on this tab
    if (_currentIndex == index) return;

    // Save current location to history before navigating
    final currentLocation = GoRouterState.of(context).matchedLocation;
    AppLogger.d('Home', 'Tab tapped: $index, Current location: $currentLocation');
    if (_routeHistory.isEmpty || _routeHistory.last != currentLocation) {
      _routeHistory
        ..clear()
        ..add(currentLocation);
      _saveRouteHistory(); // Save immediately
      AppLogger.d('Home', 'Added to history: $currentLocation');
      AppLogger.d('Home', 'History now: $_routeHistory');
    } else {
      AppLogger.d('Home', 'Skipped duplicate: $currentLocation');
    }

    setState(() => _currentIndex = index);
    
    if (_currentPetId != null) {
      switch (index) {
        case 0:
          _saveLastSelectedPetId(_currentPetId!);
          context.go('/pets/$_currentPetId');
          break;
        case 1:
          _saveLastSelectedPetId(_currentPetId!);
          context.go('/pets/$_currentPetId/records');
          break;
        case 2:
          _saveLastSelectedPetId(_currentPetId!);
          context.go('/pets/$_currentPetId/health');
          break;
        case 3:
          context.go('/settings');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final petsState = ref.watch(petsProvider);
    
    // 펫 상세 화면과 설정 화면에서 하단 탭 표시
    final isPetDetailRoute = location.startsWith('/pets/') && location.split('/').length >= 3;
    final isSettingsRoute = location == '/settings' || location.startsWith('/settings');
    final shouldShowBottomNav = isPetDetailRoute || isSettingsRoute;
    
    if (shouldShowBottomNav) {
      // 펫 ID 추출
      if (isPetDetailRoute) {
        final parts = location.split('/');
        if (parts.length >= 3) {
          _currentPetId = parts[2];
          _saveLastSelectedPetId(_currentPetId!);
        }
      } else if (_currentPetId == null) {
        // 설정 화면에서 재구성된 경우 마지막 선택 펫 복원 → 없으면 첫 번째 펫
        // _loadLastSelectedPetId() 비동기 복원을 기다리는 동안 일시 폴백
        if (petsState.pets.isNotEmpty) {
          _currentPetId = petsState.pets.first.id;
        }
      }
      
      // 탭 인덱스 결정
      if (location.endsWith('/records')) {
        _currentIndex = 1;
      } else if (location.endsWith('/health')) {
        _currentIndex = 2;
      } else if (isSettingsRoute) {
        _currentIndex = 3;
      } else {
        _currentIndex = 0;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: shouldShowBottomNav
            ? SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _onTabTap(0),
                          child: _buildTabItem(Icons.pets, 'tabs.profile'.tr(), 0),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onTabTap(1),
                          child: _buildTabItem(Icons.list_alt, 'tabs.records'.tr(), 1),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onTabTap(2),
                          child: _buildTabItem(Icons.favorite, 'tabs.health'.tr(), 2),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onTabTap(3),
                          child: _buildTabItem(Icons.settings, 'tabs.settings'.tr(), 3),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
