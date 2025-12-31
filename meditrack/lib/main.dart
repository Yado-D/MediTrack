import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:meditrack/features/home/presentation/bloc/home_bloc.dart';
import 'package:meditrack/services/get_current_user.dart';
import 'package:meditrack/services/global.dart';
import 'package:meditrack/services/notifications_controller.dart';
import 'package:provider/provider.dart';

import 'config/routes/name.dart';
import 'config/routes/pages.dart';
import 'config/theme/theme_mode_provider.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'init_dependencies.dart';

void main() async {
  await Global.init();
  await initDependencies();
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      'resource://drawable/res_meditrack_notifications_icon',
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true),
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'schedule_channel',
            channelName: 'Scheduled notifications',
            channelDescription:
                'Notification channel for scheduled medicine reminders',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController
          .onNotificationDisplayedMethod, // <--- THIS IS THE KEY ONE
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (create) => serviceLocator<AuthBloc>()),
          BlocProvider(create: (create) => serviceLocator<HomeBloc>()),
        ],
        child: Consumer<ThemeManager>(
          builder: (context, themeManager, child) {
            return GetMaterialApp(
              title: 'UniHub',
              debugShowCheckedModeBanner: false,
              themeMode: themeManager.themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              onGenerateRoute: NamedRouteSettings.GenerateRouteSettings,
              initialRoute: NamedRoutes.SplashScreenPage,
              // getPages: AppPages.routes,
            );
          },
        ),
      ),
    );
  }
}
