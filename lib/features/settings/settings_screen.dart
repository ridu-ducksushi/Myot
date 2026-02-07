import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/theme_provider.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/services/image_service.dart';
import 'package:petcare/data/services/backup_service.dart';
import 'package:petcare/features/pets/pets_screen.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/ui/theme/app_colors.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/ui/widgets/app_record_calendar.dart';
import 'package:petcare/ui/widgets/add_pet_sheet.dart';
import 'package:petcare/utils/app_constants.dart';
import 'package:petcare/utils/app_logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    // Supabase 인증 상태 변화를 감지
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'system';
    if (mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // 캐시는 사용자 스코프 키로 분리되어 있으므로 전역 삭제하지 않음
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings.logout_success'.tr())));
      }
      // The GoRouter redirect will handle navigation to the login screen.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'settings.logout_failed'.tr()}: $e')),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    // 현재 로그인한 사용자의 이메일 가져오기
    String userEmail = '';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null) {
        userEmail = user!.email!;
      }
    } catch (e) {
      // 이메일 가져오기 실패 시 빈 값으로 시작
    }

    // 다이얼로그 없이 바로 메일 앱 열기
    await _sendInquiryEmail(context, userEmail, '');
  }

  Future<void> _sendInquiryEmail(BuildContext context, String userEmail, String inquiry) async {
    try {
      final email = 'contact.email'.tr();
      final subject = 'contact.email_subject'.tr();
      final body = 'contact.email_body_template'.tr(namedArgs: {
        'email': userEmail,
        'inquiry': inquiry,
      });

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      // canLaunchUrl 체크를 건너뛰고 직접 실행 시도
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('contact.email_sent'.tr())),
          );
        }
      } else {
        // 이메일 앱 실행 실패 시 클립보드에 복사
        await _copyEmailToClipboard(context, email);
      }
    } catch (e) {
      // 오류 발생 시에도 클립보드에 복사
      final email = 'contact.email'.tr();
      await _copyEmailToClipboard(context, email, error: e);
    }
  }

  Future<void> _copyEmailToClipboard(
    BuildContext context,
    String email, {
    Object? error,
  }) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error != null
                ? '${'contact.email_copied'.tr()} 오류: $error'
                : 'contact.email_copied'.tr(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteRequest(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.delete_account_title'.tr()),
        content: Text('settings.delete_account_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('settings.delete_account_confirm'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      await _performHardDelete(context);
    }
  }

  Future<void> _performHardDelete(BuildContext context) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings.delete_account_require_login'.tr()),
            ),
          );
        }
        return;
      }

      AppLogger.d('Settings', '계정 삭제 시작: ${user.id}');

      // Ensure fresh session (older emulators may have skew causing token invalidation)
      try {
        AppLogger.d('Settings', '세션 새로고침 시도...');
        await Supabase.instance.client.auth.refreshSession();
        AppLogger.d('Settings', '세션 새로고침 성공');
      } catch (e) {
        AppLogger.w('Settings', '세션 새로고침 실패 (무시하고 진행): $e');
      }

      // Invoke Edge Function with JWT to delete server-side data and auth user
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings.delete_account_session_expired'.tr()),
            ),
          );
        }
        return;
      }

      AppLogger.d('Settings', 'JWT 토큰 획득 완료: ${token.substring(0, 20)}...');

      Future<dynamic> _call() async {
        AppLogger.d('Settings', 'Edge Function 호출 중...');
        final result = await Supabase.instance.client.functions.invoke(
          'delete-account',
          body: const {},
          headers: {'Authorization': 'Bearer $token'},
        );
        AppLogger.d('Settings', 'Edge Function 응답: ${result.data}');
        return result;
      }

      dynamic response;
      try {
        response = await _call().timeout(
          AppConstants.edgeFunctionTimeout,
          onTimeout: () {
            AppLogger.w(
              'Settings',
              'Edge Function 타임아웃 (${AppConstants.edgeFunctionTimeout.inSeconds}초)',
            );
            throw TimeoutException('settings.delete_account_timeout'.tr());
          },
        );
      } on TimeoutException catch (e) {
        AppLogger.w('Settings', '첫 시도 타임아웃, 재시도 중...');
        // One-time retry for slow/older emulators or flaky network
        response = await _call().timeout(
          AppConstants.edgeFunctionTimeout,
          onTimeout: () {
            AppLogger.w(
              'Settings',
              'Edge Function 재시도 타임아웃 (${AppConstants.edgeFunctionTimeout.inSeconds}초)',
            );
            throw TimeoutException(
              '${'settings.delete_account_timeout'.tr()} (재시도 실패)',
            );
          },
        );
      }

      AppLogger.d('Settings', 'Edge Function 응답 타입: ${response.runtimeType}');
      AppLogger.d('Settings', 'Edge Function 응답 데이터: ${response.data}');

      // Check response
      final data = response.data;
      final isSuccess = data is Map && data['ok'] == true;

      if (!isSuccess) {
        final errorDetail = data is Map
            ? (data['error']?.toString() ?? data.toString())
            : data?.toString() ?? '알 수 없는 오류';
        AppLogger.e('Settings', 'Edge Function 실패: $errorDetail');
        throw Exception(
          '${'settings.delete_account_server_failed'.tr()}: $errorDetail',
        );
      }

      AppLogger.d('Settings', '서버 데이터 삭제 완료');

      // Clear local scoped caches
      AppLogger.d('Settings', '로컬 캐시 삭제 중...');
      await LocalDatabase.instance.clearAll();
      AppLogger.d('Settings', '로컬 캐시 삭제 완료');

      // Delete all locally saved images
      AppLogger.d('Settings', '로컬 이미지 삭제 중...');
      await ImageService.deleteAllSavedImages();
      AppLogger.d('Settings', '로컬 이미지 삭제 완료');

      // Sign out locally (session becomes invalid anyway after auth deletion)
      AppLogger.d('Settings', '로그아웃 중...');
      await Supabase.instance.client.auth.signOut();
      AppLogger.d('Settings', '로그아웃 완료');
      AppLogger.d('Settings', '계정 삭제 완료');

      // Navigation will happen automatically via auth redirect (GoRouter)
      // No need to manually pop or navigate
    } catch (e, stackTrace) {
      AppLogger.e('Settings', '계정 삭제 오류', e, stackTrace);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'settings.delete_account_error'.tr()}\n오류: ${e.toString()}',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'settings.delete_account_inquiry'.tr(),
              onPressed: () => _sendEmail(context),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showDeletePetDialog(
    BuildContext context,
    WidgetRef ref,
    Pet pet,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('pets.delete_confirm_title'.tr()),
        content: Text('pets.delete_confirm_message'.tr(args: [pet.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(petsProvider.notifier).deletePet(pet.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('pets.delete_success'.tr(args: [pet.name])),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('pets.delete_error'.tr(args: [pet.name])),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petsProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    // 현재 선택된 펫 ID 추출
    String? currentPetId;
    if (currentLocation.startsWith('/pets/')) {
      final parts = currentLocation.split('/');
      if (parts.length >= 3) {
        currentPetId = parts[2];
      }
    }
    // 설정 화면에서 진입 시에는 라우트에 펫 ID가 없으므로 마지막 선택 펫을 복원
    Future<String?> loadLastSelectedPetId() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('last_selected_pet_id');
      } catch (_) {
        return null;
      }
    }

    final currentPet = currentPetId != null
        ? petsState.pets.where((pet) => pet.id == currentPetId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('tabs.settings'.tr()),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: ListView(
        children: [
          // 사용자 프로필 섹션
          _buildUserProfileSection(context),

          const SizedBox(height: 2),

          // 펫 정보 섹션 (통합)
          SectionHeader(title: 'settings.pet_info'.tr()),

          // 가로 스크롤 가능한 펫 카드들
          SizedBox(
            height: AppConstants.petCardHeight,
            child: FutureBuilder<String?>(
              future: currentPetId != null
                  ? Future.value(currentPetId)
                  : loadLastSelectedPetId(),
              builder: (context, snapshot) {
                final preferredId = currentPetId ?? snapshot.data;
                // 선호 펫 ID를 첫 번째로 배치한 리스트 구성
                final pets = List<Pet>.from(petsState.pets);
                if (preferredId != null) {
                  final idx = pets.indexWhere((p) => p.id == preferredId);
                  if (idx > 0) {
                    final selected = pets.removeAt(idx);
                    pets.insert(0, selected);
                  }
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.none,
                  itemCount: pets.length + 1, // 펫들 + 새 펫 추가 카드
                  itemBuilder: (context, index) {
                    if (index < pets.length) {
                      // 기존 펫 카드
                      final pet = pets[index];
                      final isSelected = pet.id == preferredId;
                      return Container(
                        width: AppConstants.petCardWidth,
                        margin: EdgeInsets.only(
                          right: AppConstants.petCardSpacing,
                        ),
                        child: _buildHorizontalPetCard(
                          context,
                          ref,
                          pet,
                          isSelected: isSelected,
                        ),
                      );
                    } else {
                      // 새 펫 추가 카드
                      return Container(
                        width: AppConstants.petCardWidth,
                        child: _buildAddPetCard(context),
                      );
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 2),

          // 문의하기 섹션
          SectionHeader(title: 'contact.title'.tr()),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.email, color: AppColors.primary),
              title: Text('contact.email'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _sendEmail(context),
            ),
          ),

          const SizedBox(height: 2),

          // 앱 설정 섹션 (언어/테마)
          SectionHeader(title: 'settings.app_settings'.tr()),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text('settings.language'.tr()),
              subtitle: Text(_getCurrentLanguageName(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.palette, color: AppColors.primary),
              title: Text('settings.theme'.tr()),
              subtitle: Text(_getCurrentThemeModeName(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showThemeDialog(context),
            ),
          ),

          const SizedBox(height: 2),

          // 데이터 관리 섹션
          SectionHeader(title: 'settings.backup_restore'.tr()),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.primary),
              title: Text('settings.export_data'.tr()),
              subtitle: Text('settings.export_data_description'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _exportData(context),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.download, color: AppColors.primary),
              title: Text('settings.import_data'.tr()),
              subtitle: Text('settings.import_data_description'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _importData(context),
            ),
          ),

          const SizedBox(height: 2),

          // 계정 설정 섹션
          SectionHeader(title: 'settings.account_settings'.tr()),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('settings.logout'.tr()),
              subtitle: Text('settings.logout_description'.tr()),
              onTap: () => _signOut(context),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text('settings.delete_account'.tr()),
              subtitle: Text('settings.delete_account_description'.tr()),
              onTap: () => _confirmDeleteRequest(context),
            ),
          ),

        ],
      ),
    );
  }

  String _getCurrentLanguageName(BuildContext context) {
    final locale = context.locale;
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      default:
        return locale.languageCode;
    }
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final languages = [
      {'code': 'ko', 'name': '한국어'},
      {'code': 'en', 'name': 'English'},
      {'code': 'ja', 'name': '日本語'},
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('settings.language'.tr()),
        children: languages.map((lang) {
          final isSelected = context.locale.languageCode == lang['code'];
          return SimpleDialogOption(
            onPressed: () {
              context.setLocale(Locale(lang['code']!));
              Navigator.of(dialogContext).pop();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lang['name']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getCurrentThemeModeName(BuildContext context) {
    switch (_themeMode) {
      case 'light':
        return 'settings.theme_light'.tr();
      case 'dark':
        return 'settings.theme_dark'.tr();
      case 'system':
      default:
        return 'settings.theme_system'.tr();
    }
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final themes = [
      {'key': 'system', 'label': 'settings.theme_system'.tr()},
      {'key': 'light', 'label': 'settings.theme_light'.tr()},
      {'key': 'dark', 'label': 'settings.theme_dark'.tr()},
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('settings.theme'.tr()),
        children: themes.map((theme) {
          final isSelected = _themeMode == theme['key'];
          return SimpleDialogOption(
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(theme['key']!);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                setState(() {
                  _themeMode = theme['key']!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('settings.theme_changed'.tr())),
                );
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    theme['label']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.exporting'.tr())),
      );
      await BackupService.shareBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.export_success'.tr())),
        );
      }
    } catch (e) {
      AppLogger.e('Settings', 'Export failed', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.export_error'.tr())),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.import_confirm_title'.tr()),
        content: Text('settings.import_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('settings.import_confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final importResult = await BackupService.importFromFile(filePath);

      if (context.mounted) {
        final message = 'settings.import_success'.tr(args: [
          importResult.petsImported.toString(),
          importResult.recordsImported.toString(),
          importResult.remindersImported.toString(),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        if (importResult.totalSkipped > 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings.import_skipped'.tr(
                args: [importResult.totalSkipped.toString()],
              )),
            ),
          );
        }

        // Refresh pets list
        ref.invalidate(petsProvider);
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.import_invalid_format'.tr())),
        );
      }
    } catch (e) {
      AppLogger.e('Settings', 'Import failed', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.import_error'.tr())),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) => const _EditProfileSheet(),
    );
  }

  Widget _buildUserProfileSection(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    // 게스트 사용자 확인: email이 null이거나 비어있으면 게스트
    final isGuest = user?.email == null || (user!.email?.isEmpty ?? true);
    
    final email = isGuest ? 'settings.guest_account'.tr() : (user?.email ?? 'Unknown');
    final displayName = isGuest
        ? 'settings.guest'.tr()
        : (user?.userMetadata?['display_name'] as String? ??
            user?.userMetadata?['full_name'] as String? ??
            email.split('@').first);

    return Container(
      margin: const EdgeInsets.all(16),
      child: AppCard(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEditProfileDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'settings.my_profile'.tr(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalPetCard(
    BuildContext context,
    WidgetRef ref,
    pet, {
    bool isSelected = false,
  }) {
    final speciesColor = AppColors.getSpeciesColor(pet.species);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AppCard(
      margin: EdgeInsets.zero,
      elevation: isSelected
          ? AppConstants.selectedPetElevation
          : AppConstants.defaultPetElevation,
      onTap: () => context.go('/pets/${pet.id}'),
      onLongPress: () => _showDeletePetDialog(context, ref, pet),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: primaryColor,
                  width: AppConstants.selectedPetBorderWidth,
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 펫 아바타
              Container(
                width: AppConstants.avatarSize,
                height: AppConstants.avatarSize,
                decoration: BoxDecoration(
                  color: speciesColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.avatarSize / 2,
                  ),
                  border: Border.all(
                    color: speciesColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: pet.defaultIcon != null
                    ? _buildDefaultIcon(
                        context,
                        pet.defaultIcon,
                        speciesColor,
                        species: pet.species,
                        bgColor: pet.profileBgColor,
                      )
                    : pet.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.avatarSize / 2,
                        ),
                        child: Image.file(
                          File(pet.avatarUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultIcon(
                                context,
                                pet.defaultIcon,
                                speciesColor,
                                species: pet.species,
                                bgColor: pet.profileBgColor,
                              ),
                        ),
                      )
                    : _buildDefaultIcon(
                        context,
                        pet.defaultIcon,
                        speciesColor,
                        species: pet.species,
                        bgColor: pet.profileBgColor,
                      ),
              ),
              SizedBox(height: AppConstants.mediumSpacing),

              // 펫 이름
              Text(
                pet.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppConstants.defaultPadding,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppConstants.smallSpacing),

              // 펫 종류
              Transform.scale(
                scale: 0.8,
                child: PetSpeciesChip(species: pet.species),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetCard(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => _showAddPetDialog(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 추가 아이콘
            Container(
              width: AppConstants.avatarSize,
              height: AppConstants.avatarSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.avatarSize / 2,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: AppConstants.iconSize,
              ),
            ),
            SizedBox(height: AppConstants.mediumSpacing),

            // 추가 텍스트
            Text(
              'settings.add_pet'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: AppConstants.defaultPadding,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPetDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) => const AddPetSheet(),
    );
  }

  Widget _buildDefaultIcon(
    BuildContext context,
    String? defaultIcon,
    Color fallbackColor, {
    String? species,
    String? bgColor,
  }) {
    if (defaultIcon != null) {
      // Supabase Storage에서 이미지 URL 가져오기
      final imageUrl = ImageService.getDefaultIconUrl(
        species ?? 'cat',
        defaultIcon,
      );
      if (imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.avatarSize / 2),
          child: Stack(
            children: [
              // 배경색
              if (bgColor != null)
                Image.asset(
                  'assets/images/profile_bg/$bgColor.png',
                  width: AppConstants.avatarSize,
                  height: AppConstants.avatarSize,
                  fit: BoxFit.cover,
                ),
              // 아이콘
              Image.asset(
                imageUrl,
                width: AppConstants.avatarSize,
                height: AppConstants.avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Assets 이미지 로드 실패 시 기존 아이콘으로 폴백
                  final iconData = _getDefaultIconData(defaultIcon);
                  final color = _getDefaultIconColor(defaultIcon);
                  return Icon(
                    iconData,
                    size: AppConstants.iconSize,
                    color: color,
                  );
                },
              ),
            ],
          ),
        );
      }

      // 폴백: 기존 아이콘 방식
      final iconData = _getDefaultIconData(defaultIcon);
      final color = _getDefaultIconColor(defaultIcon);

      return Icon(iconData, size: AppConstants.iconSize, color: color);
    }

    return Icon(Icons.pets, color: fallbackColor, size: AppConstants.iconSize);
  }

  // 기본 아이콘 데이터 매핑
  IconData _getDefaultIconData(String iconName) {
    switch (iconName) {
      case 'dog1':
        return Icons.pets;
      case 'dog2':
        return Icons.pets_outlined;
      case 'cat1':
        return Icons.cruelty_free;
      case 'cat2':
        return Icons.cruelty_free_outlined;
      case 'rabbit':
        return Icons.cruelty_free;
      case 'bird':
        return Icons.flight;
      case 'fish':
        return Icons.water_drop;
      case 'hamster':
        return Icons.circle;
      case 'turtle':
        return Icons.circle_outlined;
      case 'heart':
        return Icons.favorite;
      default:
        return Icons.pets;
    }
  }

  // 기본 아이콘 색상 매핑
  Color _getDefaultIconColor(String iconName) {
    switch (iconName) {
      case 'dog1':
        return const Color(0xFF8B4513); // 갈색
      case 'dog2':
        return const Color(0xFF9370DB); // 보라색
      case 'cat1':
        return const Color(0xFF808080); // 회색
      case 'cat2':
        return const Color(0xFF2F4F4F); // 어두운 회색
      case 'rabbit':
        return const Color(0xFFFFB6C1); // 연분홍
      case 'bird':
        return const Color(0xFF87CEEB); // 하늘색
      case 'fish':
        return const Color(0xFF4169E1); // 로얄블루
      case 'hamster':
        return const Color(0xFFDEB887); // 버프색
      case 'turtle':
        return const Color(0xFF9ACD32); // 옐로우그린
      case 'heart':
        return const Color(0xFFFF69B4); // 핫핑크
      default:
        return const Color(0xFF666666);
    }
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    
    // 게스트 사용자 확인: email이 null이거나 비어있으면 게스트
    final isGuest = user?.email == null || user!.email!.isEmpty;
    
    final displayName = isGuest
        ? 'settings.guest'.tr()
        : (user?.userMetadata?['display_name'] as String? ??
            user?.userMetadata?['full_name'] as String? ??
            '');

    _displayNameController.text = displayName;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final displayName = _displayNameController.text.trim();

      AppLogger.d('Settings', '프로필 업데이트 시도: displayName=$displayName');

      // 사용자 메타데이터 업데이트 (닉네임만)
      final metadata = <String, dynamic>{'display_name': displayName};

      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: metadata),
      );

      AppLogger.d('Settings', '프로필 업데이트 응답: ${response.user?.userMetadata}');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.profile_updated'.tr())),
        );
      }
    } catch (e) {
      AppLogger.e('Settings', '프로필 업데이트 오류', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'settings.profile_update_failed'.tr()}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.0,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'settings.edit_profile'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: AppConstants.mediumPadding),

                  // Display Name
                  AppTextField(
                    controller: _displayNameController,
                    labelText: 'settings.nickname'.tr(),
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'settings.nickname_required'.tr();
                      }
                      return null;
                    },
                  ),

                  // Spacer to push buttons to bottom
                  Expanded(child: const SizedBox.shrink()),

                  // Spacing between field and buttons
                  SizedBox(height: AppConstants.profileEditButtonSpacing),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text('common.cancel'.tr()),
                        ),
                      ),
                      SizedBox(width: AppConstants.defaultPadding),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('common.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.profileEditBottomSpacing),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

