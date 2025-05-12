import 'package:flutter/material.dart';

class EatrueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double height;
  final Widget? bottom;
  final Widget? stepper;

  const EatrueAppBar({
    Key? key,
    this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.height = kToolbarHeight, // 기본 AppBar 높이만 사용
    this.bottom,
    this.stepper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return AnimatedGradientContainer(
      height: preferredSize.height, // 계산된 선호 높이 명시적 적용
      child: SafeArea(
        bottom: false,  // 하단은 SafeArea에서 제외
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 사용 가능한 공간에 맞게 크기 조정
            return SingleChildScrollView( // 내용이 넘칠 경우 스크롤 가능하도록
              physics: NeverScrollableScrollPhysics(), // 스크롤은 비활성화(오직 오버플로우 방지용)
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 앱바 (로고, 앱 이름, 액션 버튼)
                    SizedBox(
                      height: kToolbarHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 좌측: 로고와 앱 이름 (또는 뒤로가기 버튼)
                            Row(
                              mainAxisSize: MainAxisSize.min, // 딱 필요한 크기만 차지하도록 설정
                              children: [
                                if (showBackButton) ...[
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                    onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 20, // 아이콘 크기 줄임
                                  ),
                                  const SizedBox(width: 4), // 간격 줄임
                                ],
                                _buildLogo(),
                                const SizedBox(width: 6), // 간격 줄임
                                Text(
                                  'Eatrue',
                                  style: theme.appBarTheme.titleTextStyle?.copyWith(
                                    fontSize: isSmallScreen ? 18 : 20, // 폰트 크기 줄임
                                  ),
                                ),
                              ],
                            ),
                            
                            // 우측: 액션 버튼들
                            if (actions != null) Row(children: actions!),
                          ],
                        ),
                      ),
                    ),
                    
                    // 타이틀과 서브타이틀 영역 (위에 배치)
                    if (title != null)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: isSmallScreen ? 1.0 : 4.0, // 더 작은 패딩으로 조정
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
                          children: [
                            Text(
                              title!,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20, // 폰트 크기 더 줄임
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (subtitle != null) ...[
                              SizedBox(height: isSmallScreen ? 0 : 1), // 간격 더 줄임
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12, // 폰트 크기 더 줄임
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1, // 한 줄만 표시
                                overflow: TextOverflow.ellipsis, // 넘치면 ...으로 처리
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                    // 하단 위젯 (스텝퍼)
                    if (bottom != null) 
                      SizedBox(
                        // 최대 높이 제한
                        height: isSmallScreen ? 60 : 70, 
                        child: bottom!,
                      ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // 하드코딩된 색상 사용
    const Color logoColor = Color(0xFF43A047); // Colors.green[600]과 동일한 색상
    
    return Container(
      width: 28, // 크기 줄임
      height: 28, // 크기 줄임
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // 더 작은 둥근 모서리
      ),
      child: Center(
        child: Icon(
          Icons.eco,
          size: 18, // 크기 줄임
          color: logoColor,
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize {
    // 동적으로 높이 계산
    double totalHeight = kToolbarHeight;  // 기본 앱바 높이
    
    // 타이틀과 서브타이틀이 있는 경우 높이 추가
    if (title != null) {
      totalHeight += 18 + 4;  // 타이틀 높이 + 패딩 (더 줄임)
      if (subtitle != null) {
        totalHeight += 10 + 2;  // 서브타이틀 높이 + 패딩 (더 줄임)
      }
    }
    
    // bottom 위젯이 있는 경우 높이 추가 (스텝퍼)
    if (bottom != null) {
      totalHeight += 70;  // 스텝퍼 위젯 높이 (고정값)
    }
    
    // 사용자 지정 높이가 있으면 해당 값 사용
    if (height > kToolbarHeight) {
      return Size.fromHeight(height);
    }
    
    return Size.fromHeight(totalHeight);
  }
}

// 그라데이션 애니메이션 배경을 위한 위젯
class AnimatedGradientContainer extends StatefulWidget {
  final Widget child;
  final double height;

  const AnimatedGradientContainer({
    Key? key,
    required this.child,
    required this.height,
  }) : super(key: key);

  @override
  State<AnimatedGradientContainer> createState() => _AnimatedGradientContainerState();
}

class _AnimatedGradientContainerState extends State<AnimatedGradientContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // 그린과 노란색을 가미한 고급스러운 색상 조합
  List<List<Color>> colorSets = [
    [Color(0xFF2E7D32), Color(0xFF558B2F), Color(0xFFAED581)], // 그린 + 라이트 그린 + 연한 그린
    [Color(0xFF558B2F), Color(0xFFAED581), Color(0xFFFFD54F)], // 라이트 그린 + 연한 그린 + 황토색
    [Color(0xFFAED581), Color(0xFFFFD54F), Color(0xFF388E3C)], // 연한 그린 + 황토색 + 미디엄 그린
    [Color(0xFFFFD54F), Color(0xFF388E3C), Color(0xFF2E7D32)], // 황토색 + 미디엄 그린 + 그린
  ];
  
  // 대각선 방향 정의 - 더 자연스러운 대각선 각도로 조정
  List<AlignmentGeometry> beginAlignments = [
    Alignment.topLeft,
    Alignment.bottomLeft,
    Alignment(-0.8, -0.8), // 약간 다른 대각선 각도
    Alignment.bottomRight,
  ];
  
  List<AlignmentGeometry> endAlignments = [
    Alignment.bottomRight,
    Alignment.topRight,
    Alignment(0.8, 0.8), // 약간 다른 대각선 각도
    Alignment.topLeft,
  ];
  
  int index = 0;
  late List<Color> currentColors;
  late AlignmentGeometry currentBegin;
  late AlignmentGeometry currentEnd;

  @override
  void initState() {
    super.initState();
    
    // 초기 색상 및 정렬 설정
    currentColors = List.from(colorSets[0]);
    currentBegin = beginAlignments[0];
    currentEnd = endAlignments[0];
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6), // 더 자연스러운 속도
    );
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          // 컨트롤러 값에 따라 다음 색상 및 정렬 세트로 보간
          final nextIndex = (index + 1) % colorSets.length;
          
          // 색상 보간 - 더 세밀한 색상 전환
          for (int i = 0; i < currentColors.length; i++) {
            currentColors[i] = Color.lerp(
              colorSets[index][i],
              colorSets[nextIndex][i],
              _controller.value,
            )!;
          }
          
          // 정렬 보간 - 더 자연스러운 움직임
          currentBegin = AlignmentGeometry.lerp(
            beginAlignments[index],
            beginAlignments[nextIndex],
            _controller.value,
          )!;
          
          currentEnd = AlignmentGeometry.lerp(
            endAlignments[index],
            endAlignments[nextIndex],
            _controller.value,
          )!;
        });
      }
    });
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 애니메이션이 완료되면 다음 색상 세트로 진행하고 다시 시작
        if (mounted) {
          setState(() {
            index = (index + 1) % colorSets.length;
            // 현재 색상을 새 시작 색상으로 설정 (자연스러운 전환)
            currentColors = List.from(colorSets[index]);
            currentBegin = beginAlignments[index];
            currentEnd = endAlignments[index];
          });
        }
        _controller.reset();
        _controller.forward();
      }
    });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: currentBegin as Alignment, 
          end: currentEnd as Alignment,
          colors: currentColors,
          stops: const [0.0, 0.5, 1.0], // 색상 분포 균일화
        ),
      ),
      child: widget.child,
    );
  }
} 