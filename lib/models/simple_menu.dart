// lib/models/simple_menu.dart
class SimpleMenu {
  final String dishName;
  final String category;
  final String description;
  final String mealType;
  final String? calories;
  final List<String>? ingredients;
  final Map<String, dynamic>? nutritionInfo;

  SimpleMenu({
    required this.dishName,
    required this.category,
    required this.description,
    required this.mealType,
    this.calories,
    this.ingredients,
    this.nutritionInfo,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'dish_name': dishName,
      'category': category,
      'description': description,
      'meal_type': mealType,
      if (calories != null) 'calories': calories,
      if (ingredients != null) 'ingredients': ingredients,
      if (nutritionInfo != null) 'nutrition': nutritionInfo,
    };
  }

  // JSON에서 객체 생성
  factory SimpleMenu.fromJson(Map<String, dynamic> json) {
    return SimpleMenu(
      dishName: json['dish_name'] ?? json['dishName'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      mealType: json['meal_type'] ?? json['mealType'] ?? '',
      calories: json['calories'],
      ingredients: json['ingredients'] != null 
          ? List<String>.from(json['ingredients']) 
          : null,
      nutritionInfo: json['nutrition'],
    );
  }
} 