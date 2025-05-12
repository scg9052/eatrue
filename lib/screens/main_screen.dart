import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'meal_base_screen.dart';
import '../widgets/app_bar_widget.dart';
import '../providers/survey_data_provider.dart';
import '../providers/meal_provider.dart';
import '../services/food_analysis_service.dart';

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
  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '홈',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_menu_outlined),
      activeIcon: Icon(Icons.restaurant_menu),
      label: '식단 생성',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: '식단 베이스',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: '프로필',
    ),
  ];

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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: _bottomNavItems,
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
    final isLoading = mealProvider.isLoading;
    final progressMessage = mealProvider.progressMessage;
    final errorMessage = mealProvider.errorMessage;
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: '식단 생성',
        subtitle: '개인 맞춤 식단을 생성합니다',
      ),
      body: isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(progressMessage ?? '로딩 중...'),
                ],
              ),
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
                  Image.asset(
                    'assets/images/meal_generation.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 24),
                  Text(
                    '맞춤형 식단 생성',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'AI가 당신의 신체 정보, 선호도, 활동량 등을 고려하여 최적의 식단을 구성합니다.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 식단 생성 후 홈 화면 탭으로 이동하도록 수정
                      mealProvider.orchestrateMenuGeneration();
                      
                      // 생성 시작 메시지 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('맞춤 식단을 생성 중입니다. 잠시 기다려주세요.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // 메인 화면의 홈 탭(인덱스 0)으로 이동
                      final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
                      if (mainScreenState != null) {
                        mainScreenState.setState(() {
                          mainScreenState._currentIndex = 0; // 홈 탭(인덱스 0)으로 이동
                        });
                      }
                    },
                    icon: Icon(Icons.auto_awesome),
                    label: Text('맞춤 식단 생성하기'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
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
    
    // 기본 정보가 누락된 경우 이니셜 화면으로 이동
    if (userData.age == null || userData.gender == null || userData.height == null || userData.weight == null) {
      // 다음 프레임에서 이동하도록 스케줄링 (빌드 중 네비게이션 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/initial', (route) => false);
      });
      
      // 로딩 화면 표시
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('사용자 정보를 확인 중입니다...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: '내 프로필',
        subtitle: '개인 정보 및 설정 관리',
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24),
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('기본 정보', style: Theme.of(context).textTheme.titleLarge),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, '나이', userData.age != null ? '${userData.age}세' : '정보 없음'),
                    _buildProfileItem(context, '성별', userData.gender ?? '정보 없음'),
                    _buildProfileItem(context, '키', userData.height != null ? '${userData.height}cm' : '정보 없음'),
                    _buildProfileItem(context, '체중', userData.weight != null ? '${userData.weight}kg' : '정보 없음'),
                    _buildProfileItem(context, '활동 수준', userData.activityLevel ?? '정보 없음'),
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
                    Text('식이 제한 및 선호도', style: Theme.of(context).textTheme.titleLarge),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, '채식주의자', userData.isVegan ? '예' : '아니오'),
                    _buildProfileItem(context, '종교적 제한', userData.isReligious ? (userData.religionDetails ?? '있음') : '없음'),
                    _buildProfileItem(context, '알레르기', userData.allergies.isEmpty ? '없음' : userData.allergies.join(', ')),
                    _buildProfileItem(context, '선호 식품', userData.favoriteFoods.isEmpty ? '없음' : userData.favoriteFoods.join(', ')),
                    _buildProfileItem(context, '기피 식품', userData.dislikedFoods.isEmpty ? '없음' : userData.dislikedFoods.join(', ')),
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
                        Text('선호 식품 분석 결과', 
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(width: 8),
                        Tooltip(
                          message: '선호하는 음식을 AI가 분석하여 식재료, 양념, 조리 방식으로 분류한 결과입니다.',
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
                    _buildProfileItem(context, '선호 식재료', 
                        userData.preferredIngredients.isEmpty ? '분석 결과 없음' 
                        : userData.preferredIngredients.join(', ')),
                    _buildProfileItem(context, '선호 양념', 
                        userData.preferredSeasonings.isEmpty ? '분석 결과 없음' 
                        : userData.preferredSeasonings.join(', ')),
                    _buildProfileItem(context, '선호 조리 방식', 
                        userData.preferredCookingStyles.isEmpty ? '분석 결과 없음' 
                        : userData.preferredCookingStyles.join(', ')),
                    if (userData.favoriteFoods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _reanalyzeFoodPreferences(context, true),
                            icon: Icon(Icons.refresh),
                            label: Text(userData.preferredIngredients.isEmpty ? '분석하기' : '다시 분석하기'),
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
                        Text('기피 식품 분석 결과', 
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(width: 8),
                        Tooltip(
                          message: '기피하는 음식을 AI가 분석하여 식재료, 양념, 조리 방식으로 분류한 결과입니다.',
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
                    _buildProfileItem(context, '기피 식재료', 
                        userData.dislikedIngredients.isEmpty ? '분석 결과 없음' 
                        : userData.dislikedIngredients.join(', ')),
                    _buildProfileItem(context, '기피 양념', 
                        userData.dislikedSeasonings.isEmpty ? '분석 결과 없음' 
                        : userData.dislikedSeasonings.join(', ')),
                    _buildProfileItem(context, '기피 조리 방식', 
                        userData.dislikedCookingStyles.isEmpty ? '분석 결과 없음' 
                        : userData.dislikedCookingStyles.join(', ')),
                    if (userData.dislikedFoods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _reanalyzeFoodPreferences(context, false),
                            icon: Icon(Icons.refresh),
                            label: Text(userData.dislikedIngredients.isEmpty ? '분석하기' : '다시 분석하기'),
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
                    Text('조리 환경', style: Theme.of(context).textTheme.titleLarge),
                    Divider(),
                    SizedBox(height: 8),
                    _buildProfileItem(context, '선호 조리법', userData.preferredCookingMethods.isEmpty ? '없음' : userData.preferredCookingMethods.join(', ')),
                    _buildProfileItem(context, '가용 조리도구', userData.availableCookingTools.isEmpty ? '없음' : userData.availableCookingTools.join(', ')),
                    _buildProfileItem(context, '선호 조리시간', userData.preferredCookingTime != null ? '${userData.preferredCookingTime}분' : '정보 없음'),
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
              label: Text('내 정보 수정하기'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 24),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: hasData ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hasData ? '분석 완료' : '미분석',
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
    
    // 분석 시작 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isPreferred ? '선호' : '기피'} 식품을 분석 중입니다...'),
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
              content: Text('선호 식품 분석이 완료되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 오류 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('분석 중 오류가 발생했습니다'),
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
              content: Text('기피 식품 분석이 완료되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 오류 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('분석 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
} 