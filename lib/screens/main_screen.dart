import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'meal_base_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_bar_widget.dart';
import '../providers/survey_data_provider.dart';
import '../providers/meal_provider.dart';
import '../services/food_analysis_service.dart';
import '../widgets/progress_loading.dart';
import '../l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // 탭에 해당하는 화면들
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(), // 홈 화면
      MealGenerationScreen(), // 식단 생성 화면
      MealBaseScreen(), // 식단 베이스 화면
      ProfileScreen(), // 프로필 화면
    ];
  }
  
  // 각 탭 아이템 정의
  List<BottomNavigationBarItem> _buildBottomNavItems(BuildContext context) {
    final localization = AppLocalizations.of(context);
    
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: localization.tabHome,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.restaurant_menu_outlined),
        activeIcon: Icon(Icons.restaurant_menu),
        label: localization.tabCreateMeal,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: localization.tabMealBase,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: localization.tabProfile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _buildBottomNavItems(context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
    );
  }
}

// 식단 생성 화면
class MealGenerationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context);
    final localization = AppLocalizations.of(context);
    
    // 지역화 설정
    mealProvider.setLocalizations(context);
    
    final isLoading = mealProvider.isLoading;
    final progressMessage = mealProvider.progressMessage;
    final progressPercentage = mealProvider.progressPercentage;
    final errorMessage = mealProvider.errorMessage;
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: localization.mealGenerationTitle,
        subtitle: localization.mealGenerationSubtitle,
      ),
      body: isLoading 
          ? FullScreenProgressLoading(
              message: progressMessage ?? localization.loadingUserInfo,
              progress: progressPercentage,
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage('assets/images/meal_generation.png'),
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // 이미지 로드 실패 시 대체 UI
                                return Container(
                                  height: 200,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 80,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        localization.mealGenerationTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24),
                            Text(
                              localization.mealGenerationTitle,
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                localization.mealGenerationDescription,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                // 식단 생성 후 홈 화면 탭으로 이동하도록 수정
                                mealProvider.orchestrateMenuGeneration();
                                
                                // 생성 시작 메시지 표시
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localization.generatingMealMessage),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: Icon(Icons.restaurant_menu),
                              label: Text(localization.generateMealButton),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// 프로필 화면
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context);
    final userData = surveyDataProvider.userData;
    final localization = AppLocalizations.of(context);
    
    // 기본 정보가 누락된 경우 이니셜 화면으로 이동
    if (userData.age == null || userData.gender == null || userData.height == null || userData.weight == null) {
      // 다음 프레임에서 이동하도록 스케줄링 (빌드 중 네비게이션 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/initial', (route) => false);
      });
      
      // 로딩 화면 표시
      return Scaffold(
        body: FullScreenProgressLoading(
          message: localization.loadingUserInfo,
        ),
      );
    }
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: localization.tabProfile,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => SettingsScreen())
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              localization.userName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 32),
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localization.profileBasicInfo, style: Theme.of(context).textTheme.titleLarge),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, localization.profileAge, userData.age != null ? '${userData.age}${localization.isKorean() ? "세" : ""}' : localization.none),
                    _buildProfileItem(context, localization.profileGender, userData.gender ?? localization.none),
                    _buildProfileItem(context, localization.profileHeight, userData.height != null ? '${userData.height}cm' : localization.none),
                    _buildProfileItem(context, localization.profileWeight, userData.weight != null ? '${userData.weight}kg' : localization.none),
                    _buildProfileItem(context, localization.profileActivityLevel, userData.activityLevel ?? localization.none),
                  ],
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localization.dietaryRestrictions, style: Theme.of(context).textTheme.titleLarge),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, localization.isVegan, userData.isVegan ? localization.yes : localization.no),
                    _buildProfileItem(context, localization.religiousRestrictions, userData.isReligious ? (userData.religionDetails ?? localization.yes) : localization.none),
                    _buildProfileItem(context, localization.allergies, userData.allergies.isEmpty ? localization.none : userData.allergies.join(', ')),
                    _buildProfileItem(context, localization.favoriteFoods, userData.favoriteFoods.isEmpty ? localization.none : userData.favoriteFoods.join(', ')),
                    _buildProfileItem(context, localization.dislikedFoods, userData.dislikedFoods.isEmpty ? localization.none : userData.dislikedFoods.join(', ')),
                  ],
                ),
              ),
            ),
            
            // 선호 식품 분해 결과 카드
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(localization.preferredFoodAnalysis, 
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(width: 8),
                        Tooltip(
                          message: 'AI가 선호하는 음식을 분석한 결과입니다',
                          child: Icon(Icons.info_outline, 
                                  size: 16, 
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        SizedBox(width: 8),
                        _buildAnalysisStatusBadge(
                          context, 
                          hasData: userData.preferredIngredients.isNotEmpty || 
                                   userData.preferredSeasonings.isNotEmpty || 
                                   userData.preferredCookingStyles.isNotEmpty
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, localization.ingredients, 
                        userData.preferredIngredients.isEmpty ? localization.noAnalysisResults
                        : userData.preferredIngredients.join(', ')),
                    _buildProfileItem(context, localization.seasonings, 
                        userData.preferredSeasonings.isEmpty ? localization.noAnalysisResults
                        : userData.preferredSeasonings.join(', ')),
                    _buildProfileItem(context, localization.cookingStyles, 
                        userData.preferredCookingStyles.isEmpty ? localization.noAnalysisResults
                        : userData.preferredCookingStyles.join(', ')),
                    if (userData.favoriteFoods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _reanalyzeFoodPreferences(context, true),
                            icon: Icon(Icons.refresh),
                            label: Text(userData.preferredIngredients.isEmpty ? localization.analyzeButton : localization.reanalyzeButton),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // 기피 식품 분해 결과 카드
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(localization.dislikedFoodAnalysis, 
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(width: 8),
                        Tooltip(
                          message: 'AI가 기피하는 음식을 분석한 결과입니다',
                          child: Icon(Icons.info_outline, 
                                  size: 16, 
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        SizedBox(width: 8),
                        _buildAnalysisStatusBadge(
                          context, 
                          hasData: userData.dislikedIngredients.isNotEmpty || 
                                   userData.dislikedSeasonings.isNotEmpty || 
                                   userData.dislikedCookingStyles.isNotEmpty
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, localization.ingredients, 
                        userData.dislikedIngredients.isEmpty ? localization.noAnalysisResults 
                        : userData.dislikedIngredients.join(', ')),
                    _buildProfileItem(context, localization.seasonings, 
                        userData.dislikedSeasonings.isEmpty ? localization.noAnalysisResults 
                        : userData.dislikedSeasonings.join(', ')),
                    _buildProfileItem(context, localization.cookingStyles, 
                        userData.dislikedCookingStyles.isEmpty ? localization.noAnalysisResults 
                        : userData.dislikedCookingStyles.join(', ')),
                    if (userData.dislikedFoods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _reanalyzeFoodPreferences(context, false),
                            icon: Icon(Icons.refresh),
                            label: Text(userData.dislikedIngredients.isEmpty ? localization.analyzeButton : localization.reanalyzeButton),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            Card(
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localization.cookingEnvironment, style: Theme.of(context).textTheme.titleLarge),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, localization.preferredCookingMethods, userData.preferredCookingMethods.isEmpty ? localization.none : userData.preferredCookingMethods.join(', ')),
                    _buildProfileItem(context, localization.availableCookingTools, userData.availableCookingTools.isEmpty ? localization.none : userData.availableCookingTools.join(', ')),
                    _buildProfileItem(context, localization.preferredCookingTime, userData.preferredCookingTime != null ? '${userData.preferredCookingTime} ${localization.minutes}' : localization.none),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                surveyDataProvider.resetSurveyForEditing();
                Navigator.of(context).pushNamedAndRemoveUntil('/survey', (route) => false);
              },
              icon: Icon(Icons.edit),
              label: Text(localization.editProfile),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 24),
            // 초기 설문 보기 카드
            Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit_document),
                    title: Text(localization.viewInitialSurvey),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/initial');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 프로필 항목 위젯
  Widget _buildProfileItem(BuildContext context, String label, String value) {
    // 값이 긴 경우 처리 (특히 분석 결과와 같은 긴 목록)
    bool isLongText = value.length > 50;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: isLongText 
                  ? Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 분석 상태 배지 위젯
  Widget _buildAnalysisStatusBadge(BuildContext context, {required bool hasData}) {
    final localization = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: hasData ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hasData ? localization.analysisDone : localization.notAnalyzed,
        style: TextStyle(
          fontSize: 12,
          color: hasData ? Colors.green[800] : Colors.orange[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  // 식품 재분석 함수
  void _reanalyzeFoodPreferences(BuildContext context, bool isPreferred) {
    final FoodAnalysisService foodAnalysisService = FoodAnalysisService();
    final surveyProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final userData = surveyProvider.userData;
    final localization = AppLocalizations.of(context);
    
    // 분석 시작 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localization.analyzingMessage),
        duration: Duration(seconds: 2),
      ),
    );
    
    if (isPreferred) {
      // 선호 식품 분석
      foodAnalysisService.analyzeDishes(userData.favoriteFoods).then((result) {
        if (result != null) {
          // 분석 결과 저장
          surveyProvider.updateUserData(userData.copyWith(
            preferredIngredients: FoodAnalysisService.parseStringList(result['ingredients']),
            preferredSeasonings: FoodAnalysisService.parseStringList(result['seasonings']),
            preferredCookingStyles: FoodAnalysisService.parseStringList(result['cooking_methods']),
          ));
          
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.analysisComplete),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 오류 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.analysisError),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } else {
      // 기피 식품 분석
      foodAnalysisService.analyzeDishes(userData.dislikedFoods).then((result) {
        if (result != null) {
          // 분석 결과 저장
          surveyProvider.updateUserData(userData.copyWith(
            dislikedIngredients: FoodAnalysisService.parseStringList(result['ingredients']),
            dislikedSeasonings: FoodAnalysisService.parseStringList(result['seasonings']),
            dislikedCookingStyles: FoodAnalysisService.parseStringList(result['cooking_methods']),
          ));
          
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.analysisComplete),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 오류 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.analysisError),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
} 