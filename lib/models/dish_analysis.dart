// models/dish_analysis.dart
class DishAnalysis {
  final String dishName;
  final List<String> ingredients;
  final List<String> seasonings;
  final List<String> cookingMethods;
  final int? estimatedCookingTimeMinutes;

  // 추가적인 영양 정보
  final String? calories;
  final String? protein;
  final String? carbohydrates;
  final String? fat;
  final String? fiber;
  final String? sodium;
  final List<String>? vitamins;
  final List<String>? minerals;
  final int? healthIndex;
  final List<String>? suitableFor;

  // 추가적인 조리법 정보
  final List<String>? cookingSteps;
  final String? difficulty;
  final List<String>? tips;

  DishAnalysis({
    required this.dishName,
    required this.ingredients,
    required this.seasonings,
    required this.cookingMethods,
    this.estimatedCookingTimeMinutes,
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
    this.sodium,
    this.vitamins,
    this.minerals,
    this.healthIndex,
    this.suitableFor,
    this.cookingSteps,
    this.difficulty,
    this.tips,
  });

  // 기본 음식 분석 결과에서 모델 생성
  factory DishAnalysis.fromBasicAnalysis(Map<String, dynamic> json) {
    return DishAnalysis(
      dishName: json['dish_name'] as String? ?? '',
      ingredients: _parseStringList(json['ingredients']),
      seasonings: _parseStringList(json['seasonings']),
      cookingMethods: _parseStringList(json['cooking_methods']),
      estimatedCookingTimeMinutes: json['estimated_cooking_time_minutes'] as int?,
    );
  }

  // 음식 분석 + 영양 정보를 합친 모델 생성
  factory DishAnalysis.withNutrition(DishAnalysis basic, Map<String, dynamic> nutritionJson) {
    return DishAnalysis(
      dishName: basic.dishName,
      ingredients: basic.ingredients,
      seasonings: basic.seasonings,
      cookingMethods: basic.cookingMethods,
      estimatedCookingTimeMinutes: basic.estimatedCookingTimeMinutes,
      // 영양 정보 추가
      calories: nutritionJson['calories'] as String?,
      protein: nutritionJson['protein'] as String?,
      carbohydrates: nutritionJson['carbohydrates'] as String?,
      fat: nutritionJson['fat'] as String?,
      fiber: nutritionJson['fiber'] as String?,
      sodium: nutritionJson['sodium'] as String?,
      vitamins: _parseStringList(nutritionJson['vitamins']),
      minerals: _parseStringList(nutritionJson['minerals']),
      healthIndex: nutritionJson['health_index'] as int?,
      suitableFor: _parseStringList(nutritionJson['suitable_for']),
    );
  }

  // 음식 분석 + 조리법 정보를 합친 모델 생성
  factory DishAnalysis.withCookingMethod(
      DishAnalysis basic, Map<String, dynamic> cookingMethodJson) {
    return DishAnalysis(
      dishName: basic.dishName,
      ingredients: basic.ingredients,
      seasonings: basic.seasonings,
      cookingMethods: _parseStringList(cookingMethodJson['cooking_methods']) 
          .isNotEmpty ? _parseStringList(cookingMethodJson['cooking_methods']) : basic.cookingMethods,
      estimatedCookingTimeMinutes: cookingMethodJson['cooking_time_minutes'] as int? ?? basic.estimatedCookingTimeMinutes,
      // 영양 정보 유지
      calories: basic.calories,
      protein: basic.protein,
      carbohydrates: basic.carbohydrates,
      fat: basic.fat,
      fiber: basic.fiber,
      sodium: basic.sodium,
      vitamins: basic.vitamins,
      minerals: basic.minerals,
      healthIndex: basic.healthIndex,
      suitableFor: basic.suitableFor,
      // 조리법 정보 추가
      cookingSteps: _parseStringList(cookingMethodJson['cooking_steps']),
      difficulty: cookingMethodJson['difficulty'] as String?,
      tips: _parseStringList(cookingMethodJson['tips']),
    );
  }

  // 모든 정보를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'dish_name': dishName,
      'ingredients': ingredients,
      'seasonings': seasonings,
      'cooking_methods': cookingMethods,
      'estimated_cooking_time_minutes': estimatedCookingTimeMinutes,
      // 영양 정보
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbohydrates != null) 'carbohydrates': carbohydrates,
      if (fat != null) 'fat': fat,
      if (fiber != null) 'fiber': fiber,
      if (sodium != null) 'sodium': sodium,
      if (vitamins != null) 'vitamins': vitamins,
      if (minerals != null) 'minerals': minerals,
      if (healthIndex != null) 'health_index': healthIndex,
      if (suitableFor != null) 'suitable_for': suitableFor,
      // 조리법 정보
      if (cookingSteps != null) 'cooking_steps': cookingSteps,
      if (difficulty != null) 'difficulty': difficulty,
      if (tips != null) 'tips': tips,
    };
  }

  // 문자열 리스트 파싱 헬퍼 메서드
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  // 복제 메서드 (수정된 복사본 생성)
  DishAnalysis copyWith({
    String? dishName,
    List<String>? ingredients,
    List<String>? seasonings,
    List<String>? cookingMethods,
    int? estimatedCookingTimeMinutes,
    String? calories,
    String? protein,
    String? carbohydrates,
    String? fat,
    String? fiber, 
    String? sodium,
    List<String>? vitamins,
    List<String>? minerals,
    int? healthIndex,
    List<String>? suitableFor,
    List<String>? cookingSteps,
    String? difficulty,
    List<String>? tips,
  }) {
    return DishAnalysis(
      dishName: dishName ?? this.dishName,
      ingredients: ingredients ?? this.ingredients,
      seasonings: seasonings ?? this.seasonings,
      cookingMethods: cookingMethods ?? this.cookingMethods,
      estimatedCookingTimeMinutes: estimatedCookingTimeMinutes ?? this.estimatedCookingTimeMinutes,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      vitamins: vitamins ?? this.vitamins,
      minerals: minerals ?? this.minerals,
      healthIndex: healthIndex ?? this.healthIndex,
      suitableFor: suitableFor ?? this.suitableFor,
      cookingSteps: cookingSteps ?? this.cookingSteps,
      difficulty: difficulty ?? this.difficulty,
      tips: tips ?? this.tips,
    );
  }
} 