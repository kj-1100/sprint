import 'package:flutter/material.dart';
import 'package:sprint/home/home_page_large.dart';
import 'package:sprint/home/home_page_small.dart';

class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  @override
  Widget build(BuildContext context) {
      return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return HomePageSmall(); // Celular
      }  else {
        return HomePageLarge(); // Computador
      }
    },
  );
  }
}