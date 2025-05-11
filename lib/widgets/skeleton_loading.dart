import 'package:flutter/material.dart';

// 스켈레톤 효과를 위한 기본 위젯
class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonContainer({
    Key? key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  // 원형 스켈레톤
  factory SkeletonContainer.circular({
    required double width,
    required double height,
    double radius = 16,
  }) =>
      SkeletonContainer(
        width: width,
        height: height,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      );

  // 사각형 스켈레톤
  factory SkeletonContainer.rectangular({
    required double width,
    required double height,
    double radius = 8,
  }) =>
      SkeletonContainer(
        width: width,
        height: height,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[300]
            : Colors.grey[700],
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SkeletonAnimation(),
      ),
    );
  }
}

// 스켈레톤 애니메이션 위젯
class SkeletonAnimation extends StatefulWidget {
  const SkeletonAnimation({Key? key}) : super(key: key);

  @override
  _SkeletonAnimationState createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = isDarkMode ? Colors.grey[600]! : Colors.grey[200]!;
    final baseColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _animation.value, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: Container(
            color: baseColor,
          ),
        );
      },
    );
  }
}

// 레시피 카드 스켈레톤
class RecipeCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 레시피 이미지 스켈레톤
            SkeletonContainer.rectangular(
              width: double.infinity,
              height: 120,
              radius: 8,
            ),
            SizedBox(height: 12),
            // 제목 스켈레톤
            SkeletonContainer(height: 24),
            SizedBox(height: 8),
            // 설명 스켈레톤
            SkeletonContainer(height: 14),
            SizedBox(height: 4),
            SkeletonContainer(height: 14, width: MediaQuery.of(context).size.width * 0.7),
            SizedBox(height: 16),
            // 하단 정보 스켈레톤
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonContainer(width: 80, height: 18),
                SkeletonContainer(width: 60, height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 식단 카드 스켈레톤
class MealCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘/이미지 위치
            SkeletonContainer.circular(width: 40, height: 40),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(height: 16),
                  SizedBox(height: 6),
                  SkeletonContainer(height: 12, width: MediaQuery.of(context).size.width * 0.5),
                  SizedBox(height: 4),
                  SkeletonContainer(height: 12, width: MediaQuery.of(context).size.width * 0.3),
                ],
              ),
            ),
            SizedBox(width: 8),
            SkeletonContainer.circular(width: 24, height: 24, radius: 12),
          ],
        ),
      ),
    );
  }
}

// 레시피 상세 화면 스켈레톤
class RecipeDetailSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // 제목 스켈레톤
        SkeletonContainer(height: 32),
        SizedBox(height: 8),
        // 부제목 스켈레톤
        SkeletonContainer(height: 18, width: MediaQuery.of(context).size.width * 0.7),
        SizedBox(height: 16),
        
        // 영양소 정보 카드 스켈레톤
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 제목
                SkeletonContainer(height: 20, width: 100),
                SizedBox(height: 12),
                // 영양소 아이템들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(3, (index) => 
                    Column(
                      children: [
                        SkeletonContainer.circular(width: 50, height: 50, radius: 25),
                        SizedBox(height: 8),
                        SkeletonContainer(height: 14, width: 60),
                        SizedBox(height: 4),
                        SkeletonContainer(height: 12, width: 40),
                      ],
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // 재료 목록 카드 스켈레톤
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 제목
                SkeletonContainer(height: 20, width: 80),
                SizedBox(height: 12),
                // 재료 아이템들
                ...List.generate(5, (index) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonContainer(height: 16, width: MediaQuery.of(context).size.width * 0.4),
                        SkeletonContainer(height: 16, width: 60),
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // 조리 과정 카드 스켈레톤
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 제목
                SkeletonContainer(height: 20, width: 120),
                SizedBox(height: 16),
                // 조리 단계 아이템들
                ...List.generate(4, (index) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonContainer.circular(width: 24, height: 24, radius: 12),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonContainer(height: 16),
                              SizedBox(height: 4),
                              SkeletonContainer(height: 16),
                              SizedBox(height: 4),
                              SkeletonContainer(height: 16, width: MediaQuery.of(context).size.width * 0.7),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 홈 화면 스켈레톤
class HomeScreenSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 선택 영역 스켈레톤
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SkeletonContainer(height: 40),
          ),
          SizedBox(height: 20),
          
          // 식단 카드 스켈레톤
          ...['아침', '점심', '저녁', '간식'].map((mealType) => 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 식사 유형 제목
                  Row(
                    children: [
                      SkeletonContainer.circular(width: 24, height: 24, radius: 12),
                      SizedBox(width: 8),
                      SkeletonContainer(height: 18, width: 60),
                    ],
                  ),
                  SizedBox(height: 8),
                  // 식사 카드
                  MealCardSkeleton(),
                ],
              ),
            )
          ).toList(),
        ],
      ),
    );
  }
} 