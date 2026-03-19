import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'di/providers.dart';
import 'routing/app_router.dart';
import 'services/posthog_client.dart';
import 'services/storage_service.dart';

class HogletApp extends StatefulWidget {
  const HogletApp({super.key});

  @override
  State<HogletApp> createState() => _HogletAppState();
}

class _HogletAppState extends State<HogletApp> {
  late final _router = createRouter(isAuthenticated: true);
  final _client = PosthogClient();
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    // Initialize state providers with explicit service instances
    // (disco providers in the same scope can't reference each other)
    initStateProviders(client: _client, storage: _storage);
  }

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
