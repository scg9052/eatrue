import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/meal_provider.dart';
import '../../models/meal.dart';
import '../../utils/meal_type_utils.dart';
import '../../screens/recipe_detail_screen.dart';
import 'meal_card.dart';
import 'meal_add_dialog.dart';

/// 홈 화면의 식단 목록을 표시하는 위젯
class MealList extends StatelessWidget {
  final MealProvider mealProvider;
  final DateTime selectedDate;
  
  const MealList({
    Key? key,
    required this.mealProvider,
    required this.selectedDate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final Map<String, Meal?> mealsForDate = mealProvider.getMealsByDate(selectedDate);
    
    // 날짜 포맷팅
    final DateFormat formatter = DateFormat('M월 d일 (E)', 'ko_KR');
    final String formattedDate = formatter.format(selectedDate);
    
    // 디버깅 로그 추가
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("MealList - selectedDate: $selectedDate, dateKey: $dateKey");
    print("MealList - mealsForDate: ${mealsForDate.entries.map((e) => '${e.key}: ${e.value?.name ?? "null"}').join(', ')}");
    print("MealList - 전체 저장된 식단 키 목록: ${mealProvider.savedMealsByDate.keys.join(', ')}");
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택된 날짜 표시
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // 식단 타입 순서 정의
            ..._buildMealTypeSection(context, '아침', mealsForDate['아침']),
            ..._buildMealTypeSection(context, '점심', mealsForDate['점심']),
            ..._buildMealTypeSection(context, '저녁', mealsForDate['저녁']),
            ..._buildMealTypeSection(context, '간식', mealsForDate['간식']),
            // 기타 카테고리 추가
            if (mealsForDate.containsKey('기타') && mealsForDate['기타'] != null)
              ..._buildMealTypeSection(context, '기타', mealsForDate['기타']),
          ],
        ),
      ),
    );
  }
  
  // 식사 타입 섹션 빌드 (식단 카드 또는 추가 버튼)
  List<Widget> _buildMealTypeSection(BuildContext context, String mealType, Meal? meal) {
    return [
      // 식사 타입 헤더
      Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
        child: Text(
          mealType,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      
      // 식단 카드 또는 추가 버튼
      meal != null 
        ? MealCard(
            meal: meal,
            onTap: () => _viewRecipe(context, meal),
            onDelete: () => _confirmDeleteMeal(context, meal),
          )
        : _buildAddMealButton(context, mealType),
    ];
  }
  
  // 식단 추가 버튼
  Widget _buildAddMealButton(BuildContext context, String mealType) {
    // 언어에 상관없이 표준화된 카테고리 사용
    final String standardCategory = standardizeCategory(mealType, toKorean: false);
    
    // 생성된 메뉴가 있는지 확인
    final bool hasGeneratedMenus = mealProvider.generatedMenuByMealType.isNotEmpty &&
                               mealProvider.generatedMenuByMealType.containsKey(standardCategory);
    
    // 오늘 날짜인지 확인
    final bool isToday = _isToday(selectedDate);
    
    // 오늘 날짜이고 생성된 메뉴가 있는 경우 다른 스타일 적용
    final bool showRecommended = isToday && hasGeneratedMenus;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () => _addMeal(context, mealType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24),
          decoration: showRecommended 
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ) 
            : null,
          child: Column(
            children: [
              Icon(
                showRecommended ? Icons.recommend : Icons.add_circle_outline,
                size: 36,
                color: showRecommended 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[500],
              ),
              SizedBox(height: 8),
              Text(
                showRecommended 
                  ? '$mealType 추천 메뉴 보기' 
                  : '$mealType 식사 추가하기',
                style: TextStyle(
                  color: showRecommended 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey[600],
                  fontWeight: showRecommended 
                    ? FontWeight.bold 
                    : FontWeight.w500,
                ),
              ),
              if (showRecommended)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '${mealProvider.generatedMenuByMealType[standardCategory]?.length ?? 0}개의 추천 메뉴가 있습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 날짜가 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // 식사 추가 다이얼로그 띄우기
  void _addMeal(BuildContext context, String mealType) {
    showMealAddDialog(context, selectedDate, mealType);
  }
  
  // 레시피 상세 보기
  void _viewRecipe(BuildContext context, Meal meal) async {
    try {
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('레시피 정보를 불러오는 중...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      print('레시피 생성 시도: ${meal.name}');
      print('메뉴 칼로리 정보: ${meal.calories}');
      print('레시피 JSON 존재 여부: ${meal.recipeJson != null ? "있음" : "없음"}');
      
      final recipe = await mealProvider.generateRecipe(meal);
      
      if (recipe != null) {
        print('레시피 생성 성공: ${recipe.title}');
        print('레시피 세부 정보 - 조리단계: ${recipe.cookingInstructions.length}, 재료: ${recipe.ingredients?.length ?? 0}');
        
        // 성공 시 화면 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      } else {
        print('레시피 생성 실패');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('레시피를 생성할 수 없습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('레시피 생성 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // 식단 삭제 확인 다이얼로그
  void _confirmDeleteMeal(BuildContext context, Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('식단 삭제'),
        content: Text('${meal.name} 식단을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            child: Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('삭제', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              try {
                Navigator.pop(context);
                // 삭제 로직 구현
                await mealProvider.removeMeal(meal, selectedDate);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${meal.name} 식단이 삭제되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('삭제 실패: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
} 