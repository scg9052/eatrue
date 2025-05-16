import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../l10n/app_localizations.dart';

class SurveyPageHealthInfo extends StatefulWidget {
  final Function(List<String>, List<String>) onUpdate;

  SurveyPageHealthInfo({
    Key? key,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _SurveyPageHealthInfoState createState() => _SurveyPageHealthInfoState();
}

class _SurveyPageHealthInfoState extends State<SurveyPageHealthInfo> {
  final _medicalConditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  
  // 한국어로 기본 설정된 값은 나중에 언어에 따라 동적으로 로드
  late List<String> _commonConditions;
  late List<String> _commonAllergies;
  
  List<String> _selectedConditions = [];
  List<String> _selectedAllergies = [];
  String? _otherCondition;
  String? _otherAllergy;

  @override
  void initState() {
    super.initState();
    
    // 기존 데이터 불러오기
    final userData = Provider.of<SurveyDataProvider>(context, listen: false).userData;
    _selectedConditions = List.from(userData.underlyingConditions);
    _selectedAllergies = List.from(userData.allergies);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localization = AppLocalizations.of(context);
    
    // 지역화된 질환 목록
    _commonConditions = localization.isKorean() ? [
      '당뇨병',
      '고혈압',
      '고지혈증',
      '심장질환',
      '갑상선질환',
      '간질환',
      '신장질환',
      '소화기질환',
      '관절염',
      '골다공증',
    ] : [
      'Diabetes',
      'Hypertension',
      'Hyperlipidemia',
      'Heart Disease',
      'Thyroid Disease',
      'Liver Disease',
      'Kidney Disease',
      'Digestive Disorders',
      'Arthritis',
      'Osteoporosis',
    ];
    
    // 지역화된 알레르기 목록
    _commonAllergies = localization.isKorean() ? [
      '계란',
      '우유/유제품',
      '견과류',
      '밀가루',
      '갑각류',
      '생선',
      '대두/콩',
      '과일',
      '땅콩',
      '참깨',
    ] : [
      'Eggs',
      'Milk/Dairy',
      'Nuts',
      'Wheat',
      'Shellfish',
      'Fish',
      'Soy',
      'Fruits',
      'Peanuts',
      'Sesame',
    ];
    
    // 사용자 입력 필드에 기존 항목 중 기본 목록에 없는 항목 표시
    _otherCondition = _selectedConditions.where((c) => !_commonConditions.contains(c)).join(', ');
    _otherAllergy = _selectedAllergies.where((a) => !_commonAllergies.contains(a)).join(', ');
    
    if (_otherCondition!.isNotEmpty) {
      _medicalConditionsController.text = _otherCondition!;
    }
    
    if (_otherAllergy!.isNotEmpty) {
      _allergiesController.text = _otherAllergy!;
    }
  }

  @override
  void dispose() {
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
      widget.onUpdate(_selectedConditions, _selectedAllergies);
    });
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
      } else {
        _selectedAllergies.add(allergy);
      }
      widget.onUpdate(_selectedConditions, _selectedAllergies);
    });
  }

  Widget _buildSectionLabel(String labelText, {bool isRequired = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            fontFamily: 'NotoSansKR'
          ),
          children: [
            TextSpan(text: labelText),
            if (isRequired)
              TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color chipColor) {
    return FilterChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildAddableChipList({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onToggle,
    required Color chipColor,
    required String fieldLabel,
    required String hintText,
    required TextEditingController controller,
    bool showAddOther = true,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(fieldLabel, isRequired: isRequired),
        // 칩 목록
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            // 기본 제공 항목들
            for (final item in items)
              _buildFilterChip(
                item,
                selectedItems.contains(item),
                () => onToggle(item),
                chipColor,
              ),
          ],
        ),
        
        // 기타 항목 추가 필드
        if (showAddOther) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    final items = text.split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    
                    setState(() {
                      for (final item in items) {
                        if (!selectedItems.contains(item)) {
                          selectedItems.add(item);
                        }
                      }
                      controller.clear();
                    });
                    
                    widget.onUpdate(_selectedConditions, _selectedAllergies);
                  }
                },
                child: Text(localization.isKorean() ? '추가' : 'Add'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final localization = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목 추가
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.healthInfoTitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                localization.isKorean() 
                    ? '건강 상태 정보를 입력하시면 더 정확한 식단을 추천해 드립니다.'
                    : 'Enter your health information for more accurate meal recommendations.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 기저질환 섹션
        _buildAddableChipList(
          items: _commonConditions,
          selectedItems: _selectedConditions,
          onToggle: _toggleCondition,
          chipColor: Colors.deepPurple[400]!,
          fieldLabel: localization.isKorean() ? '기저질환 (해당 항목 모두 선택)' : 'Medical Conditions (Select all that apply)',
          hintText: localization.isKorean() ? '기타 기저질환을 입력하세요' : 'Enter other medical conditions',
          controller: _medicalConditionsController,
          isRequired: false,
        ),
        
        // 알레르기 섹션
        _buildAddableChipList(
          items: _commonAllergies,
          selectedItems: _selectedAllergies,
          onToggle: _toggleAllergy,
          chipColor: Colors.red[400]!,
          fieldLabel: localization.allergiesLabel,
          hintText: localization.isKorean() ? '기타 알레르기를 입력하세요' : 'Enter other allergies',
          controller: _allergiesController,
          isRequired: false,
        ),
      ],
    );
  }
} 