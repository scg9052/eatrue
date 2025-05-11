import 'package:firebase_core/firebase_core.dart';
import 'meal.dart';

class RejectionReason {
  final String id;
  final String reason; // 가격, 복잡성, 재료, 맛 등
  final String details;
  final DateTime timestamp;

  RejectionReason({
    required this.id,
    required this.reason,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RejectionReason.fromJson(Map<String, dynamic> json) {
    return RejectionReason(
      id: json['id'] as String,
      reason: json['reason'] as String,
      details: json['details'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class MealBase {
  final String id;
  final String name;
  final String description;
  final String category; // 아침, 점심, 저녁, 간식
  final String? calories;
  final Map<String, dynamic>? recipeJson;
  double? rating;
  List<RejectionReason>? rejectionReasons;
  List<String>? tags;
  final DateTime createdAt;
  DateTime? lastUsedAt;
  int usageCount;

  MealBase({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.calories,
    this.recipeJson,
    this.rating,
    this.rejectionReasons,
    this.tags,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'calories': calories,
      if (recipeJson != null) 'recipeJson': recipeJson,
      if (rating != null) 'rating': rating,
      if (rejectionReasons != null) 
        'rejectionReasons': rejectionReasons!.map((reason) => reason.toJson()).toList(),
      if (tags != null) 'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  factory MealBase.fromJson(Map<String, dynamic> json) {
    return MealBase(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      calories: json['calories'] as String?,
      recipeJson: json['recipeJson'] as Map<String, dynamic>?,
      rating: json['rating'] as double?,
      rejectionReasons: json['rejectionReasons'] != null
          ? (json['rejectionReasons'] as List)
              .map((reason) => RejectionReason.fromJson(reason as Map<String, dynamic>))
              .toList()
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt'] as String) : null,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }

  // Meal에서 MealBase로 변환하는 팩토리 메서드
  factory MealBase.fromMeal(Meal meal, {List<String>? tags}) {
    return MealBase(
      id: meal.id,
      name: meal.name,
      description: meal.description,
      category: meal.category,
      calories: meal.calories,
      recipeJson: meal.recipeJson,
      tags: tags,
      createdAt: DateTime.now(),
      usageCount: 1,
    );
  }

  // MealBase를 Meal로 변환하는 메서드
  Meal toMeal(DateTime date) {
    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 새 ID 생성
      name: name,
      description: description,
      calories: calories,
      date: date,
      category: category,
      recipeJson: recipeJson,
    );
  }
  
  // 베이스 메뉴 업데이트를 위한 복제 메서드
  MealBase copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? calories,
    Map<String, dynamic>? recipeJson,
    double? rating,
    List<RejectionReason>? rejectionReasons,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return MealBase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      recipeJson: recipeJson ?? this.recipeJson,
      rating: rating ?? this.rating,
      rejectionReasons: rejectionReasons ?? this.rejectionReasons,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }
} 