import 'package:flutter/material.dart';

/// 홈 화면의 날짜 선택 위젯
/// 주간 캘린더 형태로 표시되며, 선택된 날짜를 강조 표시합니다.
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> weekDates;
  final Function(DateTime) onDateSelected;
  
  /// 생성자
  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.weekDates,
    required this.onDateSelected,
  }) : super(key: key);
  
  // 날짜가 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDarkMode 
          ? theme.colorScheme.primary.withOpacity(0.15) // 다크모드에서는 더 진한 배경색
          : theme.colorScheme.primary.withOpacity(0.05),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // 현재 월 표시
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${selectedDate.year}년 ${selectedDate.month}월',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // 요일 및 날짜 선택 행
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: weekDates.length,
              itemBuilder: (context, index) {
                final date = weekDates[index];
                final isSelected = date.year == selectedDate.year && 
                                   date.month == selectedDate.month && 
                                   date.day == selectedDate.day;
                final today = _isToday(date);
                // 날짜가 다른 월에 속하는지 확인
                final isDifferentMonth = date.month != selectedDate.month;
                
                // 요일 이름 (월~일)
                String weekdayName = '';
                switch (date.weekday) {
                  case 1: weekdayName = '월'; break;
                  case 2: weekdayName = '화'; break;
                  case 3: weekdayName = '수'; break;
                  case 4: weekdayName = '목'; break;
                  case 5: weekdayName = '금'; break;
                  case 6: weekdayName = '토'; break;
                  case 7: weekdayName = '일'; break;
                }

                // 요일별 색상 설정 (다크모드 대응)
                Color weekdayColor;
                if (isSelected) {
                  weekdayColor = Colors.white;
                } else if (date.weekday == 7) { // 일요일
                  weekdayColor = Colors.red.shade300;
                } else if (date.weekday == 6) { // 토요일
                  weekdayColor = Colors.blue.shade300;
                } else {
                  weekdayColor = isDarkMode ? Colors.white70 : Colors.black87;
                }
                
                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: Container(
                    width: 50,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : (today ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 요일 표시
                        Text(
                          weekdayName,
                          style: TextStyle(
                            color: weekdayColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        // 날짜 표시
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? Colors.white 
                                : (today 
                                    ? theme.colorScheme.primary 
                                    : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isSelected 
                                    ? theme.colorScheme.primary 
                                    : (today 
                                        ? Colors.white 
                                        : (isDifferentMonth 
                                            ? (isDarkMode ? Colors.grey[400] : Colors.grey) 
                                            : (isDarkMode ? Colors.white : Colors.black))),
                                fontWeight: isSelected || today 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 