import 'package:flame_forge2d/flame_forge2d.dart' hide Transform;
import 'package:flutter/material.dart';

import '../game/clock_rain_game.dart';

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
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Stack(
          children: [
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
    Key? key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
    required this.body,
    this.style,
  }) : super(key: key);

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
        child: SizedBox(
          width: width,
          height: height,
          child: FallingTextWidget(
            msg.toString().padLeft(2, '0'),
            style: style,
            backgroundColor: body.backgroundColor,
            onTap: () => body.onTap(),
          ),
        ),
      ),
    );
  }
}

class FallingTextWidget extends StatelessWidget {
  const FallingTextWidget(
    this.msg, {
    super.key,
    this.style,
    this.backgroundColor,
    this.onTap,
  });

  final String msg;
  final TextStyle? style;
  final Color? backgroundColor;

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
          padding: const EdgeInsets.all(8.0),
          child: Text(msg, style: style),
        ),
      ),
    );
  }
}
