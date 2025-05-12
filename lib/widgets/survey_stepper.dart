import 'package:flutter/material.dart';

class SurveyStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<StepData> steps;
  final Function(int) onStepTapped;
  final bool allowStepSelection;

  const SurveyStepper({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.steps,
    required this.onStepTapped,
    this.allowStepSelection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48.0 : 56.0, // 오버플로우 방지를 위해 높이 더 줄임
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 2.0 : 4.0, // 패딩 더 줄임
          vertical: 0.0, // 수직 패딩 제거
        ),
        // Row로 변경하여 수평 레이아웃 사용
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 스텝 아이콘들을 수평으로 배치
            Expanded(
              flex: 3,
              child: Row(
                children: List.generate(totalSteps * 2 - 1, (index) {
                  // 짝수 인덱스는 스텝 아이콘, 홀수 인덱스는 연결선
                  if (index % 2 == 0) {
                    final stepIndex = index ~/ 2;
                    final step = steps[stepIndex];
                    final isActive = stepIndex == currentStep;
                    final isCompleted = stepIndex < currentStep;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: allowStepSelection && (isCompleted || stepIndex == currentStep) 
                            ? () => onStepTapped(stepIndex)
                            : null,
                        child: _StepIndicator(
                          stepNumber: stepIndex + 1,
                          isActive: isActive,
                          isCompleted: isCompleted,
                          isSmallScreen: isSmallScreen,
                          icon: step.icon,
                          title: step.title,
                          theme: theme,
                        ),
                      ),
                    );
                  } else {
                    // 연결선 - 더 세련된 디자인으로 변경
                    final leftStepIndex = index ~/ 2;
                    final rightStepIndex = leftStepIndex + 1;
                    final isLeftCompleted = leftStepIndex < currentStep;
                    final isRightActive = rightStepIndex <= currentStep;
                    
                    return Expanded(
                      child: Container(
                        height: isSmallScreen ? 20 : 24, // 높이 제한
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 배경 라인
                            Container(
                              height: 1, // 두께 줄임
                              color: Colors.grey[300],
                            ),
                            // 활성화된 라인 (조건부 표시)
                            if (isLeftCompleted && isRightActive)
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                height: 1, // 두께 줄임
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                }),
              ),
            ),
            
            // 진행 상태 텍스트 - 오른쪽에 배치
            Padding(
              padding: const EdgeInsets.only(left: 4.0), // 패딩 더 줄임
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.0, // 패딩 더 줄임
                  vertical: 1.0, // 패딩 줄임
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0), // 더 작은 반경
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${currentStep + 1}/$totalSteps',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 8 : 10, // 폰트 크기 더 줄임
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

// 스텝 인디케이터를 별도 위젯으로 분리
class _StepIndicator extends StatelessWidget {
  final int stepNumber;
  final bool isActive;
  final bool isCompleted;
  final bool isSmallScreen;
  final IconData icon;
  final String title;
  final ThemeData theme;

  const _StepIndicator({
    Key? key,
    required this.stepNumber,
    required this.isActive,
    required this.isCompleted,
    required this.isSmallScreen,
    required this.icon,
    required this.title,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 컬럼의 높이를 제한하기 위한 크기 계산
    final circleSize = isSmallScreen ? 20.0 : 24.0; // 크기 더 줄임
    final rippleSize = isSmallScreen ? 28.0 : 32.0; // 크기 더 줄임
    
    // 컬럼의 높이를 명시적으로 제한 (활성화 효과 포함)
    final containerHeight = isActive ? rippleSize + 2 : circleSize + 2; // 여유 공간 더 줄임
    
    return SizedBox(
      height: containerHeight,
      child: Center(
        child: Tooltip(
          message: title,
          preferBelow: false, // 툴팁이 항상 위에 표시되도록 설정
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 스텝 배경
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: isActive 
                      ? theme.colorScheme.primary
                      : isCompleted 
                          ? theme.colorScheme.primary.withOpacity(0.7) 
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 1, // 그림자 더 줄임
                      spreadRadius: 0.5, // 그림자 확산 더 줄임
                    )
                  ] : null,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: isSmallScreen ? 10 : 12, // 아이콘 크기 더 줄임
                        )
                      : Icon(
                          icon, // 숫자 대신 아이콘 사용
                          color: isActive ? Colors.white : Colors.grey[700],
                          size: isSmallScreen ? 10 : 12, // 아이콘 크기 더 줄임
                        ),
                ),
              ),
              
              // 활성화 효과 (물결 효과)
              if (isActive)
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: rippleSize,
                    height: rippleSize,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        width: 1, // 테두리 두께 유지
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepData {
  final String title;
  final IconData icon;

  StepData({
    required this.title,
    required this.icon,
  });
} 