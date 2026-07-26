import 'package:flutter/material.dart';

class AppNavBrand extends StatelessWidget {
  final double fontSize;

  const AppNavBrand({super.key, this.fontSize = 35});

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'LT',
            style: TextStyle(
              color: const Color.fromARGB(255, 248, 35, 35),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'D',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AppNavBrandLeading extends StatelessWidget {
  const AppNavBrandLeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 15),
      child: const AppNavBrand(fontSize: 26),
    );
  }
}