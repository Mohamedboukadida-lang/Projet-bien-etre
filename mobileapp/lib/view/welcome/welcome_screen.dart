import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/api_client.dart';
import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';

import '../../common_widgets/round_gradient_button.dart';

class WelcomeScreen extends StatefulWidget {
  static String routeName = "/WelcomeScreen";

  const WelcomeScreen({super.key, this.wellbeingService});

  /// Injectable for tests; defaults to the real service.
  final WellbeingService? wellbeingService;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// The user's first name from the back-end; null until loaded or if unavailable.
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      final user = await (widget.wellbeingService ?? WellbeingService())
          .fetchUser(ApiConfig.userId);
      final first = user.name.split(RegExp(r'\s+')).first;
      if (mounted && first.isNotEmpty) setState(() => _firstName = first);
    } on ApiException {
      // Keep the generic greeting.
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset("assets/images/welcome_promo.png",
                  width: media.width * 0.75, fit: BoxFit.fitWidth),
              SizedBox(height: media.width * 0.05),
              Text(
                _firstName == null ? "Welcome!" : "Welcome, $_firstName",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: media.width * 0.01),
              const Text(
                "You are all set now, let’s reach your\ngoals together with us",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grayColor,
                  fontSize: 12,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              RoundGradientButton(
                title: "Go To Home",
                onPressed: () {
                  Navigator.pushNamed(context, DashboardScreen.routeName);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
