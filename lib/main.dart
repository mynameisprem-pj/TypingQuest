import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/profile_service.dart';
import 'services/progress_service.dart';
import 'services/stats_service.dart';
import 'services/achievements_service.dart';
import 'services/sound_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileService().init();
  await ProgressService().init();
  await StatsService().init();
  await AchievementsService().init();
  await SoundService().init();
  runApp(const TypingQuestApp());
}

class TypingQuestApp extends StatelessWidget {
  const TypingQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TypingQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: ProfileService().hasProfile
          ? const HomeScreen()
          : const ProfileSelectScreen(),
    );
  }
}