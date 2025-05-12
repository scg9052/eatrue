import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';

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
  
  final List<String> _commonConditions = [
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
  ];
  
  final List<String> _commonAllergies = [
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
  ];
  
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

  void _updateOtherConditions(String value) {
    final otherConditions = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    // 이전에 입력된 기타 조건들 제거
    _selectedConditions.removeWhere((c) => !_commonConditions.contains(c));
    
    // 새로운 기타 조건들 추가
    _selectedConditions.addAll(otherConditions);
    
    widget.onUpdate(_selectedConditions, _selectedAllergies);
    _otherCondition = value;
  }

  void _updateOtherAllergies(String value) {
    final otherAllergies = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    // 이전에 입력된 기타 알레르기 제거
    _selectedAllergies.removeWhere((a) => !_commonAllergies.contains(a));
    
    // 새로운 기타 알레르기 추가
    _selectedAllergies.addAll(otherAllergies);
    
    widget.onUpdate(_selectedConditions, _selectedAllergies);
    _otherAllergy = value;
  }

  Widget _buildSectionLabel(String labelText) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 16.0),
      child: Text(
        labelText,
        style: TextStyle(
          fontSize: 17, 
          fontWeight: FontWeight.w600, 
          color: theme.colorScheme.primary,
          fontFamily: 'NotoSansKR'
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function() onTap, {Color? accentColor}) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onTap(),
      backgroundColor: theme.cardColor,
      selectedColor: color,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 0),
      elevation: isSelected ? 2 : 0,
      shadowColor: isSelected ? color.withOpacity(0.3) : Colors.transparent,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected ? color : theme.dividerColor,
          width: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
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
                '건강 정보',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '건강 상태 정보를 입력하시면 더 정확한 식단을 추천해 드립니다.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 기저질환 섹션
        _buildSectionLabel('기저질환 (해당 항목 모두 선택)'),
        
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonConditions.map((condition) => _buildFilterChip(
                  condition,
                  _selectedConditions.contains(condition),
                  () => _toggleCondition(condition),
                  accentColor: Color(0xFF5C6BC0), // 인디고 계열
                )).toList(),
              ),
              SizedBox(height: 16),
              Text(
                '기타 질환',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _medicalConditionsController,
                decoration: InputDecoration(
                  hintText: '기타 질환이 있다면 쉼표로 구분하여 입력하세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor,
                  prefixIcon: Icon(Icons.add_circle_outline, color: Color(0xFF5C6BC0)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: theme.textTheme.bodyMedium,
                onChanged: _updateOtherConditions,
              ),
            ],
          ),
        ),
        
        // 알레르기 섹션
        _buildSectionLabel('식품 알레르기 (해당 항목 모두 선택)'),
        
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonAllergies.map((allergy) => _buildFilterChip(
                  allergy,
                  _selectedAllergies.contains(allergy),
                  () => _toggleAllergy(allergy),
                  accentColor: Color(0xFFEF5350), // 레드 계열
                )).toList(),
              ),
              SizedBox(height: 16),
              Text(
                '기타 알레르기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  hintText: '기타 알레르기가 있다면 쉼표로 구분하여 입력하세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor,
                  prefixIcon: Icon(Icons.add_circle_outline, color: Color(0xFFEF5350)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: theme.textTheme.bodyMedium,
                onChanged: _updateOtherAllergies,
              ),
            ],
          ),
        ),
        
        // 건강 정보 작성 팁
        SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    '건강 정보 작성 팁',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• 기저질환과 알레르기 정보는 더 안전하고 맞춤화된 식단 추천을 위해 중요합니다.',
                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
              ),
              SizedBox(height: 4),
              Text(
                '• 여러 항목을 선택할 수 있으며, 필요한 경우 기타 항목에 직접 입력하세요.',
                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 