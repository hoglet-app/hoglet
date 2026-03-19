import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'di/providers.dart';
import 'routing/app_router.dart';

class HogletApp extends StatefulWidget {
  const HogletApp({super.key});

  @override
  State<HogletApp> createState() => _HogletAppState();
}

class _HogletAppState extends State<HogletApp> {
  late final _router = createRouter(isAuthenticated: true);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme();

    return ProviderScope(
      providers: [
        posthogClientProvider,
        storageServiceProvider,
        dashboardStateProvider,
        insightsStateProvider,
        flagsStateProvider,
        eventsStateProvider,
      ],
      child: MaterialApp.router(
        title: 'Hoglet',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF15A24),
            brightness: Brightness.light,
          ),
          textTheme: textTheme,
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
