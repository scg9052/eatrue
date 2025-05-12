// services/meal_base_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_base.dart';
import '../models/meal.dart';

class MealBaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  
  // 식단 베이스 저장
  Future<void> saveMealBase(MealBase mealBase) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      // 저장할 데이터 준비
      final Map<String, dynamic> dataToSave = mealBase.toJson();
      dataToSave['userId'] = currentUserId; // 사용자 ID 추가
      
      await _firestore
          .collection('mealBase')
          .doc(mealBase.id)
          .set(dataToSave);
      
      print('식단 베이스에 저장되었습니다: ${mealBase.name}');
    } catch (e) {
      print('식단 베이스 저장 중 오류: $e');
      throw Exception('식단 베이스 저장에 실패했습니다: $e');
    }
  }
  
  // 모든 식단 베이스 불러오기
  Future<List<MealBase>> getAllMealBases() async {
    if (currentUserId == null) {
      return [];
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mealBase')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      return snapshot.docs
          .map((doc) => MealBase.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('식단 베이스 로드 중 오류: $e');
      
      // 권한 오류인 경우 임시 데이터 반환
      if (e.toString().contains('permission-denied')) {
        print('Firebase 권한 오류로 임시 데이터 반환');
        return _getDefaultMealBases();
      }
      
      return [];
    }
  }
  
  // 임시 식단 베이스 데이터 생성
  List<MealBase> _getDefaultMealBases() {
    final List<MealBase> defaults = [];
    final categories = ['아침', '점심', '저녁', '간식'];
    
    // 각 카테고리별 기본 메뉴 2개씩 생성
    for (var category in categories) {
      for (var i = 0; i < 2; i++) {
        defaults.add(
          MealBase(
            id: 'default_${category}_$i',
            name: '기본 ${category} 메뉴 ${i+1}',
            description: '로컬에서 생성된 기본 ${category} 메뉴입니다.',
            category: category,
            calories: '약 ${300 + i * 50}kcal',
            tags: ['기본', category, '로컬'],
            createdAt: DateTime.now().subtract(Duration(days: i)),
            lastUsedAt: i % 2 == 0 ? DateTime.now().subtract(Duration(hours: i * 6)) : null,
            usageCount: i,
          )
        );
      }
    }
    
    return defaults;
  }
  
  // 카테고리별 식단 베이스 불러오기
  Future<List<MealBase>> getMealBasesByCategory(String category) async {
    if (currentUserId == null) {
      return [];
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mealBase')
          .where('userId', isEqualTo: currentUserId)
          .where('category', isEqualTo: category)
          .get();
      
      return snapshot.docs
          .map((doc) => MealBase.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('카테고리별 식단 베이스 로드 중 오류: $e');
      
      // 권한 오류인 경우 임시 데이터 반환
      if (e.toString().contains('permission-denied')) {
        print('Firebase 권한 오류로 임시 데이터 반환');
        return _getDefaultMealBases().where((base) => base.category == category).toList();
      }
      
      return [];
    }
  }
  
  // 식단 베이스 삭제
  Future<void> deleteMealBase(String mealBaseId) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .delete();
      
      print('식단 베이스에서 삭제되었습니다 (ID: $mealBaseId)');
    } catch (e) {
      print('식단 베이스 삭제 중 오류: $e');
      throw Exception('식단 베이스 삭제에 실패했습니다: $e');
    }
  }
  
  // 식단 베이스 평가 저장
  Future<void> rateMealBase(String mealBaseId, double rating) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .update({'rating': rating});
      
      print('식단 베이스 평가가 저장되었습니다 (ID: $mealBaseId, 평점: $rating)');
    } catch (e) {
      print('식단 베이스 평가 저장 중 오류: $e');
      throw Exception('식단 베이스 평가 저장에 실패했습니다: $e');
    }
  }
  
  // 식단 베이스 기각 사유 추가
  Future<void> addRejectionReason(String mealBaseId, RejectionReason reason) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      // 현재 문서 가져오기
      final DocumentSnapshot doc = await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .get();
      
      if (!doc.exists) {
        throw Exception('존재하지 않는 식단 베이스입니다');
      }
      
      final mealBaseData = doc.data() as Map<String, dynamic>;
      List<dynamic> reasons = mealBaseData['rejectionReasons'] ?? [];
      reasons.add(reason.toJson());
      
      await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .update({'rejectionReasons': reasons});
      
      print('식단 베이스 기각 사유가 추가되었습니다 (ID: $mealBaseId)');
    } catch (e) {
      print('식단 베이스 기각 사유 추가 중 오류: $e');
      throw Exception('식단 베이스 기각 사유 추가에 실패했습니다: $e');
    }
  }
  
  // 식단 베이스 사용 횟수 증가
  Future<void> incrementUsageCount(String mealBaseId) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      // 트랜잭션을 사용하여 동시성 문제 해결
      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot snapshot = await transaction.get(
          _firestore.collection('mealBase').doc(mealBaseId)
        );
        
        if (!snapshot.exists) {
          throw Exception('존재하지 않는 식단 베이스입니다');
        }
        
        final mealBaseData = snapshot.data() as Map<String, dynamic>;
        final int currentCount = mealBaseData['usageCount'] ?? 0;
        
        transaction.update(
          _firestore.collection('mealBase').doc(mealBaseId),
          {
            'usageCount': currentCount + 1,
            'lastUsedAt': DateTime.now().toIso8601String(),
          }
        );
      });
      
      print('식단 베이스 사용 횟수가 증가되었습니다 (ID: $mealBaseId)');
    } catch (e) {
      print('식단 베이스 사용 횟수 증가 중 오류: $e');
      // 중요한 작업이 아니므로 사용자 경험을 방해하지 않기 위해 예외 발생하지 않음
    }
  }
  
  // 식단 베이스 태그 추가
  Future<void> addTagToMealBase(String mealBaseId, String tag) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .get();
      
      if (!doc.exists) {
        throw Exception('존재하지 않는 식단 베이스입니다');
      }
      
      final mealBaseData = doc.data() as Map<String, dynamic>;
      List<dynamic> tags = mealBaseData['tags'] ?? [];
      
      if (!tags.contains(tag)) {
        tags.add(tag);
        await _firestore
            .collection('mealBase')
            .doc(mealBaseId)
            .update({'tags': tags});
        
        print('식단 베이스에 태그가 추가되었습니다 (ID: $mealBaseId, 태그: $tag)');
      }
    } catch (e) {
      print('식단 베이스 태그 추가 중 오류: $e');
      throw Exception('식단 베이스 태그 추가에 실패했습니다: $e');
    }
  }
  
  // 식단 베이스 태그 제거
  Future<void> removeTagFromMealBase(String mealBaseId, String tag) async {
    if (currentUserId == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .get();
      
      if (!doc.exists) {
        throw Exception('존재하지 않는 식단 베이스입니다');
      }
      
      final mealBaseData = doc.data() as Map<String, dynamic>;
      List<dynamic> tags = mealBaseData['tags'] ?? [];
      
      tags.remove(tag);
      await _firestore
          .collection('mealBase')
          .doc(mealBaseId)
          .update({'tags': tags});
      
      print('식단 베이스에서 태그가 제거되었습니다 (ID: $mealBaseId, 태그: $tag)');
    } catch (e) {
      print('식단 베이스 태그 제거 중 오류: $e');
      throw Exception('식단 베이스 태그 제거에 실패했습니다: $e');
    }
  }
  
  // 태그별 식단 베이스 검색
  Future<List<MealBase>> searchMealBasesByTag(String tag) async {
    if (currentUserId == null) {
      return [];
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mealBase')
          .where('userId', isEqualTo: currentUserId)
          .where('tags', arrayContains: tag)
          .get();
      
      return snapshot.docs
          .map((doc) => MealBase.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('태그별 식단 베이스 검색 중 오류: $e');
      return [];
    }
  }
  
  // 인기 태그 목록 가져오기
  Future<Map<String, int>> getPopularTags({int limit = 10}) async {
    if (currentUserId == null) {
      return {};
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mealBase')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      Map<String, int> tagCount = {};
      
      for (var doc in snapshot.docs) {
        final mealBaseData = doc.data() as Map<String, dynamic>;
        final List<dynamic> tags = mealBaseData['tags'] ?? [];
        
        for (var tag in tags) {
          if (tag is String) {
            tagCount[tag] = (tagCount[tag] ?? 0) + 1;
          }
        }
      }
      
      // 태그를 인기도(사용 횟수)에 따라 정렬
      final sortedTags = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // 상위 limit개 태그만 반환
      return Map.fromEntries(sortedTags.take(limit));
    } catch (e) {
      print('인기 태그 목록 가져오기 중 오류: $e');
      return {};
    }
  }
  
  // 텍스트 기반 식단 베이스 검색
  Future<List<MealBase>> searchMealBasesByText(String query) async {
    if (currentUserId == null || query.trim().isEmpty) {
      return [];
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mealBase')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      // Firestore에서는 다중 필드 검색이 제한적이므로 클라이언트에서 필터링
      final results = snapshot.docs
          .map((doc) => MealBase.fromJson(doc.data() as Map<String, dynamic>))
          .where((mealBase) {
            final searchableText = '${mealBase.name} ${mealBase.description}'.toLowerCase();
            return searchableText.contains(query.toLowerCase());
          })
          .toList();
      
      return results;
    } catch (e) {
      print('텍스트 기반 식단 베이스 검색 중 오류: $e');
      return [];
    }
  }
} 