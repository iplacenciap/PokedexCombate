import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';

class AppBarPokedex extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppBarPokedex({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: TextStyle(color: Colors.white)),
      backgroundColor: PokedexAppColors.appBarColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
