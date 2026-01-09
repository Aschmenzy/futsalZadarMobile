import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': 'assets/icons/navBar/Home.png', 'label': 'Početna'},
      {'icon': 'assets/icons/navBar/Trophy.png', 'label': 'Utakmice'},
      {'icon': 'assets/icons/navBar/Shield.png', 'label': 'Lige'},
      {'icon': 'assets/icons/navBar/News.png', 'label': 'Vijesti'},
      {'icon': 'assets/icons/navBar/Star.png', 'label': 'Favoriti'},
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: activeIndex,
      onTap: onTap,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey[400],
      elevation: 15,
      items: items.asMap().entries.map((entry) {
        int index = entry.key;
        Map item = entry.value;
        bool isActive = activeIndex == index;

        return BottomNavigationBarItem(
          icon: Image.asset(
            item['icon'] as String,
            width: 35,
            height: 35,
            color: isActive ? Colors.blue : Colors.grey[400],
            colorBlendMode: BlendMode.srcIn,
          ),
          label: item['label'] as String,
        );
      }).toList(),
    );
  }
}
