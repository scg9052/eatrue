// widgets/survey_pages/survey_page_food_preference.dart
// (이전 답변의 flutter_recipe_app_v1_religious_required 문서 내용과 거의 동일,
// UserData 모델에 dislikedCookingMethods, favoriteSeasonings, dislikedSeasonings 필드 추가 시 해당 UI 요소 추가 필요)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPageFoodPreference extends StatefulWidget {
  final Function(bool isVegan, bool isReligious, String? religionDetails, List<String> mealPurposes, double? mealBudget, List<String> favFoods, List<String> dislikedFoods, List<String> cookingMethods) onUpdate;

  const SurveyPageFoodPreference({Key? key, required this.onUpdate}) : super(key: key);

  @override
  _SurveyPageFoodPreferenceState createState() => _SurveyPageFoodPreferenceState();
}

class _SurveyPageFoodPreferenceState extends State<SurveyPageFoodPreference> {
  bool _isVegan = false;
  bool _isReligiousDiet = false;

  final TextEditingController _religionDetailsController = TextEditingController();
  final TextEditingController _mealPurposeController = TextEditingController();
  List<String> _mealPurposes = [];

  final TextEditingController _mealBudgetController = TextEditingController();
  final TextEditingController _favoriteFoodController = TextEditingController();
  final TextEditingController _dislikedFoodController = TextEditingController();
  // final TextEditingController _favoriteSeasoningController = TextEditingController(); // 필요시 추가
  // final TextEditingController _dislikedSeasoningController = TextEditingController(); // 필요시 추가

  List<String> _favoriteFoods = [];
  List<String> _dislikedFoods = [];
  // List<String> _favoriteSeasonings = []; // 필요시 추가
  // List<String> _dislikedSeasonings = []; // 필요시 추가


  List<String> _allCookingMethods = ['상관없음','구이', '찜', '조림', '볶음', '튀김', '국/탕', '무침', '생식', '데치기', '굽기(오븐/에어프라이어)'];
  List<String> _selectedCookingMethods = [];
  // List<String> _allDislikedCookingMethods = ['튀김', '볶음', '기타 직접 입력']; // 예시, 필요시 확장
  // List<String> _selectedDislikedCookingMethods = []; // 필요시 추가

  // 식사 목적 옵션
  final List<String> _commonPurposes = [
    '건강 관리',
    '체중 감량',
    '근육 증가',
    '영양 균형',
    '에너지 향상',
    '식이 제한 관리',
    '맛있는 식사',
    '경제적인 식사'
  ];

  // 포커스 노드 추가
  final FocusNode _favoriteFoodFocusNode = FocusNode();
  final FocusNode _dislikedFoodFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final UserData existingData = surveyDataProvider.userData;

    _isVegan = existingData.isVegan;
    _isReligiousDiet = existingData.isReligious;
    _religionDetailsController.text = existingData.religionDetails ?? '';
    _mealPurposes = List<String>.from(existingData.mealPurpose);
    if (existingData.mealBudget != null) _mealBudgetController.text = existingData.mealBudget.toString();
    _favoriteFoods = List<String>.from(existingData.favoriteFoods);
    _dislikedFoods = List<String>.from(existingData.dislikedFoods);
    _selectedCookingMethods = List<String>.from(existingData.preferredCookingMethods);
    // _selectedDislikedCookingMethods = List<String>.from(existingData.dislikedCookingMethods ?? []);
    // _favoriteSeasonings = List<String>.from(existingData.favoriteSeasonings ?? []);
    // _dislikedSeasonings = List<String>.from(existingData.dislikedSeasonings ?? []);


    _religionDetailsController.addListener(_onReligionDetailsChanged);
  }

  void _onReligionDetailsChanged() {
    setState(() {}); // SurveyScreen의 버튼 상태 갱신 유도
    _updateParent();
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon, Widget? suffixIcon, bool isRequired = false}) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color, 
            fontSize: isSmallScreen ? 14 : 16,
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
        borderRadius: BorderRadius.circular(12.0),
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
      isDense: isSmallScreen,
    );
  }

  void _updateParent() {
    widget.onUpdate(
      _isVegan,
      _isReligiousDiet,
      _religionDetailsController.text.trim().isEmpty ? null : _religionDetailsController.text.trim(),
      List<String>.from(_mealPurposes),
      double.tryParse(_mealBudgetController.text),
      List<String>.from(_favoriteFoods),
      List<String>.from(_dislikedFoods),
      List<String>.from(_selectedCookingMethods),
      // List<String>.from(_selectedDislikedCookingMethods), // UserData 확장 시 전달
      // List<String>.from(_favoriteSeasonings),
      // List<String>.from(_dislikedSeasonings),
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

  Widget _buildChipInputList({
    required String fieldLabel, 
    required String inputLabel, 
    required TextEditingController controller,
    required List<String> itemList, 
    required Function(String) onAdd, 
    required Function(String) onRemove,
    required FocusNode focusNode,
    IconData? listIcon, 
    String? hintText, 
    Color? chipColor,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    final accentColor = chipColor ?? theme.colorScheme.secondary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(fieldLabel, isRequired: isRequired),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: itemList.isNotEmpty ? EdgeInsets.all(12) : EdgeInsets.zero,
          decoration: itemList.isNotEmpty ? BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: theme.dividerColor)
          ) : null,
          child: Wrap(
            spacing: 8.0, 
            runSpacing: 8.0,
            children: itemList.map((item) => _buildAnimatedChip(
              item,
              listIcon,
              accentColor,
              () { 
                setState(() { 
                  onRemove(item); 
                  _updateParent(); 
                }); 
              },
            )).toList(),
          ),
        ),
        SizedBox(height: itemList.isNotEmpty ? 12 : 0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                decoration: _inputDecoration(
                  inputLabel, 
                  hint: hintText ?? '$inputLabel 입력 후 \'추가\' 또는 Enter', 
                  icon: Icons.edit_note
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) { 
                    setState(() { 
                      onAdd(value.trim()); 
                      controller.clear(); 
                      _updateParent(); 
                      // 포커스 유지
                      focusNode.requestFocus();
                    }); 
                  }
                },
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) { 
                  setState(() { 
                    onAdd(value); 
                    controller.clear(); 
                    _updateParent(); 
                    // 포커스 유지
                    focusNode.requestFocus();
                  }); 
                }
              },
              child: Icon(Icons.add, size: 24),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                minimumSize: Size(60, 52), 
                padding: EdgeInsets.zero, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // 애니메이션이 적용된 Chip 위젯 생성
  Widget _buildAnimatedChip(String label, IconData? icon, Color accentColor, VoidCallback onDelete) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Chip(
              avatar: icon != null ? Icon(icon, size: 18, color: accentColor) : null,
              label: Text(
                label, 
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w500
                )
              ),
              onDeleted: onDelete,
              deleteIcon: Icon(Icons.close, size: 18), 
              deleteIconColor: Colors.red[400],
              backgroundColor: accentColor.withOpacity(0.1), 
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: accentColor.withOpacity(0.3), width: 1)
              ),
            ),
          ),
        );
      },
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

  Widget _buildCookingMethodSelector() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('선호하는 조리 방법', isRequired: true),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCookingMethods.map((method) => _buildFilterChip(
              method,
              _selectedCookingMethods.contains(method),
              () {
                setState(() {
                  if (_selectedCookingMethods.contains(method)) {
                    _selectedCookingMethods.remove(method);
                  } else {
                    // '상관없음' 선택 시 다른 모든 선택 해제
                    if (method == '상관없음') {
                      _selectedCookingMethods.clear();
                    } else {
                      // 다른 방법 선택 시 '상관없음' 해제
                      _selectedCookingMethods.remove('상관없음');
                    }
                    _selectedCookingMethods.add(method);
                  }
                  _updateParent();
                });
              },
              accentColor: Color(0xFF26A69A), // 청록색 계열
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeSelector() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('식사 목적', isRequired: true),
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
                children: _commonPurposes.map((purpose) => _buildFilterChip(
                  purpose,
                  _mealPurposes.contains(purpose),
                  () {
                    setState(() {
                      if (_mealPurposes.contains(purpose)) {
                        _mealPurposes.remove(purpose);
                      } else {
                        _mealPurposes.add(purpose);
                      }
                      _updateParent();
                    });
                  },
                  accentColor: Color(0xFF7986CB), // 인디고 계열
                )).toList(),
              ),
              SizedBox(height: 16),
              Text(
                '기타 목적',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mealPurposeController,
                      decoration: _inputDecoration(
                        '직접 입력',
                        hint: '기타 목적이 있다면 입력하세요',
                        icon: Icons.add_circle_outline,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            if (!_mealPurposes.contains(value.trim())) {
                              _mealPurposes.add(value.trim());
                            }
                            _mealPurposeController.clear();
                            _updateParent();
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final value = _mealPurposeController.text.trim();
                      if (value.isNotEmpty) {
                        setState(() {
                          if (!_mealPurposes.contains(value)) {
                            _mealPurposes.add(value);
                          }
                          _mealPurposeController.clear();
                          _updateParent();
                        });
                      }
                    },
                    child: Icon(Icons.add, size: 24),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7986CB),
                      minimumSize: Size(60, 52),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
                '식습관 정보',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '당신의 식습관과 선호도에 맞는 최적의 식단을 추천해 드립니다.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 식이 제한 섹션
        _buildSectionLabel('식이 제한'),
        Row(
          children: [
            // 비건 여부
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      color: _isVegan ? Colors.green[600] : Colors.grey[500],
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '비건/채식',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '채식 식단을 선호합니다',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isVegan,
                      onChanged: (value) {
                        setState(() {
                          _isVegan = value;
                          _updateParent();
                        });
                      },
                      activeColor: Colors.green[600],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            // 종교적 제한 여부
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.church_outlined,
                      color: _isReligiousDiet ? Colors.amber[700] : Colors.grey[500],
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '종교적 제한',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '종교적 이유로 제한',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isReligiousDiet,
                      onChanged: (value) {
                        setState(() {
                          _isReligiousDiet = value;
                          _updateParent();
                        });
                      },
                      activeColor: Colors.amber[700],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // 종교적 제한 상세 (조건부 표시)
        if (_isReligiousDiet) ...[
          SizedBox(height: 16),
          TextField(
            controller: _religionDetailsController,
            decoration: _inputDecoration(
              '종교적 제한 사항', 
              hint: '종교적 식이 제한 사항을 설명해주세요', 
              icon: Icons.info_outline,
              isRequired: true,
            ),
            maxLines: 2,
          ),
        ],
        
        SizedBox(height: 24),
        
        // 식사 목적 섹션
        _buildPurposeSelector(),
        
        SizedBox(height: 24),
        
        // 식사 예산 섹션
        _buildSectionLabel('식사 예산 (1인분 기준)', isRequired: true),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mealBudgetController,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: '1인분 기준 예산',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color, 
                        fontSize: MediaQuery.of(context).size.height < 700 ? 14 : 16,
                        fontFamily: 'NotoSansKR'
                      ),
                      children: <TextSpan>[
                        TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  hintText: '예: 10000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.monetization_on_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '₩',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // 텍스트 필드 내용과의 간격
                    ],
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      '₩',
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey[600]
                      )
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  contentPadding: EdgeInsets.only(
                    left: 60, // 원화 기호와 입력 텍스트 사이의 간격 확보
                    right: 16,
                    top: 14,
                    bottom: 14
                  ),
                  isDense: MediaQuery.of(context).size.height < 700,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateParent(),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24),
        
        // 조리 방법 선택
        _buildCookingMethodSelector(),
        
        SizedBox(height: 24),
        
        // 좋아하는 음식
        _buildChipInputList(
          fieldLabel: '좋아하는 음식',
          inputLabel: '음식 이름 입력',
          controller: _favoriteFoodController,
          itemList: _favoriteFoods,
          onAdd: (food) {
            if (!_favoriteFoods.contains(food)) _favoriteFoods.add(food);
          },
          onRemove: (food) => _favoriteFoods.remove(food),
          focusNode: _favoriteFoodFocusNode,
          listIcon: Icons.favorite,
          chipColor: Colors.red[400],
        ),
        
        SizedBox(height: 8),
        
        // 싫어하는 음식
        _buildChipInputList(
          fieldLabel: '싫어하는 음식',
          inputLabel: '음식 이름 입력',
          controller: _dislikedFoodController,
          itemList: _dislikedFoods,
          onAdd: (food) {
            if (!_dislikedFoods.contains(food)) _dislikedFoods.add(food);
          },
          onRemove: (food) => _dislikedFoods.remove(food),
          focusNode: _dislikedFoodFocusNode,
          listIcon: Icons.not_interested,
          chipColor: Colors.grey[700],
        ),
        
        SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _religionDetailsController.removeListener(_onReligionDetailsChanged);
    _religionDetailsController.dispose();
    _mealBudgetController.dispose();
    _mealPurposeController.dispose();
    _favoriteFoodController.dispose();
    _dislikedFoodController.dispose();
    // _favoriteSeasoningController.dispose();
    // _dislikedSeasoningController.dispose();
    
    // 포커스 노드 정리
    _favoriteFoodFocusNode.dispose();
    _dislikedFoodFocusNode.dispose();
    
    super.dispose();
  }
}