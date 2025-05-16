// widgets/survey_pages/survey_page_personal_info.dart
// (UserData에 activityLevel 추가됨에 따라, 해당 정보 입력 UI 추가)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';
import '../../l10n/app_localizations.dart';

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
  
  // 포커스 노드 추가
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();

  String? _selectedGender;
  late List<String> _genders;

  // 활동 수준 옵션
  String? _selectedActivityLevel;
  late List<String> _activityLevels;

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
    
    // 활동 수준 초기화
    _selectedActivityLevel = existingData.activityLevel;
    
    _underlyingConditions = List<String>.from(existingData.underlyingConditions);
    _allergies = List<String>.from(existingData.allergies);
    
    // 포커스 리스너 설정
    _ageFocusNode.addListener(() {
      if (!_ageFocusNode.hasFocus) {
        _validateAge();
      }
    });
    
    _heightFocusNode.addListener(() {
      if (!_heightFocusNode.hasFocus) {
        _validateHeight();
      }
    });
    
    _weightFocusNode.addListener(() {
      if (!_weightFocusNode.hasFocus) {
        _validateWeight();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localization = AppLocalizations.of(context);
    
    // 현재 선택된 성별 저장
    String? previousGender = _selectedGender;
    
    // 지역화된 문자열로 초기화
    _genders = [
      localization.maleOption,
      localization.femaleOption,
      localization.isKorean() ? '기타' : 'Other',
      localization.isKorean() ? '선택 안함' : 'Prefer not to say'
    ];
    
    // 이전에 선택한 성별이 있는 경우, 적절한 인덱스로 매핑
    if (previousGender != null) {
      // 언어가 변경되었을 때 올바른 성별 옵션을 선택
      if (previousGender == 'Male' || previousGender == '남성') {
        _selectedGender = localization.maleOption;
      } else if (previousGender == 'Female' || previousGender == '여성') {
        _selectedGender = localization.femaleOption;
      } else if (previousGender == 'Other' || previousGender == '기타') {
        _selectedGender = localization.isKorean() ? '기타' : 'Other';
      } else if (previousGender == 'Prefer not to say' || previousGender == '선택 안함') {
        _selectedGender = localization.isKorean() ? '선택 안함' : 'Prefer not to say';
      }
      
      // 변경된 경우 부모 업데이트
      if (_selectedGender != previousGender) {
        _updateParent();
      }
    }
    
    _activityLevels = [
      localization.activityLevel1,
      localization.activityLevel2,
      localization.activityLevel3,
      localization.activityLevel4,
      localization.activityLevel5,
    ];
    
    // 활동량 기본값 설정 (보통 = index 2)
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    
    // 기존 활동량이 없으면 무조건 기본값 설정
    if (_selectedActivityLevel == null || _selectedActivityLevel!.isEmpty) {
      _selectedActivityLevel = _activityLevels[2]; // '보통' 수준을 기본값으로
      surveyDataProvider.userData.activityLevel = _selectedActivityLevel;
      
      // 여기서 데이터 프로바이더도 업데이트
      _updateParent();
    }
    
    // 설정된 활동량이 현재 지역화된 옵션에 없는 경우도 체크
    bool found = false;
    for (String level in _activityLevels) {
      if (level == _selectedActivityLevel) {
        found = true;
        break;
      }
    }
    
    if (!found) {
      _selectedActivityLevel = _activityLevels[2];
      surveyDataProvider.userData.activityLevel = _selectedActivityLevel;
      
      // 여기서도 데이터 프로바이더 업데이트
      _updateParent();
    }
  }

  // 나이 값 검증
  void _validateAge() {
    if (_ageController.text.isEmpty) return;
    
    final age = int.tryParse(_ageController.text);
    if (age != null) {
      if (age < 1) {
        _ageController.text = '1';
        _ageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ageController.text.length)
        );
      } else if (age > 120) {
        _ageController.text = '120';
        _ageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ageController.text.length)
        );
      }
    }
    _updateParent();
  }
  
  // 키 값 검증
  void _validateHeight() {
    if (_heightController.text.isEmpty) return;
    
    final height = double.tryParse(_heightController.text);
    if (height != null) {
      if (height < 50) {
        _heightController.text = '50';
        _heightController.selection = TextSelection.fromPosition(
          TextPosition(offset: _heightController.text.length)
        );
      } else if (height > 250) {
        _heightController.text = '250';
        _heightController.selection = TextSelection.fromPosition(
          TextPosition(offset: _heightController.text.length)
        );
      }
    }
    _updateParent();
  }
  
  // 체중 값 검증
  void _validateWeight() {
    if (_weightController.text.isEmpty) return;
    
    final weight = double.tryParse(_weightController.text);
    if (weight != null) {
      if (weight < 20) {
        _weightController.text = '20';
        _weightController.selection = TextSelection.fromPosition(
          TextPosition(offset: _weightController.text.length)
        );
      } else if (weight > 300) {
        _weightController.text = '300';
        _weightController.selection = TextSelection.fromPosition(
          TextPosition(offset: _weightController.text.length)
        );
      }
    }
    _updateParent();
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
      _selectedActivityLevel ?? _activityLevels[2], // 활동량이 null인 경우 '보통' 수준 기본값 사용
      _underlyingConditions,
      _allergies,
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
    final localization = AppLocalizations.of(context);
    
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
                localization.personalInfoTitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                localization.isKorean() 
                    ? '맞춤형 식단 추천을 위해 필요한 기본 정보를 입력해주세요.'
                    : 'Please enter the basic information needed for customized meal recommendations.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 기본 신체 정보 섹션
        _buildSectionLabel(localization.profileBasicInfo, isRequired: true),
        
        // 나이 입력
        Container(
          height: textFieldHeight,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: horizontalPadding),
          child: TextField(
            controller: _ageController,
            focusNode: _ageFocusNode,
            decoration: _inputDecoration(
              localization.ageLabel,
              hint: localization.isKorean() ? '나이 입력 (1-120세)' : 'Enter age (1-120 years)',
              icon: Icons.person_outline,
              isRequired: true,
              suffixIcon: Text(
                localization.isKorean() ? '세' : 'years',
                style: TextStyle(color: theme.hintColor),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _updateParent(),
            onEditingComplete: _validateAge,
            onSubmitted: (_) => _validateAge(),
          ),
        ),
        
        // 성별 선택
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequiredLabel(localization.genderLabel),
              SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0; i < _genders.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGender = _genders[i];
                              _updateParent();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _selectedGender == _genders[i]
                                ? theme.colorScheme.onPrimary
                                : null,
                            backgroundColor: _selectedGender == _genders[i]
                                ? theme.colorScheme.primary
                                : null,
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: _selectedGender == _genders[i]
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            _genders[i],
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // 키 입력
        Container(
          height: textFieldHeight,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: horizontalPadding),
          child: TextField(
            controller: _heightController,
            focusNode: _heightFocusNode,
            decoration: _inputDecoration(
              localization.heightLabel,
              hint: localization.isKorean() ? '키 입력 (50-250cm)' : 'Enter height (50-250cm)',
              icon: Icons.height,
              isRequired: true,
              suffixIcon: Text(
                'cm',
                style: TextStyle(color: theme.hintColor),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
            ],
            onChanged: (value) => _updateParent(),
            onEditingComplete: _validateHeight,
            onSubmitted: (_) => _validateHeight(),
          ),
        ),
        
        // 체중 입력
        Container(
          height: textFieldHeight,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: horizontalPadding),
          child: TextField(
            controller: _weightController,
            focusNode: _weightFocusNode,
            decoration: _inputDecoration(
              localization.weightLabel,
              hint: localization.isKorean() ? '체중 입력 (20-200kg)' : 'Enter weight (20-200kg)',
              icon: Icons.fitness_center,
              isRequired: true,
              suffixIcon: Text(
                'kg',
                style: TextStyle(color: theme.hintColor),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
            ],
            onChanged: (value) => _updateParent(),
            onEditingComplete: _validateWeight,
            onSubmitted: (_) => _validateWeight(),
          ),
        ),
        
        // 활동 수준 선택
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequiredLabel(localization.activityLevelLabel),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedActivityLevel == null ? Colors.red : theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _activityLevels.map((level) {
                    return RadioListTile<String>(
                      title: Text(
                        level,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: _selectedActivityLevel == level ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      value: level,
                      groupValue: _selectedActivityLevel,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _selectedActivityLevel = value;
                          _updateParent();
                        });
                      },
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 16,
                        vertical: 0,
                      ),
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              if (_selectedActivityLevel == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    localization.isKorean() ? '* 활동량을 선택해주세요' : '* Please select your activity level',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ageFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}