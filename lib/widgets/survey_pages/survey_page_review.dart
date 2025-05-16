import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../l10n/app_localizations.dart';

class SurveyPageReview extends StatelessWidget {
  const SurveyPageReview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<SurveyDataProvider>(context).userData;
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.reviewTitle,
            style: theme.textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            localization.reviewDescription,
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          SizedBox(height: 24),
          
          // 기본 정보
          _buildSectionCard(
            context: context,
            title: localization.personalInfoTitle,
            icon: Icons.person_outline,
            items: [
              _buildInfoItem(localization.ageLabel, userData.age != null ? '${userData.age}${localization.isKorean() ? "세" : ""}' : localization.none),
              _buildInfoItem(localization.genderLabel, userData.gender ?? localization.none),
              _buildInfoItem(localization.heightLabel, userData.height != null ? '${userData.height}cm' : localization.none),
              _buildInfoItem(localization.weightLabel, userData.weight != null ? '${userData.weight}kg' : localization.none),
              _buildInfoItem(localization.activityLevelLabel, userData.activityLevel ?? localization.none),
            ],
          ),
          
          // 건강 상태
          _buildSectionCard(
            context: context,
            title: localization.healthInfoTitle,
            icon: Icons.favorite_outline,
            items: [
              _buildInfoItem(
                localization.allergiesLabel,
                userData.allergies.isEmpty
                    ? localization.none
                    : userData.allergies.join(', '),
              ),
              _buildInfoItem(
                localization.isKorean() ? '기저질환' : 'Underlying Conditions',
                userData.underlyingConditions.isEmpty
                    ? localization.none
                    : userData.underlyingConditions.join(', '),
              ),
            ],
          ),
          
          // 식습관
          _buildSectionCard(
            context: context,
            title: localization.foodPreferenceTitle,
            icon: Icons.restaurant_outlined,
            items: [
              _buildInfoItem(
                localization.isVeganLabel,
                userData.isVegan ? localization.yes : localization.no,
              ),
              _buildInfoItem(
                localization.isReligiousLabel,
                userData.isReligious
                    ? (userData.religionDetails?.isNotEmpty == true
                        ? userData.religionDetails!
                        : localization.yes)
                    : localization.no,
              ),
              _buildInfoItem(
                localization.favoriteFoodsLabel,
                userData.favoriteFoods.isEmpty
                    ? localization.none
                    : userData.favoriteFoods.join(', '),
              ),
              _buildInfoItem(
                localization.dislikedFoodsLabel,
                userData.dislikedFoods.isEmpty
                    ? localization.none
                    : userData.dislikedFoods.join(', '),
              ),
            ],
          ),
          
          // 조리 환경
          _buildSectionCard(
            context: context,
            title: localization.cookingDataTitle,
            icon: Icons.kitchen_outlined,
            items: [
              _buildInfoItem(
                localization.cookingMethodsLabel,
                userData.preferredCookingMethods.isEmpty
                    ? localization.none
                    : userData.preferredCookingMethods.join(', '),
              ),
              _buildInfoItem(
                localization.cookingToolsLabel,
                userData.availableCookingTools.isEmpty
                    ? localization.none
                    : userData.availableCookingTools.join(', '),
              ),
              _buildInfoItem(
                localization.cookingTimeLabel,
                userData.preferredCookingTime != null
                    ? '${userData.preferredCookingTime} ${localization.minutes}'
                    : localization.none,
              ),
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
                          localization.isKorean() ? '주의 사항' : 'Notice',
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
                      localization.isKorean() 
                          ? '입력하신 정보는 맞춤형 식단을 추천하는데 사용됩니다. 정보는 언제든지 프로필 메뉴에서 수정할 수 있습니다.'
                          : 'The information you entered will be used to recommend a customized diet. You can modify this information at any time from the profile menu.',
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
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
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
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
} 