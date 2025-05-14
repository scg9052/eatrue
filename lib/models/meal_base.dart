import 'package:cloud_firestore/cloud_firestore.dart';
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

/// 식단 베이스 모델
/// 
/// 사용자가 좋아하거나 자주 먹는 음식을 모아둔 컬렉션으로,
/// 이를 기반으로 식단을 빠르게 추가할 수 있습니다.
class MealBase {
  final String id;
  final String userId;
  final String name;
  final String category; // 식단 카테고리 (아침, 점심, 저녁, 간식)
  final String? description;
  final String? recipeId;
  final String? imageUrl;
  final DateTime? createdAt;
  double? rating;
  List<RejectionReason>? rejectionReasons;
  List<String>? tags;
  DateTime? lastUsedAt;
  int usageCount;
  Map<String, dynamic>? recipeJson; // 레시피 JSON 추가
  final String? calories; // 추가된 칼로리 정보 필드

  // Firestore 데이터 변환
  MealBase({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.description,
    this.recipeId,
    this.imageUrl,
    this.createdAt,
    this.rating,
    this.rejectionReasons,
    this.tags,
    this.lastUsedAt,
    this.usageCount = 0,
    this.recipeJson,
    this.calories,
  });
  
  // JSON에서 MealBase 객체 생성 (API 호환용)
  factory MealBase.fromJson(Map<String, dynamic> json) {
    List<RejectionReason>? rejectionReasons;
    if (json['rejectionReasons'] != null) {
      rejectionReasons = (json['rejectionReasons'] as List)
          .map((item) => RejectionReason.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    
    return MealBase(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      recipeId: json['recipeId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'].toString())) 
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      rejectionReasons: rejectionReasons,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      lastUsedAt: json['lastUsedAt'] != null 
          ? (json['lastUsedAt'] is Timestamp 
              ? (json['lastUsedAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastUsedAt'].toString()))
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
      recipeJson: json['recipeJson'] as Map<String, dynamic>?,
      calories: json['calories'] as String?,
    );
  }
  
  // MealBase 객체를 JSON으로 변환 (API 호환용)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'description': description,
      'recipeId': recipeId,
      'imageUrl': imageUrl,
      'usageCount': usageCount,
      'calories': calories,
    };
    
    if (createdAt != null) {
      data['createdAt'] = createdAt!.toIso8601String();
    }
    
    if (rating != null) {
      data['rating'] = rating;
    }
    
    if (rejectionReasons != null) {
      data['rejectionReasons'] = rejectionReasons!.map((r) => r.toJson()).toList();
    }
    
    if (tags != null) {
      data['tags'] = tags;
    }
    
    if (lastUsedAt != null) {
      data['lastUsedAt'] = lastUsedAt!.toIso8601String();
    }
    
    if (recipeJson != null) {
      data['recipeJson'] = recipeJson;
    }
    
    return data;
  }
  
  // Firestore 컬렉션에서 문서를 MealBase 객체로 변환
  factory MealBase.fromFirestore(Map<String, dynamic> data, String id) {
    return MealBase(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'],
      recipeId: data['recipeId'],
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      lastUsedAt: data['lastUsedAt'] != null 
          ? (data['lastUsedAt'] as Timestamp).toDate() 
          : null,
      usageCount: data['usageCount'] as int? ?? 0,
      recipeJson: data['recipeJson'] as Map<String, dynamic>?,
      calories: data['calories'] as String?,
    );
  }
  
  // MealBase 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'description': description,
      'recipeId': recipeId,
      'imageUrl': imageUrl,
      'createdAt': createdAt ?? DateTime.now(),
      'rating': rating,
      'tags': tags,
      'lastUsedAt': lastUsedAt,
      'usageCount': usageCount,
      'recipeJson': recipeJson,
      'calories': calories,
    };
  }
  
  // 식단 베이스로부터 새로운 식단 생성
  Meal toMeal(DateTime date) {
    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description ?? '',
      calories: calories != null && calories!.isNotEmpty ? calories! : '칼로리 정보 없음',
      date: date,
      category: category,
      recipeJson: recipeJson,
    );
  }
  
  // 식단 베이스 복사본 생성 (특정 속성 변경 가능)
  MealBase copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? description,
    String? recipeId,
    String? imageUrl,
    DateTime? createdAt,
    double? rating,
    List<RejectionReason>? rejectionReasons,
    List<String>? tags,
    DateTime? lastUsedAt,
    int? usageCount,
    Map<String, dynamic>? recipeJson,
    String? calories,
  }) {
    return MealBase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      recipeId: recipeId ?? this.recipeId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      rejectionReasons: rejectionReasons ?? this.rejectionReasons,
      tags: tags ?? this.tags,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      recipeJson: recipeJson ?? this.recipeJson,
      calories: calories ?? this.calories,
    );
  }
} 