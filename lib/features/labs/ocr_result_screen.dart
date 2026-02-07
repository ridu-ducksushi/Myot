import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petcare/data/services/lab_reference_ranges.dart';
import 'package:petcare/data/services/ocr_service.dart';

/// OCR 인식 결과 확인/수정 화면
class OcrResultScreen extends StatefulWidget {
  final File imageFile;
  final String species;
  final List<String> existingKeys;
  final Function(Map<String, String>) onConfirm;
  
  const OcrResultScreen({
    super.key,
    required this.imageFile,
    required this.species,
    required this.existingKeys,
    required this.onConfirm,
  });

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  bool _isProcessing = true;
  String _rawText = '';
  Map<String, String> _results = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _selectedItems = {};
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _processImage();
  }
  
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _processImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });
      
      // OCR 텍스트 인식
      final rawText = await OcrService.recognizeText(widget.imageFile);
      _rawText = rawText;
      
      // 검사 항목 파싱
      final results = OcrService.parseLabResults(rawText);
      
      setState(() {
        _results = results;
        _isProcessing = false;
        
        // 컨트롤러 초기화 및 기본 선택
        for (final entry in results.entries) {
          _controllers[entry.key] = TextEditingController(text: entry.value);
          _selectedItems.add(entry.key); // 기본적으로 모두 선택
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'ocr.process_error'.tr(args: [e.toString()]);
      });
    }
  }
  
  void _onConfirm() {
    // 선택된 항목만 반환
    final selectedResults = <String, String>{};
    for (final key in _selectedItems) {
      final value = _controllers[key]?.text ?? '';
      if (value.isNotEmpty) {
        selectedResults[key] = value;
      }
    }
    
    widget.onConfirm(selectedResults);
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ocr.result_title'.tr()),
        actions: [
          if (!_isProcessing && _results.isNotEmpty)
            TextButton(
              onPressed: _onConfirm,
              child: Text(
                'common.apply'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('ocr.analyzing'.tr()),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _processImage,
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'ocr.no_items_found'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ocr.retake_photo_hint'.tr(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.camera_alt),
                label: Text('ocr.retake_photo'.tr()),
              ),
              const SizedBox(height: 32),
              // 원본 텍스트 표시 토글
              ExpansionTile(
                title: Text('ocr.raw_text_title'.tr()),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _rawText.isEmpty ? 'ocr.no_text_recognized'.tr() : _rawText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // 이미지 미리보기
        Container(
          height: 150,
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ocr.edit_hint'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // 인식 결과 안내
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ocr.items_recognized'.tr(args: [_results.length.toString()]),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  if (_selectedItems.length == _results.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems.addAll(_results.keys);
                  }
                }),
                child: Text(
                  _selectedItems.length == _results.length ? 'common.deselect_all'.tr() : 'common.select_all'.tr(),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // 결과 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final key = _results.keys.elementAt(index);
              final isSelected = _selectedItems.contains(key);
              final reference = LabReferenceRanges.getReference(
                widget.species,
                key,
              );
              
              return _buildResultItem(key, reference, isSelected);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultItem(String testName, String reference, bool isSelected) {
    final controller = _controllers[testName];
    if (controller == null) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() {
          if (isSelected) {
            _selectedItems.remove(testName);
          } else {
            _selectedItems.add(testName);
          }
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 체크박스
              Checkbox(
                value: isSelected,
                onChanged: (value) => setState(() {
                  if (value == true) {
                    _selectedItems.add(testName);
                  } else {
                    _selectedItems.remove(testName);
                  }
                }),
              ),
              
              // 검사 항목명
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.grey,
                      ),
                    ),
                    if (reference.isNotEmpty)
                      Text(
                        '${'ocr.reference_prefix'.tr()}: $reference',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              
              // 수치 입력 필드
              Expanded(
                flex: 1,
                child: TextField(
                  controller: controller,
                  enabled: isSelected,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    FilteringTextInputFormatter.deny(RegExp(r',')),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.grey[200],
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? _getValueColor(controller.text, reference)
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 현재 값이 기준치 범위 내에 있는지 확인하고 색상 반환
  Color _getValueColor(String? valueStr, String? reference) {
    if (valueStr == null ||
        valueStr.isEmpty ||
        reference == null ||
        reference.isEmpty ||
        reference == '-') {
      return Colors.black;
    }

    final value = double.tryParse(valueStr);
    if (value == null) return Colors.black;

    // 기준치 파싱 (예: "9~53", "~14", "≤14" 등)
    if (reference.startsWith('~') || reference.startsWith('≤')) {
      final maxStr = reference.replaceAll(RegExp(r'[~≤]'), '').trim();
      final maxValue = double.tryParse(maxStr);
      if (maxValue != null && value > maxValue) {
        return Colors.red;
      }
      return Colors.black;
    }

    if (reference.contains('~')) {
      final parts = reference.split('~');
      if (parts.length == 2) {
        final minValue = double.tryParse(parts[0].replaceAll(',', '').trim());
        final maxValue = double.tryParse(parts[1].replaceAll(',', '').trim());

        if (minValue != null && maxValue != null) {
          if (value < minValue) {
            return Colors.blue;
          } else if (value > maxValue) {
            return Colors.red;
          }
        }
      }
    }

    return Colors.black;
  }
}

