// screens/saved_meals_screen.dart
// (이전 flutter_saved_meals_screen_updated 문서 내용과 동일)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class SavedMealsScreen extends StatefulWidget {
  @override
  _SavedMealsScreenState createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  Future<void> _navigateToRecipeDetail(BuildContext context, Meal meal) async {
    try {
      print('레시피 상세 화면 이동 시도 - 메뉴: ${meal.name}, recipeJson 존재: ${meal.recipeJson != null}');
      
      if (meal.recipeJson != null && meal.recipeJson!.isNotEmpty) {
        print('저장된 레시피 JSON: ${meal.recipeJson}');
        try {
          final recipe = Recipe.fromJson(meal.recipeJson!);
          print('레시피 변환 성공: ${recipe.title}');
          
          // 상세 화면으로 이동
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))
          );
          return;
        } catch (parseError) {
          print('레시피 JSON 파싱 오류: $parseError');
          // 파싱 오류 시 새로운 레시피 생성 시도로 진행
        }
      }
      
      // 저장된 레시피가 없거나 파싱에 실패한 경우 새로 생성 시도
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      
      // 로딩 상태 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('레시피 정보를 불러오는 중...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      print('새 레시피 생성 시도: ${meal.name}');
      final Recipe? generatedRecipe = await mealProvider.loadRecipeDetails(meal.name);
      
      if (generatedRecipe != null) {
        print('새 레시피 생성 성공: ${generatedRecipe.title}');
        
        // 생성된 레시피가 있으면 상세 화면으로 이동
        if (mounted) {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: generatedRecipe))
          );
        }
      } else {
        print('레시피 생성 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('레시피를 생성할 수 없습니다. 나중에 다시 시도해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('레시피 상세 화면 이동 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 카테고리에 따른 색상 반환
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
      case '아침':
        return Colors.orange[700]!;
      case 'lunch':
      case '점심':
        return Colors.green[700]!;
      case 'dinner':
      case '저녁':
        return Colors.indigo[700]!;
      case 'snack':
      case '간식':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final Map<String, List<Meal>> allSavedMeals = mealProvider.savedMealsByDate;
    final sortedDates = allSavedMeals.keys.toList()..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: Text('저장된 식단 목록')),
      body: allSavedMeals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 100, color: Colors.grey[400]),
                  SizedBox(height: 20),
                  Text('저장된 식단이 아직 없어요.', style: TextStyle(fontSize: 18, color: Colors.grey[600]))
                ]
              )
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: sortedDates.length,
              itemBuilder: (context, dateIndex) {
                final dateString = sortedDates[dateIndex];
                final mealsForDate = allSavedMeals[dateString]!;
                final date = DateTime.parse(dateString);
                
                // 카테고리별로 분류
                final Map<String, List<Meal>> mealsByCategory = {};
                for (final meal in mealsForDate) {
                  mealsByCategory.putIfAbsent(meal.category, () => []).add(meal);
                }
                
                final categories = ['breakfast', 'lunch', 'dinner', 'snack'];
                final categoryNames = {
                  'breakfast': '아침',
                  'lunch': '점심',
                  'dinner': '저녁',
                  'snack': '간식',
                };
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                      child: Text(
                        '${date.year}년 ${date.month}월 ${date.day}일 (${_getWeekday(date)})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor
                        )
                      )
                    ),
                    ...categories.where((cat) => mealsByCategory.containsKey(cat)).map((cat) {
                      final meals = mealsByCategory[cat]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(cat).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getCategoryColor(cat).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${categoryNames[cat] ?? cat}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getCategoryColor(cat),
                                )
                              ),
                            ),
                          ),
                          ...meals.map((meal) => Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                print('식단 카드 탭: ${meal.name}');
                                _navigateToRecipeDetail(context, meal);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getCategoryColor(cat).withOpacity(0.2),
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        color: _getCategoryColor(cat),
                                      )
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            meal.description,
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.orange.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.local_fire_department,
                                                  size: 16,
                                                  color: Colors.orange[600],
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  meal.calories.isNotEmpty && meal.calories != '칼로리 정보 없음'
                                                      ? meal.calories
                                                      : '칼로리 정보 없음',
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }
  
  // 요일 문자열 반환 (한글)
  String _getWeekday(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final index = date.weekday - 1; // DateTime에서 월요일은 1, 일요일은 7
    return weekdays[index];
  }
}