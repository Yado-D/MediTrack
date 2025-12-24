import 'package:flutter/material.dart';
import 'package:meditrack/services/get_current_user.dart';

import '../../config/routes/name.dart';
import '../../services/global.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    OnLoadingFun();
  }

  OnLoadingFun() async {
    bool isUserNew = await Global.storageServices.GetDeviceFirstOpen();
    String? isUserLogin = await UserProvider().getUuid();
    await Future.delayed(Duration(seconds: 2)).then((_) {
      print("....on splash screen...");
      if (isUserNew) {
        Navigator.pushNamedAndRemoveUntil(
            context, NamedRoutes.OnboardingPage, (predicate) => false);
        return;
      } else if (isUserLogin != null) {
        Navigator.pushNamedAndRemoveUntil(
            context, NamedRoutes.HomePage, (predicate) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, NamedRoutes.SigninPage, (predicate) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 80,
              child: Image.asset(
                "assets/logos/meditrack.png",
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
