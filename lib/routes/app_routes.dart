import 'package:flutter/material.dart';

import '../screens/about/about_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/ecodiary/eco_diary_screen.dart';
import '../screens/ranking/ranking_screen.dart';

class AppRoutes {
  static const String about = '/about';
  static const String detail = '/detail';
  static const String ecoDiary = '/eco-diary';
  static const String ranking = '/ranking';

  static Map<String, WidgetBuilder> get routes => {
        about: (_) => const AboutScreen(),
        detail: (_) => const DetailScreen(),
        ecoDiary: (_) => const EcoDiaryScreen(),
        ranking: (_) => const RankingScreen(),
      };
}
