// models/ingredient.dart
// Recipe 모델에서 ingredients와 seasonings가 Map<String, String>으로 변경됨에 따라,
// 이 Ingredient 클래스는 현재 Recipe 모델에서 직접 사용되지 않을 수 있습니다.
// 만약 다른 곳에서 사용하거나, List<Ingredient> 형태가 여전히 필요하다면 유지합니다.
// API 스펙에 따라 LLM이 재료/양념을 객체 리스트로 반환한다면 이 모델이 다시 필요해집니다.
// 현재는 Recipe.fromJson에서 Map<String, String>으로 처리하고 있습니다.
class Ingredient {
  final String name;
  final String quantity;

  Ingredient({
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String? ?? '이름 없음',
      quantity: json['quantity'] as String? ?? '양 정보 없음',
    );
  }
}