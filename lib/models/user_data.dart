// models/user_data.dart
class UserData {
  int? age;
  String? gender;
  double? height;
  double? weight;
  String? activityLevel;
  List<String> underlyingConditions;
  List<String> allergies;
  bool isVegan;
  bool isReligious;
  String? religionDetails;
  List<String> mealPurpose;
  double? mealBudget;
  List<String> favoriteFoods;
  List<String> dislikedFoods;
  List<String> preferredCookingMethods;
  List<String> availableCookingTools;
  int? preferredCookingTime;
  
  // 선호 식품 분해 결과를 저장할 새 필드
  List<String> preferredIngredients; // 선호 식재료
  List<String> preferredSeasonings;  // 선호 양념
  List<String> preferredCookingStyles; // 선호 조리 방식
  
  // 기피 식품 분해 결과를 저장할 새 필드
  List<String> dislikedIngredients; // 기피 식재료
  List<String> dislikedSeasonings;  // 기피 양념
  List<String> dislikedCookingStyles; // 기피 조리 방식

  UserData({
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel = "보통 (주 3-5회 중간 강도 운동)", // 기본값 설정
    this.underlyingConditions = const [],
    this.allergies = const [],
    this.isVegan = false,
    this.isReligious = false,
    this.religionDetails,
    this.mealPurpose = const [],
    this.mealBudget,
    this.favoriteFoods = const [],
    this.dislikedFoods = const [],
    this.preferredCookingMethods = const [],
    this.availableCookingTools = const [],
    this.preferredCookingTime,
    // 선호/기피 식품 분해 필드 초기화
    this.preferredIngredients = const [],
    this.preferredSeasonings = const [],
    this.preferredCookingStyles = const [],
    this.dislikedIngredients = const [],
    this.dislikedSeasonings = const [],
    this.dislikedCookingStyles = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'underlyingConditions': underlyingConditions,
      'allergies': allergies,
      'isVegan': isVegan,
      'isReligious': isReligious,
      'religionDetails': religionDetails,
      'mealPurpose': mealPurpose,
      'mealBudget': mealBudget,
      'favoriteFoods': favoriteFoods,
      'dislikedFoods': dislikedFoods,
      'preferredCookingMethods': preferredCookingMethods,
      'availableCookingTools': availableCookingTools,
      'preferredCookingTime': preferredCookingTime,
      // 선호/기피 식품 분해 필드
      'preferredIngredients': preferredIngredients,
      'preferredSeasonings': preferredSeasonings,
      'preferredCookingStyles': preferredCookingStyles,
      'dislikedIngredients': dislikedIngredients,
      'dislikedSeasonings': dislikedSeasonings,
      'dislikedCookingStyles': dislikedCookingStyles,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String? ?? "보통 (주 3-5회 중간 강도 운동)",
      underlyingConditions: List<String>.from(json['underlyingConditions'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      isVegan: json['isVegan'] as bool? ?? false,
      isReligious: json['isReligious'] as bool? ?? false,
      religionDetails: json['religionDetails'] as String?,
      mealPurpose: List<String>.from(json['mealPurpose'] ?? []),
      mealBudget: (json['mealBudget'] as num?)?.toDouble(),
      favoriteFoods: List<String>.from(json['favoriteFoods'] ?? []),
      dislikedFoods: List<String>.from(json['dislikedFoods'] ?? []),
      preferredCookingMethods: List<String>.from(json['preferredCookingMethods'] ?? []),
      availableCookingTools: List<String>.from(json['availableCookingTools'] ?? []),
      preferredCookingTime: json['preferredCookingTime'] as int?,
      // 선호/기피 식품 분해 필드
      preferredIngredients: List<String>.from(json['preferredIngredients'] ?? []),
      preferredSeasonings: List<String>.from(json['preferredSeasonings'] ?? []),
      preferredCookingStyles: List<String>.from(json['preferredCookingStyles'] ?? []),
      dislikedIngredients: List<String>.from(json['dislikedIngredients'] ?? []),
      dislikedSeasonings: List<String>.from(json['dislikedSeasonings'] ?? []),
      dislikedCookingStyles: List<String>.from(json['dislikedCookingStyles'] ?? []),
    );
  }
  
  // 복제 메서드 (수정된 복사본 생성)
  UserData copyWith({
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    List<String>? underlyingConditions,
    List<String>? allergies,
    bool? isVegan,
    bool? isReligious,
    String? religionDetails,
    List<String>? mealPurpose,
    double? mealBudget,
    List<String>? favoriteFoods,
    List<String>? dislikedFoods,
    List<String>? preferredCookingMethods,
    List<String>? availableCookingTools,
    int? preferredCookingTime,
    List<String>? preferredIngredients,
    List<String>? preferredSeasonings,
    List<String>? preferredCookingStyles,
    List<String>? dislikedIngredients,
    List<String>? dislikedSeasonings,
    List<String>? dislikedCookingStyles,
  }) {
    return UserData(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      underlyingConditions: underlyingConditions ?? this.underlyingConditions,
      allergies: allergies ?? this.allergies,
      isVegan: isVegan ?? this.isVegan,
      isReligious: isReligious ?? this.isReligious,
      religionDetails: religionDetails ?? this.religionDetails,
      mealPurpose: mealPurpose ?? this.mealPurpose,
      mealBudget: mealBudget ?? this.mealBudget,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      preferredCookingMethods: preferredCookingMethods ?? this.preferredCookingMethods,
      availableCookingTools: availableCookingTools ?? this.availableCookingTools,
      preferredCookingTime: preferredCookingTime ?? this.preferredCookingTime,
      preferredIngredients: preferredIngredients ?? this.preferredIngredients,
      preferredSeasonings: preferredSeasonings ?? this.preferredSeasonings,
      preferredCookingStyles: preferredCookingStyles ?? this.preferredCookingStyles,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      dislikedSeasonings: dislikedSeasonings ?? this.dislikedSeasonings,
      dislikedCookingStyles: dislikedCookingStyles ?? this.dislikedCookingStyles,
    );
  }
}