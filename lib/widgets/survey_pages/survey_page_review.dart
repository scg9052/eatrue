import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPageReview extends StatelessWidget {
  const SurveyPageReview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<SurveyDataProvider>(context).userData;
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '입력 정보 검토',
            style: theme.textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            '입력하신 정보를 최종 확인해주세요. 수정이 필요한 부분은 이전 단계로 돌아가 수정할 수 있습니다.',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          SizedBox(height: 24),
          
          // 기본 정보
          _buildSectionCard(
            context: context,
            title: '기본 정보',
            icon: Icons.person_outline,
            items: [
              _buildInfoItem('나이', userData.age != null ? '${userData.age}세' : '정보 없음'),
              _buildInfoItem('성별', userData.gender ?? '정보 없음'),
              _buildInfoItem('키', userData.height != null ? '${userData.height}cm' : '정보 없음'),
              _buildInfoItem('체중', userData.weight != null ? '${userData.weight}kg' : '정보 없음'),
              _buildInfoItem('활동 수준', userData.activityLevel ?? '정보 없음'),
            ],
          ),
          
          // 건강 상태
          _buildSectionCard(
            context: context,
            title: '건강 상태',
            icon: Icons.health_and_safety_outlined,
            items: [
              _buildInfoItem('기저질환', userData.underlyingConditions.isEmpty ? '없음' : userData.underlyingConditions.join(', ')),
              _buildInfoItem('알레르기', userData.allergies.isEmpty ? '없음' : userData.allergies.join(', ')),
            ],
          ),
          
          // 식습관
          _buildSectionCard(
            context: context,
            title: '식습관',
            icon: Icons.restaurant_outlined,
            items: [
              _buildInfoItem('채식주의자', userData.isVegan ? '예' : '아니오'),
              _buildInfoItem('종교적 제한', userData.isReligious ? (userData.religionDetails ?? '있음') : '없음'),
              _buildInfoItem('식단 목적', userData.mealPurpose.isEmpty ? '정보 없음' : userData.mealPurpose.join(', ')),
              _buildInfoItem('식단 예산', userData.mealBudget != null ? _getBudgetText(userData.mealBudget!) : '정보 없음'),
              _buildInfoItem('선호 식품', userData.favoriteFoods.isEmpty ? '없음' : userData.favoriteFoods.join(', ')),
              _buildInfoItem('기피 식품', userData.dislikedFoods.isEmpty ? '없음' : userData.dislikedFoods.join(', ')),
              _buildInfoItem('선호 조리법', userData.preferredCookingMethods.isEmpty ? '없음' : userData.preferredCookingMethods.join(', ')),
            ],
          ),
          
          // 조리 환경
          _buildSectionCard(
            context: context,
            title: '조리 환경',
            icon: Icons.kitchen_outlined,
            items: [
              _buildInfoItem('가용 조리도구', userData.availableCookingTools.isEmpty ? '없음' : userData.availableCookingTools.join(', ')),
              _buildInfoItem('선호 조리시간', userData.preferredCookingTime != null ? '${userData.preferredCookingTime}분' : '정보 없음'),
            ],
          ),
          
          // 주의 사항
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[800],
                        ),
                        SizedBox(width: 8),
                        Text(
                          '주의 사항',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '입력하신 정보는 맞춤형 식단을 추천하는데 사용됩니다. 정보는 언제든지 프로필 메뉴에서 수정할 수 있습니다.',
                      style: TextStyle(color: Colors.amber[900]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  title, 
                  style: theme.textTheme.titleLarge
                ),
              ],
            ),
            Divider(color: theme.dividerColor),
            SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getBudgetText(double budget) {
    if (budget < 3) {
      return '저비용 (1~2만원)';
    } else if (budget < 6) {
      return '중간 (3~5만원)';
    } else {
      return '고비용 (6만원 이상)';
    }
  }
} 