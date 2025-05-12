import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/meal_provider.dart';
import '../../models/meal.dart';
import '../../utils/meal_type_utils.dart';
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
    // 영어 카테고리 매핑
    final String englishMealType = getEnglishMealCategory(mealType);
    
    // 생성된 메뉴가 있는지 확인
    final bool hasGeneratedMenus = mealProvider.generatedMenuByMealType.isNotEmpty &&
                               mealProvider.generatedMenuByMealType.containsKey(englishMealType);
    
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
                    '${mealProvider.generatedMenuByMealType[englishMealType]?.length ?? 0}개의 추천 메뉴가 있습니다',
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
  void _viewRecipe(BuildContext context, Meal meal) {
    // 레시피가 있으면 상세 화면으로 이동
    if (meal.recipeJson != null) {
      mealProvider.generateRecipe(meal);
      Navigator.pushNamed(context, '/recipe', arguments: meal);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('레시피 정보가 없습니다.'),
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