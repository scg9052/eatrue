// widgets/survey_pages/survey_page_food_preference.dart
// (이전 답변의 flutter_recipe_app_v1_religious_required 문서 내용과 거의 동일,
// UserData 모델에 dislikedCookingMethods, favoriteSeasonings, dislikedSeasonings 필드 추가 시 해당 UI 요소 추가 필요)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';
import '../../l10n/app_localizations.dart';

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

  late List<String> _allCookingMethods;
  List<String> _selectedCookingMethods = [];

  // 식사 목적 옵션
  late List<String> _commonPurposes;

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

    _religionDetailsController.addListener(_onReligionDetailsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localization = AppLocalizations.of(context);
    
    // 지역화된 요리 방법 목록
    _allCookingMethods = localization.isKorean() ? 
      ['상관없음','구이', '찜', '조림', '볶음', '튀김', '국/탕', '무침', '생식', '데치기', '굽기(오븐/에어프라이어)'] :
      ['Any','Grilling', 'Steaming', 'Braising', 'Stir-frying', 'Deep-frying', 'Soup/Stew', 'Seasoning', 'Raw', 'Blanching', 'Baking(Oven/Air fryer)'];
    
    // 지역화된 식사 목적 옵션
    _commonPurposes = localization.isKorean() ? [
      '건강 관리',
      '체중 감량',
      '근육 증가',
      '영양 균형',
      '에너지 향상',
      '식이 제한 관리',
      '맛있는 식사',
      '경제적인 식사'
    ] : [
      'Health Management',
      'Weight Loss',
      'Muscle Gain',
      'Nutritional Balance',
      'Energy Boost',
      'Dietary Restriction Management',
      'Delicious Meals',
      'Budget-Friendly Meals'
    ];
  }

  @override
  void dispose() {
    _religionDetailsController.dispose();
    _mealPurposeController.dispose();
    _mealBudgetController.dispose();
    _favoriteFoodController.dispose();
    _dislikedFoodController.dispose();
    _favoriteFoodFocusNode.dispose();
    _dislikedFoodFocusNode.dispose();
    super.dispose();
  }

  void _onReligionDetailsChanged() {
    if (!_isReligiousDiet && _religionDetailsController.text.isNotEmpty) {
      setState(() {
        _isReligiousDiet = true;
      });
    }
    _updateParent();
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
    final localization = AppLocalizations.of(context);
    
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
                decoration: InputDecoration(
                  hintText: hintText ?? (localization.isKorean() ? '$inputLabel 입력 후 \'추가\' 또는 Enter' : 'Enter $inputLabel and press \'Add\' or Enter'),
                  prefixIcon: Icon(Icons.edit_note, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final localization = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(localization.cookingMethodsLabel, isRequired: true),
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
    final localization = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(localization.mealPurposeLabel, isRequired: true),
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
                      decoration: InputDecoration(
                        hintText: localization.mealPurposeHint,
                        prefixIcon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final localization = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
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
                  localization.foodPreferenceTitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                  localization.isKorean() 
                      ? '식품 선호도 정보를 입력하시면 취향에 맞는 식단을 추천해 드립니다.'
                      : 'Enter your food preferences to get meal recommendations that match your taste.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 식이 제한 섹션
          _buildSectionLabel(localization.isKorean() ? '식이 제한 사항' : 'Dietary Restrictions'),
          
          // 채식주의자 여부
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // 채식주의자 여부
                SwitchListTile(
                  title: Text(
                    localization.isVeganLabel,
                            style: TextStyle(
                      fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  value: _isVegan,
                  onChanged: (value) {
                    setState(() {
                      _isVegan = value;
                      _updateParent();
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                
                Divider(),
                
                // 종교적 제한 여부
                SwitchListTile(
                  title: Text(
                    localization.isReligiousLabel,
                            style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      ),
                    ),
                  value: _isReligiousDiet,
                      onChanged: (value) {
                        setState(() {
                      _isReligiousDiet = value;
                      if (!value) {
                        _religionDetailsController.text = '';
                      }
                          _updateParent();
                        });
                      },
                  activeColor: theme.colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                    ),
                
                // 종교적 제한 사항 상세 텍스트 필드
                if (_isReligiousDiet) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Text(
                      localization.religionDetailsLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _religionDetailsController,
                    decoration: InputDecoration(
                      hintText: localization.isKorean() ? '예: 할랄, 코셔 등' : 'e.g. Halal, Kosher, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 선호 식품 섹션
          _buildSectionLabel(localization.favoriteFoodsLabel),
          
          Container(
            width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // 선호 식품이 있을 때만 목록 표시
                if (_favoriteFoods.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _favoriteFoods.map((food) => _buildAnimatedChip(
                      food,
                      Icons.favorite,
                      Colors.pinkAccent,
                      () {
                        setState(() {
                          _favoriteFoods.remove(food);
                          _updateParent();
                        });
                      },
                    )).toList(),
                          ),
                  SizedBox(height: 16),
                ],
                
                // 입력 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _favoriteFoodController,
                        focusNode: _favoriteFoodFocusNode,
                        decoration: InputDecoration(
                          hintText: localization.isKorean() ? '선호하는 음식을 입력하세요' : 'Enter your favorite foods',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              final foods = value.split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                              
                              for (final food in foods) {
                                if (!_favoriteFoods.contains(food)) {
                                  _favoriteFoods.add(food);
                                }
                              }
                              
                              _favoriteFoodController.clear();
                              _updateParent();
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final value = _favoriteFoodController.text.trim();
                        if (value.isNotEmpty) {
                        setState(() {
                            final foods = value.split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            
                            for (final food in foods) {
                              if (!_favoriteFoods.contains(food)) {
                                _favoriteFoods.add(food);
                              }
                            }
                            
                            _favoriteFoodController.clear();
                          _updateParent();
                        });
                          // 입력 후 키보드를 내리지 않고 포커스 유지
                          FocusScope.of(context).requestFocus(_favoriteFoodFocusNode);
                        }
                      },
                      child: Text(localization.isKorean() ? '추가' : 'Add'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                Text(
                  localization.isKorean() ? '쉼표로 구분하여 여러 음식을 한 번에 추가할 수 있습니다.' : 'You can add multiple foods at once, separated by commas.',
                  style: TextStyle(
                    fontSize: 12, 
                    color: theme.hintColor,
                    fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
          ),
          
          // 기피 식품 섹션
          _buildSectionLabel(localization.dislikedFoodsLabel),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기피 식품이 있을 때만 목록 표시
                if (_dislikedFoods.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dislikedFoods.map((food) => _buildAnimatedChip(
                      food,
                      Icons.do_not_disturb,
                      Colors.redAccent,
                      () {
                        setState(() {
                          _dislikedFoods.remove(food);
                          _updateParent();
                        });
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                ],
                
                // 입력 필드
        Row(
          children: [
            Expanded(
              child: TextField(
                        controller: _dislikedFoodController,
                        focusNode: _dislikedFoodFocusNode,
                decoration: InputDecoration(
                          hintText: localization.isKorean() ? '기피하는 음식을 입력하세요' : 'Enter foods you dislike',
                  border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              final foods = value.split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                              
                              for (final food in foods) {
                                if (!_dislikedFoods.contains(food)) {
                                  _dislikedFoods.add(food);
                                }
                              }
                              
                              _dislikedFoodController.clear();
                              _updateParent();
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final value = _dislikedFoodController.text.trim();
                        if (value.isNotEmpty) {
                          setState(() {
                            final foods = value.split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            
                            for (final food in foods) {
                              if (!_dislikedFoods.contains(food)) {
                                _dislikedFoods.add(food);
                              }
                            }
                            
                            _dislikedFoodController.clear();
                            _updateParent();
                          });
                          // 입력 후 키보드를 내리지 않고 포커스 유지
                          FocusScope.of(context).requestFocus(_dislikedFoodFocusNode);
                        }
                      },
                      child: Text(localization.isKorean() ? '추가' : 'Add'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                Text(
                  localization.isKorean() ? '쉼표로 구분하여 여러 음식을 한 번에 추가할 수 있습니다.' : 'You can add multiple foods at once, separated by commas.',
                          style: TextStyle(
                    fontSize: 12, 
                    color: theme.hintColor,
                    fontStyle: FontStyle.italic,
                          ),
                        ),
              ],
            ),
          ),
          
          // 선호 조리법 섹션
          _buildCookingMethodSelector(),
          
          SizedBox(height: 24),
          
          // 한 끼 예산 섹션 추가
          _buildSectionLabel(localization.isKorean() ? '한 끼 예산' : 'Meal Budget', isRequired: true),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _mealBudgetController,
                  decoration: InputDecoration(
                    labelText: localization.isKorean() ? '한 끼 최대 예산' : 'Maximum budget per meal',
                    hintText: localization.isKorean() ? '예산 입력 (단위: 원)' : 'Enter budget (unit: KRW)',
                    prefixIcon: Icon(Icons.monetization_on, color: theme.colorScheme.primary),
                    suffixText: localization.isKorean() ? '원' : 'KRW',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateParent(),
                ),
                SizedBox(height: 8),
                Text(
                  localization.isKorean() 
                      ? '예산에 맞는 재료와 레시피를 추천해 드립니다.' 
                      : 'We will recommend ingredients and recipes that fit your budget.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
            ),
        ),
        
        SizedBox(height: 24),
        
          // 식사 목적 섹션
          _buildSectionLabel(localization.isKorean() ? '식사 목적 (선택)' : 'Meal Purpose (Optional)'),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 선택된 목적 표시
                if (_mealPurposes.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealPurposes.map((purpose) => _buildAnimatedChip(
                      purpose,
                      Icons.flag,
                      Color(0xFF7986CB), // 인디고 계열
                      () {
                        setState(() {
                          _mealPurposes.remove(purpose);
                          _updateParent();
                        });
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                ],
                
                // 일반적인 목적 버튼
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonPurposes.map((purpose) {
                    return ActionChip(
                      label: Text(purpose),
                      onPressed: () {
                        setState(() {
                          if (!_mealPurposes.contains(purpose)) {
                            _mealPurposes.add(purpose);
                            _updateParent();
                          }
                        });
          },
                      avatar: Icon(Icons.add, size: 16, color: Color(0xFF7986CB)),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: Color(0xFF7986CB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
        ),
        
        SizedBox(height: 16),
                
                // 직접 입력 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mealPurposeController,
                        decoration: InputDecoration(
                          hintText: localization.mealPurposeHint,
                          prefixIcon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
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
      ),
    );
  }
}