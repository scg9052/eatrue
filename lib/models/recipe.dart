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
    print('Recipe.fromJson 시작: ${json['title'] ?? json['dish_name']}');
    
    // 조리 시간 (cookingTimeMinutes) 파싱
    int? cookingTime;
    if (json['cookingTimeMinutes'] != null) {
      cookingTime = json['cookingTimeMinutes'] is int 
          ? json['cookingTimeMinutes'] 
          : int.tryParse(json['cookingTimeMinutes'].toString());
    } else if (json['cooking_time_minutes'] != null) {
      cookingTime = json['cooking_time_minutes'] is int 
          ? json['cooking_time_minutes'] 
          : int.tryParse(json['cooking_time_minutes'].toString());
    }
    
    // 조리 지침 파싱
    List<String> instructions = [];
    if (json['cooking_instructions'] != null) {
      if (json['cooking_instructions'] is List) {
        instructions = (json['cooking_instructions'] as List)
            .map((item) => item.toString())
            .toList();
      } 
    } else if (json['instructions'] != null) {
      if (json['instructions'] is List) {
        instructions = (json['instructions'] as List)
            .map((item) => item.toString())
            .toList();
      }
    } else if (json['steps'] != null) {
      if (json['steps'] is List) {
        instructions = (json['steps'] as List)
            .map((item) => item.toString())
            .toList();
      }
    }
    
    // 대체 ID 생성
    String id = json['id'] as String? ?? 
                json['recipe_id'] as String? ?? 
                json['dish_name'] as String? ?? 
                DateTime.now().millisecondsSinceEpoch.toString();
    
    // 영양 정보 파싱 개선
    Map<String, dynamic>? nutritionalInfo;
    if (json['nutritional_information'] != null) {
      nutritionalInfo = json['nutritional_information'] is Map ? 
        Map<String, dynamic>.from(json['nutritional_information']) : null;
    } else if (json['nutrition'] != null) {
      nutritionalInfo = json['nutrition'] is Map ? 
        Map<String, dynamic>.from(json['nutrition']) : null;
    } else if (json['nutritionalInformation'] != null) {
      nutritionalInfo = json['nutritionalInformation'] is Map ? 
        Map<String, dynamic>.from(json['nutritionalInformation']) : null;
    }
    
    // 칼로리가 다른 형태로 제공된 경우 영양 정보에 통합
    if (nutritionalInfo != null && json['calories'] != null && 
        !nutritionalInfo.containsKey('calories') && !nutritionalInfo.containsKey('calorie')) {
      nutritionalInfo['calories'] = json['calories'];
    }
    
    // 재료 및 양념 처리 함수 개선
    Map<String, String>? processIngredients(dynamic raw) {
      if (raw == null) return null;
      
      try {
        if (raw is Map) {
          // Map 형태로 직접 받은 경우
          return Map<String, String>.from(
            raw.map((k, v) => MapEntry(k.toString(), v.toString()))
          );
        } else if (raw is List) {
          final result = <String, String>{};
          for (final item in raw) {
            if (item is Map) {
              if (item.containsKey('name') && item.containsKey('quantity')) {
                // {name: 양파, quantity: 1개} 형태
                result[item['name'].toString()] = item['quantity'].toString();
              } else if (item.length == 1) {
                // {양파: 1개} 형태
                final entry = item.entries.first;
                result[entry.key.toString()] = entry.value.toString();
              } else {
                // 다른 방식으로 정보가 표현된 경우
                item.forEach((k, v) {
                  result[k.toString()] = v.toString();
                });
              }
            } else if (item is String) {
              // 문자열만 있는 경우 수량 미정으로 처리
              result[item] = '적당량';
            }
          }
          return result.isEmpty ? null : result;
        }
      } catch (e) {
        print('재료 정보 파싱 중 오류: $e');
      }
      return null;
    }
    
    // 재료 파싱 - 다양한 필드명 처리
    Map<String, String>? ingredientsMap = processIngredients(json['ingredients']);
    Map<String, String>? seasoningsMap = processIngredients(json['seasonings']);
    
    // 재료가 다른 필드명으로 제공된 경우 확인
    if (ingredientsMap == null) {
      if (json['main_ingredients'] != null) {
        ingredientsMap = processIngredients(json['main_ingredients']);
      } else if (json['mainIngredients'] != null) {
        ingredientsMap = processIngredients(json['mainIngredients']);
      }
    }
    
    // 양념이 다른 필드명으로 제공된 경우 확인
    if (seasoningsMap == null) {
      if (json['sauce_ingredients'] != null) {
        seasoningsMap = processIngredients(json['sauce_ingredients']);
      } else if (json['sauceIngredients'] != null) {
        seasoningsMap = processIngredients(json['sauceIngredients']);
      } else if (json['condiments'] != null) {
        seasoningsMap = processIngredients(json['condiments']);
      }
    }
    
    // 조리 지침이 빈 경우 기본 지침 제공
    if (instructions.isEmpty) {
      instructions = [
        "1. 재료를 준비합니다.",
        "2. 재료를 손질합니다.",
        "3. 조리합니다.",
        "4. 완성된 요리를 그릇에 담아 제공합니다."
      ];
    }
    
    // 재료 정보가 없거나 부족한 경우 메뉴 이름에서 재료 추론
    if (ingredientsMap == null || ingredientsMap.isEmpty) {
      String dishName = json['dish_name']?.toString() ?? json['title']?.toString() ?? '';
      if (dishName.isNotEmpty) {
        Map<String, String> inferredIngredients = {};
        // 요리 이름에서 주요 재료 추론
        List<String> words = dishName.split(' ');
        for (var word in words) {
          if (word.length > 1) {
            inferredIngredients[word] = '적당량';
          }
        }
        
        if (inferredIngredients.isNotEmpty) {
          ingredientsMap = inferredIngredients;
        }
      }
    }
    
    // 최종 레시피 생성
    final recipe = Recipe(
      id: id,
      mealId: json['mealId'] as String? ?? '',
      title: json['dish_name'] as String? ?? 
             json['title'] as String? ?? 
             json['name'] as String? ?? 
             '제목 없음',
      costInformation: json['cost_information'] as String?,
      nutritionalInformation: nutritionalInfo,
      ingredients: ingredientsMap,
      seasonings: seasoningsMap,
      cookingInstructions: instructions,
      cookingTimeMinutes: cookingTime,
      difficulty: json['difficulty'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
    
    print('Recipe.fromJson 완료: ${recipe.title}');
    print('영양 정보: ${recipe.nutritionalInformation?.keys.join(', ') ?? "없음"}');
    print('재료 수: ${recipe.ingredients?.length ?? 0}');
    print('조리 단계: ${recipe.cookingInstructions.length}');
    
    return recipe;
  }
}