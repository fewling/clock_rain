import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/clock_rain_game.dart';
import 'clock_rain_screen.dart';

/// Use these keys to obtain the `currentContext`, in turn the `Size` of the widget.
/// So that we can match the size of the [FallingBodyWidget] and [FallingBodyComponent].
final measureSecondsKey = GlobalKey();
final measureMinutesKey = GlobalKey();
final measureHoursKey = GlobalKey();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _clockRainGame = ClockRainGame();
  static const _op = 0.0;

  @override
  Widget build(BuildContext context) {
    final hourTextStyle = Theme.of(context).textTheme.displayLarge;
    final minuteTextStyle = Theme.of(context).textTheme.displaySmall;
    final secondTextStyle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      body: Stack(
        children: [
          // Place at the bottom layer just to measure the size of the widget.
          Opacity(
            key: measureHoursKey,
            opacity: _op,
            child: TextMeasureWidget(
              '03',
              style: hourTextStyle,
              padding: 32,
            ),
          ),
          Opacity(
            key: measureMinutesKey,
            opacity: _op,
            child: TextMeasureWidget(
              '02',
              style: minuteTextStyle,
              padding: 16,
            ),
          ),
          Opacity(
            key: measureSecondsKey,
            opacity: _op,
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
