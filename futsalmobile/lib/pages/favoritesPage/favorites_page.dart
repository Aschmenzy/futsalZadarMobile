import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(child: Image.asset('assets/images/logo.png', scale: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
