import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/clock_rain_game.dart';
import '../services/preference_provider.dart';
import 'clock_rain_screen.dart';

/// Use these keys to obtain the `currentContext`, in turn the `Size` of the widget.
/// So that we can match the size of the [FallingBodyWidget] and [FallingBodyComponent].
final measureSecondsKey = GlobalKey();
final measureMinutesKey = GlobalKey();
final measureHoursKey = GlobalKey();

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final _clockRainGame = ClockRainGame();

  @override
  Widget build(BuildContext context) {
    final hourTextStyle = Theme.of(context).textTheme.displayLarge;
    final minuteTextStyle = Theme.of(context).textTheme.displaySmall;
    final secondTextStyle = Theme.of(context).textTheme.titleLarge;
    const op = 0.0;

    final isDarkMode = ref.watch(appPreferenceNotifierProvider).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: () => _clockRainGame.reset(),
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
            onPressed: ref
                .read(appPreferenceNotifierProvider.notifier)
                .toggleBrightness,
            icon: isDarkMode
                ? const Icon(Icons.light_mode_outlined)
                : const Icon(Icons.dark_mode_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Place at the bottom layer just to measure the size of the widget.
          Opacity(
            key: measureHoursKey,
            opacity: op,
            child: TextMeasureWidget(
              '03',
              style: hourTextStyle,
              padding: 32,
            ),
          ),
          Opacity(
            key: measureMinutesKey,
            opacity: op,
            child: TextMeasureWidget(
              '02',
              style: minuteTextStyle,
              padding: 16,
            ),
          ),
          Opacity(
            key: measureSecondsKey,
            opacity: op,
            child: TextMeasureWidget(
              '01',
              style: secondTextStyle,
            ),
          ),
          GameWidget<ClockRainGame>(
            game: _clockRainGame,
            overlayBuilderMap: {
              'clockRainScreen': (context, game) => ClockRainScreen(game: game),
            },
            initialActiveOverlays: const ['clockRainScreen'],
          ),
        ],
      ),
    );
  }
}
