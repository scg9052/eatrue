class Recipe {
  final String id;
  final String mealId;
  final String title; // LLM 응답의 'dish_name'
  final String? costInformation;
  final Map<String, dynamic>? nutritionalInformation;
  final Map<String, String>? ingredients; // API 스펙: Dict 식재료명:양
  final Map<String, String>? seasonings;  // API 스펙: Dict 양념명:양
  final List<String> cookingInstructions;
  final int? cookingTimeMinutes;
  final String? difficulty;
  double rating;

  Recipe({
    required this.id,
    this.mealId = '',
    required this.title,
    this.costInformation,
    this.nutritionalInformation,
    this.ingredients,
    this.seasonings,
    required this.cookingInstructions,
    this.cookingTimeMinutes,
    this.difficulty,
    this.rating = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealId': mealId,
      'dish_name': title,
      'cost_information': costInformation,
      'nutritional_information': nutritionalInformation,
      'ingredients': ingredients,
      'seasonings': seasonings,
      'cooking_instructions': cookingInstructions,
      'cookingTimeMinutes': cookingTimeMinutes,
      'difficulty': difficulty,
      'rating': rating,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? json['dish_name'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      mealId: json['mealId'] as String? ?? '',
      title: json['dish_name'] as String? ?? json['title'] as String? ?? '제목 없음',
      costInformation: json['cost_information'] as String?,
      nutritionalInformation: json['nutritional_information'] as Map<String, dynamic>?,
      ingredients: (() {
        final raw = json['ingredients'];
        if (raw is Map<String, dynamic>) {
          return raw.map((k, v) => MapEntry(k, v.toString()));
        } else if (raw is List) {
          return {
            for (final item in raw)
              if (item is Map && item['name'] != null && item['quantity'] != null)
                item['name'].toString(): item['quantity'].toString()
          };
        }
        return null;
      })(),
      seasonings: (() {
        final raw = json['seasonings'];
        if (raw is Map<String, dynamic>) {
          return raw.map((k, v) => MapEntry(k, v.toString()));
        } else if (raw is List) {
          return {
            for (final item in raw)
              if (item is Map && item['name'] != null && item['quantity'] != null)
                item['name'].toString(): item['quantity'].toString()
          };
        }
        return null;
      })(),
      cookingInstructions: (json['cooking_instructions'] as List<dynamic>?)
          ?.map((step) => step.toString())
          .toList() ??
          [],
      cookingTimeMinutes: json['cookingTimeMinutes'] as int?,
      difficulty: json['difficulty'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}