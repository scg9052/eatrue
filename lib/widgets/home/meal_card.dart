import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../utils/meal_type_utils.dart';
import '../../l10n/app_localizations.dart';

/// 하나의 식단 카드를 표시하는 위젯
class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealTypeIcon = getMealTypeIcon(meal.category);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localization = AppLocalizations.of(context);
    
    // 디버깅용 로그 추가
    print('MealCard 빌드 - 메뉴: ${meal.name}, 칼로리: ${meal.calories}, 레시피 JSON: ${meal.recipeJson != null ? "있음" : "없음"}');
    
    Text mealTitleText = Text(
      meal.name,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget mealCategoryText = Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        meal.category.isNotEmpty ? meal.category : '기타',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
    
    // 칼로리 정보 추출 및 표시 로직 개선
    String displayCalories = _extractCaloriesText();
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 식단 이름 및 삭제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(mealTypeIcon, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: mealTitleText,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null) 
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: onDelete,
                    ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // 카테고리와 칼로리 정보를 한 줄에 표시
              Padding(
                padding: EdgeInsets.only(left: 32),
                child: Row(
                  children: [
                    mealCategoryText,
                    SizedBox(width: 8),
                    
                    // 칼로리 태그
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, size: 12, color: Colors.orange[700]),
                          SizedBox(width: 2),
                          Text(
                            displayCalories,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 식단 설명
              if (meal.description?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 32),
                  child: Text(
                    meal.description!,
                    style: TextStyle(
                      fontSize: 14, 
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700]
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // 레시피/영양소 요약 정보
              _buildNutritionSummary(context),
              
              // 레시피 상세 보기 안내
              if (meal.recipeJson != null)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 32),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        localization.viewRecipe,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 칼로리 텍스트 추출 메서드
  String _extractCaloriesText() {
    // BuildContext 접근 불가능, 하드코딩된 스트링 사용
    final noCaloriesString = 'No calories information';
    
    // 디버깅 로그 추가
    print('_extractCaloriesText 호출됨: ${meal.name}');
    print('meal.calories: ${meal.calories}');
    print('meal.recipeJson 존재 여부: ${meal.recipeJson != null}');
    
    // 기본 칼로리 정보 (meal.calories)
    String baseCalories = meal.calories?.isNotEmpty == true 
                      && meal.calories != noCaloriesString
                      ? meal.calories
                      : '';
    
    print('baseCalories 초기값: "$baseCalories"');
                      
    // recipeJson에서 추가 칼로리 정보 확인
    if ((baseCalories.isEmpty || baseCalories == noCaloriesString) && meal.recipeJson != null) {
      // 1. nutritional_information 확인
      if (meal.recipeJson!.containsKey('nutritional_information')) {
        final nutritionInfo = meal.recipeJson!['nutritional_information'];
        if (nutritionInfo is Map) {
          // 여러 가능한 키 확인
          final caloriesKeys = ['calories', 'calorie', 'Calories', 'calories information'];
          for (final key in caloriesKeys) {
            if (nutritionInfo.containsKey(key)) {
              baseCalories = nutritionInfo[key].toString();
              print('nutritional_information에서 칼로리 찾음: $baseCalories');
              break;
            }
          }
        }
      }
      
      // 2. nutrition 확인
      if (baseCalories.isEmpty && meal.recipeJson!.containsKey('nutrition')) {
        final nutrition = meal.recipeJson!['nutrition'];
        if (nutrition is Map) {
          final caloriesKeys = ['calories', 'calorie', 'Calories', 'calories information'];
          for (final key in caloriesKeys) {
            if (nutrition.containsKey(key)) {
              baseCalories = nutrition[key].toString();
              print('nutrition에서 칼로리 찾음: $baseCalories');
              break;
            }
          }
        }
      }
      
      // 3. 직접 calories 키 확인
      if (baseCalories.isEmpty && meal.recipeJson!.containsKey('calories')) {
        baseCalories = meal.recipeJson!['calories'].toString();
        print('최상위 calories에서 칼로리 찾음: $baseCalories');
      }
      
      // 4. approximate_nutrients 확인
      if (baseCalories.isEmpty && meal.recipeJson!.containsKey('approximate_nutrients')) {
        final approxNutrients = meal.recipeJson!['approximate_nutrients'];
        if (approxNutrients is Map) {
          final caloriesKeys = ['calories', 'calorie', 'Calories', 'calories information', 'energy'];
          for (final key in caloriesKeys) {
            if (approxNutrients.containsKey(key)) {
              baseCalories = approxNutrients[key].toString();
              print('approximate_nutrients에서 칼로리 찾음: $baseCalories');
              break;
            }
          }
        }
      }
    }
    
    // 칼로리 정보 포맷팅
    if (baseCalories.isNotEmpty && baseCalories != noCaloriesString) {
      // 숫자만 있는지 확인
      bool hasNonDigit = false;
      for (int i = 0; i < baseCalories.length; i++) {
        if (!(baseCalories[i] == '.' || baseCalories[i] == ',' || 
              baseCalories[i] == '-' || baseCalories[i] == '~' || 
              baseCalories[i].codeUnitAt(0) >= 48 && baseCalories[i].codeUnitAt(0) <= 57)) {
          hasNonDigit = true;
          break;
        }
      }
      
      // kcal 표시 추가
      if (!baseCalories.toLowerCase().contains('kcal') && 
          !baseCalories.toLowerCase().contains('calorie')) {
        return '$baseCalories kcal';
      } else {
        return baseCalories;
      }
    }
    
    return noCaloriesString;
  }
  
  // 영양소 요약 정보 위젯
  Widget _buildNutritionSummary(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localization = AppLocalizations.of(context);
    
    // 레시피 JSON에서 영양 정보 추출 시도
    Map<String, dynamic>? nutritionInfo;
    if (meal.recipeJson != null) {
      try {
        // 여러 가능한 필드 이름 확인
        final nutritionKeys = ['nutritional_information', 'nutrition', 'nutritionalInformation'];
        for (final key in nutritionKeys) {
          if (meal.recipeJson!.containsKey(key) && meal.recipeJson![key] is Map) {
            nutritionInfo = meal.recipeJson![key] as Map<String, dynamic>;
            break;
          }
        }
      } catch (e) {
        print('영양 정보 추출 실패: $e');
      }
    }
    
    if (nutritionInfo == null || nutritionInfo.isEmpty) {
      return SizedBox.shrink(); // 영양 정보가 없으면 표시하지 않음
    }
    
    // 표시할 주요 영양소
    final nutrientLabels = {
      'protein': localization.protein,
      'carbohydrates': localization.carbohydrates,
      'carbs': localization.carbohydrates,
      'fats': localization.fats,
      'fat': localization.fats,
      'fiber': localization.fiber,
    };
    
    // 칼로리는 이미 별도로 표시하므로 제외
    final caloriesKeys = ['calories', 'calorie', 'Calories', '칼로리'];
    for (final key in caloriesKeys) {
      nutritionInfo.remove(key);
    }
    
    List<Widget> nutrientWidgets = [];
    
    // 영양소 정보가 있는 경우 표시
    nutrientLabels.forEach((key, label) {
      if (nutritionInfo!.containsKey(key) && nutritionInfo![key] != null) {
        nutrientWidgets.add(
          Container(
            margin: EdgeInsets.only(right: 6),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: Text(
              '$label: ${nutritionInfo![key]}',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.green[200] : Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    });
    
    if (nutrientWidgets.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Padding(
      padding: EdgeInsets.only(top: 8, left: 32),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: nutrientWidgets,
      ),
    );
  }
} 