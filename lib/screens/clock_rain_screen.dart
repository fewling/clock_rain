import 'package:flame_forge2d/flame_forge2d.dart' hide Transform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/clock_rain_game.dart';
import '../services/preference_provider.dart';

class ClockRainScreen extends StatefulWidget {
  const ClockRainScreen({
    super.key,
    required this.game,
  });

  final ClockRainGame game;

  @override
  State<ClockRainScreen> createState() => _ClockRainScreenState();
}

class _ClockRainScreenState extends State<ClockRainScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(days: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;

    const textColor = Colors.white;
    final hourTextStyle = txtTheme.displayLarge?.copyWith(color: textColor);
    final minuteTextStyle = txtTheme.headlineLarge?.copyWith(color: textColor);
    final secondTextStyle = txtTheme.labelLarge?.copyWith(color: textColor);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              onTap: widget.game.reset,
              title: const Text('Reset'),
            ),
            Consumer(
              builder: (context, ref, child) {
                final isDarkMode = ref.watch(
                  appPreferenceNotifierProvider.select(
                    (pref) => pref.isDarkMode,
                  ),
                );

                return ListTile(
                  leading: isDarkMode
                      ? const Icon(Icons.light_mode_outlined)
                      : const Icon(Icons.dark_mode_outlined),
                  onTap: ref
                      .read(appPreferenceNotifierProvider.notifier)
                      .toggleBrightness,
                  title: Text(isDarkMode ? 'Light mode' : 'Dark mode'),
                );
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final upright = ref.watch(
                  appPreferenceNotifierProvider.select(
                    (pref) => pref.uprightText,
                  ),
                );

                return SwitchListTile(
                  title: const Text('Upright text'),
                  secondary: AnimatedRotation(
                    turns: upright ? 0 : (1 / 4),
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.text_rotation_none_outlined),
                  ),
                  value: upright,
                  onChanged: (_) => ref
                      .read(appPreferenceNotifierProvider.notifier)
                      .toggleUprightText(),
                );
              },
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  // if user swipe from left edge --> open drawer
                  if (details.delta.dx > 30) {
                    Scaffold.of(context).openDrawer();
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            for (final body in widget.game.secondBodies)
              _buildBodyWidget(body, secondTextStyle),
            for (final body in widget.game.minuteBodies)
              _buildBodyWidget(body, minuteTextStyle),
            for (final body in widget.game.hourBodies)
              _buildBodyWidget(body, hourTextStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyWidget(FallingBodyComponent body, TextStyle? textStyle) {
    // halfSize == (0.5w, 0.5h), so technically should be quarterSize.
    final bodySize = Vector2(body.w, body.h);
    final halfSize = body.body.worldCenter - bodySize;
    final offset = widget.game.worldToScreen(halfSize);

    return FallingBodyWidget(
      left: offset.x,
      top: offset.y,
      width: widget.game.worldToScreen(bodySize).x * 2,
      height: widget.game.worldToScreen(bodySize).y * 2,
      angle: body.angle,
      style: textStyle,
      body: body,
    );
  }
}

class FallingBodyWidget extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;

  final TextStyle? style;

  final FallingBodyComponent body;

  const FallingBodyWidget({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
    required this.body,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final msg = switch (body.type) {
      FallingBodyType.seconds => body.time.second,
      FallingBodyType.minutes => body.time.minute,
      FallingBodyType.hour => body.time.hour,
    };

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Card(
          margin: EdgeInsets.zero,
          color: body.backgroundColor.withOpacity(1),
          child: SizedBox(
            width: width,
            height: height,
            child: InkWell(
              onTap: body.onTap,
              child: Center(
                child: Consumer(
                  builder: (_, ref, child) {
                    final upright = ref.watch(
                      appPreferenceNotifierProvider.select(
                        (value) => value.uprightText,
                      ),
                    );
                    return Transform.rotate(
                      angle: upright ? -angle : 0,
                      child: child,
                    );
                  },
                  child: Text(
                    msg.toString().padLeft(2, '0'),
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TextMeasureWidget extends StatelessWidget {
  const TextMeasureWidget(
    this.msg, {
    super.key,
    this.style,
    this.backgroundColor,
    this.onTap,
    this.padding = 8,
  });

  final String msg;
  final TextStyle? style;
  final Color? backgroundColor;
  final double padding;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Text(msg, style: style),
        ),
      ),
    );
  }
}
