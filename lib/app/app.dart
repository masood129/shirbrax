import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';
import 'theme/app_theme.dart';

import 'package:shirbrax/shared/controllers/theme_controller.dart';

class ShirBraxApp extends GetView<ThemeController> {
  const ShirBraxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return MaterialApp.router(
        title: 'شیربرکس',
        debugShowCheckedModeBanner: false,

        // ─── Theme ──────────────────────────────────────────
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode,

        // ─── Routing ────────────────────────────────────────
        routerConfig: AppPages.router,

        // ─── RTL Persian ────────────────────────────────────
        locale: const Locale('fa', 'IR'),
        builder: (context, child) {
          // GetX overlay + RTL wrapper
          return GetMaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
      );
    });
  }
}
