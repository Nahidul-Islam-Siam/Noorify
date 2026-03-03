import 'package:flutter/material.dart';

Widget bottomNav(int active) {
  final items = [
    ('Home', Icons.home_filled),
    ('Discover', Icons.explore_outlined),
    ('Quran', Icons.menu_book_outlined),
    ('Prayer', Icons.calendar_month_outlined),
    ('Profile', Icons.person_outline),
  ];

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isActive = index == active;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$2,
              size: 20,
              color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
            ),
            const SizedBox(height: 2),
            Text(
              item.$1,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
              ),
            ),
          ],
        );
      }),
    ),
  );
}
