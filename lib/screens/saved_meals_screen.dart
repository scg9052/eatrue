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
    if (meal.recipeJson != null) {
      final recipe = Recipe.fromJson(meal.recipeJson!);
      Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이 식단에는 저장된 레시피 정보가 없습니다.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final Map<String, List<Meal>> allSavedMeals = mealProvider.savedMealsByDate;
    final sortedDates = allSavedMeals.keys.toList()..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
    return Scaffold(
      appBar: AppBar(title: Text('저장된 식단 목록')),
      body: allSavedMeals.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmark_border, size: 100, color: Colors.grey[400]), SizedBox(height: 20), Text('저장된 식단이 아직 없어요.', style: TextStyle(fontSize: 18, color: Colors.grey[600]))]))
          : ListView.builder(padding: EdgeInsets.all(12), itemCount: sortedDates.length, itemBuilder: (context, dateIndex) {
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
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0), child: Text('${date.year}년 ${date.month}월 ${date.day}일 (${_getWeekday(date)})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
          ...categories.where((cat) => mealsByCategory.containsKey(cat)).map((cat) {
            final meals = mealsByCategory[cat]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                  child: Text('${categoryNames[cat] ?? cat}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
                ),
                ...meals.map((meal) => Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColorLight, child: Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColorDark)),
                    title: Text(meal.name, style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${meal.description}\n${(meal.calories != null && meal.calories!.isNotEmpty) ? '${meal.calories} kcal' : '칼로리 정보 없음'}', style: TextStyle(color: Colors.grey[600])),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => _navigateToRecipeDetail(context, meal),
                  ),
                )),
              ],
            );
          }).toList(),
          if (dateIndex < sortedDates.length -1) Divider(height: 20, thickness: 1),
        ]);
      }),
    );
  }
  String _getWeekday(DateTime date) { const weekdays = ['월', '화', '수', '목', '금', '토', '일']; return weekdays[date.weekday - 1]; }
}