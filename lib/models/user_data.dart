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
  // UserData 모델에 추가할 수 있는 필드 (플로우차트 및 API 스펙 기반)
  // List<String> dislikedCookingMethods;
  // List<String> favoriteSeasonings;
  // List<String> dislikedSeasonings;


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
    // this.dislikedCookingMethods = const [],
    // this.favoriteSeasonings = const [],
    // this.dislikedSeasonings = const [],
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
      // 'dislikedCookingMethods': dislikedCookingMethods,
      // 'favoriteSeasonings': favoriteSeasonings,
      // 'dislikedSeasonings': dislikedSeasonings,
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
      // dislikedCookingMethods: List<String>.from(json['dislikedCookingMethods'] ?? []),
      // favoriteSeasonings: List<String>.from(json['favoriteSeasonings'] ?? []),
      // dislikedSeasonings: List<String>.from(json['dislikedSeasonings'] ?? []),
    );
  }
}