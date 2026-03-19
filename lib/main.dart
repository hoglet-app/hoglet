import 'package:flutter/material.dart';
import 'package:solidart/solidart.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable the strict assert that requires SignalBuilder to detect signals
  // during the first build. The tracking still works correctly — this assert
  // fires false positives when signals are accessed through DI providers.
  SolidartConfig.assertSignalBuilderWithoutDependencies = false;
  runApp(const HogletApp());
}
