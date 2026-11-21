import 'package:fitnessapp/routes.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('hydrationBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'well-being',
      debugShowCheckedModeBanner: false,
      routes: routes,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor1,
            primary: AppColors.primaryColor1,
            secondary: AppColors.secondaryColor1,
          ),
          primaryColor: AppColors.primaryColor1,
          scaffoldBackgroundColor: AppColors.whiteColor,
          useMaterial3: true,
          fontFamily: "Poppins"),
      home: const LoginScreen(),
    );
  }
}
