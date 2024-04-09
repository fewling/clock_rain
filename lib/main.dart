import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home.dart';
import 'services/preference_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sp = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferenceProvider.overrideWith((_) => sp)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorSeed = ref.watch(
      appPreferenceNotifierProvider.select((value) => value.colorSchemeSeed),
    );
    final isDarkMode = ref.watch(
      appPreferenceNotifierProvider.select((value) => value.isDarkMode),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Home(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(colorSeed),
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
    );
  }
}
