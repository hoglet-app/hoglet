import 'package:flutter/widgets.dart';

import '../services/posthog_client.dart';
import '../services/storage_service.dart';

class AppProviders extends InheritedWidget {
  final PosthogClient client;
  final StorageService storage;

  const AppProviders({
    super.key,
    required this.client,
    required this.storage,
    required super.child,
  });

  static AppProviders of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppProviders>();
    assert(result != null, 'No AppProviders found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppProviders oldWidget) =>
      client != oldWidget.client || storage != oldWidget.storage;
}
