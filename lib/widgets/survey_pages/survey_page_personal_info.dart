 // widgets/survey_pages/survey_page_personal_info.dart
// (UserData에 activityLevel 추가됨에 따라, 해당 정보 입력 UI 추가)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPagePersonalInfo extends StatefulWidget {
  final Function(int? age, String? gender, double? height, double? weight, String? activityLevel, List<String> conditions, List<String> allergies) onUpdate;

  const SurveyPagePersonalInfo({Key? key, required this.onUpdate}) : super(key: key);

  @override
  _SurveyPagePersonalInfoState createState() => _SurveyPagePersonalInfoState();
}

class _SurveyPagePersonalInfoState extends State<SurveyPagePersonalInfo> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['남성', '여성', '기타', '선택 안함'];

  // 활동 수준 옵션
  String? _selectedActivityLevel;
  final List<String> _activityLevels = ['매우 낮음 (거의 운동 안함)', '낮음 (주 1-2회 가벼운 운동)', '보통 (주 3-5회 중간 강도 운동)', '높음 (주 6-7회 고강도 운동)', '매우 높음 (매일 매우 고강도 운동 또는 육체노동)'];

  // 빈 리스트로 초기화 (건강 상태 페이지에서 다룰 예정)
  List<String> _underlyingConditions = [];
  List<String> _allergies = [];

  @override
  void initState() {
    super.initState();
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final UserData existingData = surveyDataProvider.userData;

    if (existingData.age != null) _ageController.text = existingData.age.toString();
    _selectedGender = existingData.gender;
    if (existingData.height != null) _heightController.text = existingData.height.toString();
    if (existingData.weight != null) _weightController.text = existingData.weight.toString();
    _selectedActivityLevel = existingData.activityLevel ?? _activityLevels[2]; // 기본값 '보통'
    _underlyingConditions = List<String>.from(existingData.underlyingConditions);
    _allergies = List<String>.from(existingData.allergies);
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon, Widget? suffixIcon, bool isRequired = false}) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700; // 작은 화면 감지
    
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color, 
            fontSize: isSmallScreen ? 14 : 16, // 화면 크기에 따라 폰트 크기 조정
            fontFamily: 'NotoSansKR'
          ),
          children: <TextSpan>[
            if (isRequired)
              TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      hintText: hint,
      hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
      prefixIcon: icon != null ? Icon(icon, color: theme.colorScheme.primary, size: isSmallScreen ? 20 : 24) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),  // 더 둥근 모서리
        borderSide: BorderSide(color: theme.dividerColor)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), 
        borderSide: BorderSide(color: theme.dividerColor)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), 
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0)
      ),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16, 
        vertical: isSmallScreen ? 10 : 14
      ),
      isDense: isSmallScreen, // 작은 화면에서는 입력 필드를 더 조밀하게 표시
    );
  }

  void _updateParent() {
    widget.onUpdate(
      int.tryParse(_ageController.text),
      _selectedGender,
      double.tryParse(_heightController.text),
      double.tryParse(_weightController.text),
      _selectedActivityLevel,
      _underlyingConditions, // 빈 리스트 전달
      _allergies, // 빈 리스트 전달
    );
  }

  Widget _buildRequiredLabel(String labelText) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 18, 
          fontWeight: FontWeight.w600, 
          color: theme.textTheme.titleLarge?.color,
          fontFamily: 'NotoSansKR'
        ),
        children: [
          TextSpan(text: labelText),
          TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String labelText, {bool isRequired = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 16.0),
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700; // 작은 화면 기기 감지
    final theme = Theme.of(context);
    final horizontalPadding = isSmallScreen ? 8.0 : 16.0;
    
    // 텍스트 필드의 높이를 화면 크기에 맞게 조정
    final textFieldHeight = isSmallScreen ? 46.0 : 52.0;
    
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
                '기본 정보',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '맞춤형 식단 추천을 위해 필요한 기본 정보를 입력해주세요.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 기본 신체 정보 섹션
        _buildSectionLabel('기본 신체 정보', isRequired: true),
        
        // 나이 입력
        SizedBox(
          height: textFieldHeight,
          child: TextField(
            controller: _ageController,
            decoration: _inputDecoration(
              '나이 입력', 
              hint: '예: 30', 
              icon: Icons.cake_outlined, 
              isRequired: true
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            onChanged: (_) => _updateParent(),
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            textInputAction: TextInputAction.next, // 키보드에서 다음 버튼 활성화
          ),
        ),
        SizedBox(height: 16),
        
        // 성별 선택 (더 현대적인 UI)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 4.0, bottom: 8.0),
                child: RichText(
                  text: TextSpan(
                    text: '성별',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color, 
                      fontSize: isSmallScreen ? 14 : 16,
                      fontFamily: 'NotoSansKR'
                    ),
                    children: <TextSpan>[
                      TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 8.0,
                children: _genders.map((gender) {
                  final isSelected = gender == _selectedGender;
                  return ChoiceChip(
                    label: Text(gender),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: theme.chipTheme.backgroundColor,
                    selectedColor: theme.colorScheme.primary,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedGender = gender;
                          _updateParent();
                        });
                      }
                    },
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // 키와 체중 입력 (가로 배치)
        Row(
          children: [
            // 키 입력
            Expanded(
              child: SizedBox(
                height: textFieldHeight,
                child: TextField(
                  controller: _heightController,
                  decoration: _inputDecoration(
                    '키 (cm)', 
                    hint: '예: 170', 
                    icon: Icons.height, 
                    isRequired: true
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                    LengthLimitingTextInputFormatter(5)
                  ],
                  onChanged: (_) => _updateParent(),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  textInputAction: TextInputAction.next, // 키보드에서 다음 버튼 활성화
                ),
              ),
            ),
            SizedBox(width: 16),
            // 체중 입력
            Expanded(
              child: SizedBox(
                height: textFieldHeight,
                child: TextField(
                  controller: _weightController,
                  decoration: _inputDecoration(
                    '체중 (kg)', 
                    hint: '예: 65', 
                    icon: Icons.monitor_weight_outlined, 
                    isRequired: true
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                    LengthLimitingTextInputFormatter(5)
                  ],
                  onChanged: (_) => _updateParent(),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  textInputAction: TextInputAction.next, // 키보드에서 다음 버튼 활성화
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        
        // 활동 수준 섹션
        _buildSectionLabel('활동 수준', isRequired: true),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _activityLevels.map((level) {
              final isSelected = level == _selectedActivityLevel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: RadioListTile<String>(
                  title: Text(
                    level,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  value: level,
                  groupValue: _selectedActivityLevel,
                  onChanged: (val) {
                    setState(() {
                      _selectedActivityLevel = val;
                      _updateParent();
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}