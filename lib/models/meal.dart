// models/meal.dart
// (이전 flutter_models_firestore_ready 문서 내용과 동일)
class Meal {
  final String id;
  final String name;
  final String description;
  final String calories;
  final DateTime date;
  final String category;
  final Map<String, dynamic>? recipeJson;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    this.calories = '칼로리 정보 없음',
    required this.date,
    required this.category,
    this.recipeJson,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calories': calories.isEmpty ? '칼로리 정보 없음' : calories,
      'date': date.toIso8601String(),
      'category': category,
      if (recipeJson != null) 'recipeJson': recipeJson,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    String category = json['category'] as String? ?? '';
    if (category.isEmpty) {
      category = '기타';
    }
    
    String caloriesValue = json['calories'] as String? ?? '';
    if (caloriesValue.isEmpty) {
      caloriesValue = '칼로리 정보 없음';
    }
    
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      calories: caloriesValue,
      date: DateTime.parse(json['date'] as String),
      category: category,
      recipeJson: json['recipeJson'] as Map<String, dynamic>?,
    );
  }
}
