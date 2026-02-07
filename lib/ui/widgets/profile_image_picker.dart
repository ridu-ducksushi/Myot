import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petcare/data/services/image_service.dart';
import 'package:petcare/utils/app_constants.dart';
import 'package:petcare/utils/app_logger.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? imagePath;
  final Function(File?) onImageSelected;
  final Function(String, String)? onDefaultIconSelected; // 아이콘과 배경색을 함께 전달
  final double size;
  final bool showEditIcon;
  final String? selectedDefaultIcon;
  final String? selectedBgColor; // 선택된 배경색 추가
  final String? species; // 동물 종류 (dog, cat 등)
  final Future<void> Function()? onClearSelection;

  const ProfileImagePicker({
    super.key,
    this.imagePath,
    required this.onImageSelected,
    this.onDefaultIconSelected,
    this.size = 120,
    this.showEditIcon = true,
    this.selectedDefaultIcon,
    this.selectedBgColor,
    this.species,
    this.onClearSelection,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  List<String> _defaultIconUrls = [];
  bool _isLoadingIcons = false;

  @override
  void initState() {
    super.initState();
    if (widget.species != null) {
      _loadDefaultIcons();
    }
  }

  @override
  void didUpdateWidget(ProfileImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species && widget.species != null) {
      _loadDefaultIcons();
    }
  }

  Future<void> _loadDefaultIcons() async {
    if (widget.species == null) {
      AppLogger.w('ProfilePicker', 'species가 null입니다.');
      return;
    }
    
    AppLogger.d('ProfilePicker', '기본 아이콘 로드 시작: species=${widget.species}');
    
    setState(() {
      _isLoadingIcons = true;
    });

    try {
      final urls = await ImageService.getDefaultIconUrls(widget.species!);
      AppLogger.d('ProfilePicker', '로드된 아이콘 URL 개수: ${urls.length}');
      setState(() {
        _defaultIconUrls = urls;
        _isLoadingIcons = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingIcons = false;
      });
      AppLogger.e('ProfilePicker', '기본 아이콘 로드 실패', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // 배경색 레이어 (기본 아이콘이 선택된 경우에만)
            if (widget.selectedDefaultIcon != null && widget.selectedBgColor != null)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/profile_bg/${widget.selectedBgColor}.png',
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      );
                    },
                  ),
                ),
              ),
            // 프로필 이미지
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selectedDefaultIcon != null && widget.selectedBgColor != null 
                    ? Colors.transparent 
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: ClipOval(
                child: _buildImageContent(context),
              ),
            ),
            // 편집 아이콘
            if (widget.showEditIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: widget.size * 0.15,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    // 기본 아이콘이 선택된 경우 기본 아이콘 표시
    if (widget.selectedDefaultIcon != null && widget.species != null) {
      // Supabase Storage에서 이미지 URL 가져오기
      final imageUrl = ImageService.getDefaultIconUrl(widget.species!, widget.selectedDefaultIcon!);
      if (imageUrl.isNotEmpty) {
        return Image.asset(
          imageUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.e('ProfilePicker', 'Assets 이미지 로드 실패: $imageUrl, 에러: $error');
            // Assets 이미지 로드 실패 시 기본 아이콘으로 폴백
            return _buildDefaultIcon(context);
          },
        );
      }
    }
    
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      try {
        return Image.file(
          File(widget.imagePath!),
          key: ValueKey(widget.imagePath), // 캐시 무효화를 위한 고유 key
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(context);
          },
        );
      } catch (e) {
        return _buildDefaultAvatar(context);
      }
    }
    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: _buildDefaultIcon(context),
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    if (widget.selectedDefaultIcon != null) {
      final iconData = _getDefaultIconData(widget.selectedDefaultIcon!);
      final color = _getDefaultIconColor(widget.selectedDefaultIcon!);
      
      return Icon(
        iconData,
        size: widget.size * 0.4,
        color: color,
      );
    }
    
    return Icon(
      Icons.pets,
      size: widget.size * 0.4,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32, // 시스템 네비게이션 바 고려
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'pets.select_profile_image'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'pets.gallery'.tr(),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(context, ImageSource.gallery);
                  },
                ),
                _buildSourceOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'pets.camera'.tr(),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(context, ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  context,
                  icon: Icons.pets,
                  label: 'pets.default_icon'.tr(),
                  onTap: () async {
                    Navigator.pop(context);
                    _showDefaultIconsDialog(context);
                  },
                ),
                _buildSourceOption(
                  context,
                  icon: Icons.delete,
                  label: 'common.delete'.tr(),
                  onTap: () async {
                    Navigator.pop(context);
                    if (widget.onClearSelection != null) {
                      await widget.onClearSelection!();
                    }
                    await Future.sync(() => widget.onImageSelected(null));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      File? imageFile;
      
      if (source == ImageSource.gallery) {
        imageFile = await ImageService.pickImageFromGallery();
      } else {
        imageFile = await ImageService.pickImageFromCamera();
      }

      if (imageFile != null) {
        // 이미지 압축
        final compressedImage = await ImageService.compressImage(imageFile);
        if (compressedImage != null) {
          // 앱 내부 저장소에 저장
          final savedPath = await ImageService.saveImageToAppDirectory(compressedImage);
          if (savedPath != null) {
            widget.onImageSelected(File(savedPath));
          } else {
            _showErrorSnackBar(context, 'pets.image_save_failed'.tr());
          }
        } else {
          _showErrorSnackBar(context, 'pets.image_compress_failed'.tr());
        }
      }
    } catch (e) {
      _showErrorSnackBar(context, 'pets.image_select_error'.tr());
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // 기본 아이콘 목록
  static const List<String> _defaultIcons = [
    'dog1',
    'dog2', 
    'cat1',
    'cat2',
    'rabbit',
    'bird',
    'fish',
    'hamster',
    'turtle',
    'heart'
  ];

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
        return const Color(0xFFCD853F); // 페루색
      case 'cat1':
        return const Color(0xFF696969); // 회색
      case 'cat2':
        return const Color(0xFFA9A9A9); // 어두운 회색
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

  // 기본 아이콘 선택 다이얼로그
  void _showDefaultIconsDialog(BuildContext context) {
    AppLogger.d('ProfilePicker', '기본 아이콘 다이얼로그 열기 시작');
    AppLogger.d('ProfilePicker', 'Species: ${widget.species}, Loading: $_isLoadingIcons, Icons: ${_defaultIconUrls.length}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 24),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'pets.select_default_icon'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoadingIcons
                      ? const Center(child: CircularProgressIndicator())
                      : _defaultIconUrls.isEmpty
                          ? Center(child: Text('pets.no_icons_found'.tr()))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1,
                              ),
                              itemCount: _isLoadingIcons ? 0 : _defaultIconUrls.length,
                              itemBuilder: (context, index) {
                                final iconUrl = _defaultIconUrls[index];
                                final iconName = iconUrl.split('/').last.split('.').first;
                                final isSelected = widget.selectedDefaultIcon == iconName;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showBgColorDialog(context, iconName);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                          : Theme.of(context).colorScheme.surfaceVariant,
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        iconUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.pets,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            size: 32,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // 배경색 선택 다이얼로그
  void _showBgColorDialog(BuildContext context, String selectedIcon) {
    final bgColors = ['Color_1', 'Color_2', 'Color_3', 'Color_4', 'Color_5', 'Color_6', 'Color_7', 'Color_8'];
    String? previewBgColor; // 상태를 builder 밖으로 이동
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 24),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'pets.select_bg_color'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Stack(
                        children: [
                          if (previewBgColor != null)
                            Image.asset(
                              'assets/images/profile_bg/$previewBgColor.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          Center(
                            child: Image.asset(
                              ImageService.getDefaultIconUrl(widget.species!, selectedIcon),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: bgColors.length,
                      itemBuilder: (context, index) {
                        final colorName = bgColors[index];
                        final isSelected = previewBgColor == colorName;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              previewBgColor = colorName;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/profile_bg/$colorName.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.palette,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: previewBgColor == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              if (widget.onDefaultIconSelected != null && previewBgColor != null) {
                                widget.onDefaultIconSelected!(selectedIcon, previewBgColor!);
                              }
                            },
                      child: Text('common.confirm_selection'.tr()),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
