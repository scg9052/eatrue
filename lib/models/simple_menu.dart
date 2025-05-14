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
    // 가능한 필드명 변형 처리
    final possibleDishNameKeys = ['dish_name', 'dishName', 'name', 'title', 'menu_name', 'menuName'];
    final possibleCategoryKeys = ['category', 'meal_category', 'menuCategory', 'type'];
    final possibleDescriptionKeys = ['description', 'desc', 'summary', 'menuDescription'];
    final possibleMealTypeKeys = ['meal_type', 'mealType', 'type', 'time', 'when'];
    final possibleCaloriesKeys = ['calories', 'calorie', 'energy', 'kcal', 'calorieInfo'];
    final possibleIngredientsKeys = ['ingredients', 'ingredient', 'ingredient_list', 'ingredientList', 'main_ingredients'];
    final possibleNutritionKeys = ['nutrition', 'nutritional_information', 'nutritionalInfo', 'nutrients', 'approximate_nutrients', 'nutritionInfo'];
    
    // 다양한 키에서 값을 추출하는 헬퍼 함수
    T? getValueFromKeys<T>(List<String> keys, T? defaultValue) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key] as T;
        }
      }
      return defaultValue;
    }
    
    // 재료 목록 추출 함수
    List<String>? extractIngredients() {
      // 가능한 키 확인
      for (final key in possibleIngredientsKeys) {
        if (json.containsKey(key) && json[key] != null) {
          final dynamic ingredients = json[key];
          
          // 재료가 리스트 형태인 경우
          if (ingredients is List) {
            // 리스트의 각 항목이 문자열인지 확인
            try {
              return ingredients.map((item) {
                if (item is String) {
                  return item;
                } else if (item is Map) {
                  // 객체 형태인 경우 "name" 필드 또는 첫 번째 키 사용
                  return item['name']?.toString() ?? 
                         item.values.first?.toString() ?? 
                         item.toString();
                } else {
                  return item.toString();
                }
              }).toList().cast<String>();
            } catch (e) {
              print("재료 변환 중 오류: $e");
              return null;
            }
          }
          
          // 재료가 문자열인 경우 (콤마로 구분된)
          else if (ingredients is String) {
            return ingredients.split(',').map((e) => e.trim()).toList();
          }
          
          // 재료가 맵(객체) 형태인 경우
          else if (ingredients is Map) {
            return ingredients.keys.map((e) => e.toString()).toList();
          }
        }
      }
      return null;
    }
    
    // 영양 정보 추출 함수
    Map<String, dynamic>? extractNutrition() {
      for (final key in possibleNutritionKeys) {
        if (json.containsKey(key) && json[key] != null) {
          final dynamic nutrition = json[key];
          
          if (nutrition is Map) {
            return Map<String, dynamic>.from(nutrition);
          } else if (nutrition is String) {
            // 문자열로 된 영양 정보를 파싱 시도
            try {
              final nutritionMap = <String, dynamic>{};
              nutritionMap['rawText'] = nutrition;
              return nutritionMap;
            } catch (e) {
              print("영양 정보 변환 중 오류: $e");
              return null;
            }
          }
        }
      }
      return null;
    }
    
    // 칼로리 정보 추출 - 영양 정보에서도 확인
    String? extractCalories() {
      // 직접 칼로리 필드 확인
      final caloriesValue = getValueFromKeys<String>(possibleCaloriesKeys, null);
      if (caloriesValue != null) {
        return caloriesValue;
      }
      
      // 영양 정보에서 칼로리 확인
      final nutrition = extractNutrition();
      if (nutrition != null) {
        for (final key in possibleCaloriesKeys) {
          if (nutrition.containsKey(key) && nutrition[key] != null) {
            return nutrition[key].toString();
          }
        }
      }
      
      return null;
    }
    
    // 디버깅 로그
    print("SimpleMenu.fromJson 변환 시작: ${json['dish_name'] ?? json['dishName'] ?? '이름 없음'}");
    
    // 안전한 변환 시도
    try {
      final result = SimpleMenu(
        dishName: getValueFromKeys<String>(possibleDishNameKeys, '') ?? '',
        category: getValueFromKeys<String>(possibleCategoryKeys, '') ?? '',
        description: getValueFromKeys<String>(possibleDescriptionKeys, '') ?? '',
        mealType: getValueFromKeys<String>(possibleMealTypeKeys, '') ?? '',
        calories: extractCalories(),
        ingredients: extractIngredients(),
        nutritionInfo: extractNutrition(),
      );
      
      print("SimpleMenu.fromJson 변환 완료: ${result.dishName}");
      return result;
    } catch (e) {
      print("SimpleMenu.fromJson 변환 오류: $e, JSON: $json");
      // 오류 발생 시 기본값으로 생성
      return SimpleMenu(
        dishName: json['dish_name']?.toString() ?? '메뉴 이름 변환 오류',
        category: json['category']?.toString() ?? '',
        description: json['description']?.toString() ?? '설명 없음',
        mealType: json['meal_type']?.toString() ?? '',
      );
    }
  }
} 