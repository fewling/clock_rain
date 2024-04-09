import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame_audio/audio_pool.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Timer;
import 'package:flutter/material.dart';

import '../screens/home.dart';

const _shrinkRate = 0.9;

class ClockRainGame extends Forge2DGame {
  ClockRainGame() : super(gravity: Vector2(0, 30));
  late Timer _timer;
  late AudioPool _pool;

  var _second = -1;
  var _minute = -1;
  var _hour = -1;

  final secondBodies = <FallingBodyComponent>[];
  final minuteBodies = <FallingBodyComponent>[];
  final hourBodies = <FallingBodyComponent>[];

  var _materialColorIndex = 0;

  Wall? wallL;
  Wall? wallR;
  Ground? ground;

  @override
  FutureOr<void> onLoad() async {
    _pool = await FlameAudio.createPool(
      'falling_sfx.mp3',
      minPlayers: 1,
      maxPlayers: 1,
    );

    return super.onLoad();
  }

  @override
  Future<void> onAttach() async {
    super.onAttach();
    await createBoundaries();

    final current = DateTime.now();
    final nextSec = DateTime(
      current.year,
      current.month,
      current.day,
      current.hour,
      current.minute,
      current.second + 1,
    );

    final diff = nextSec.difference(current);
    await Future.delayed(diff);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _timer = timer;
        _tick();
      },
    );
  }

  @override
  void onRemove() {
    _timer.cancel();
    super.onRemove();
  }

  Future<void> _tick() async {
    final current = DateTime.now();
    final currentSec = current.second;
    final currentMin = current.minute;
    final currentHour = current.hour;

    final oneSecPassed = _second != currentSec;
    final oneMinPassed = _minute != currentMin;
    final oneHourPassed = _hour != currentHour;

    if (oneMinPassed) _switchColor();

    final backgroundColor =
        Colors.primaries[_materialColorIndex].withOpacity(0.7);

    if (oneSecPassed) {
      _second = currentSec;

      await _createSecondBody(backgroundColor);
    }

    if (oneMinPassed) {
      _minute = currentMin;

      for (final fallingBody in secondBodies) {
        if (fallingBody.time.minute == currentMin) continue;
        fallingBody.shrinkRate = _shrinkRate;
      }

      await _createMinuteBody(backgroundColor);
    }

    if (oneHourPassed) {
      _hour = currentHour;

      for (final fallingBody in minuteBodies) {
        if (fallingBody.time.hour == currentHour) continue;
        fallingBody.shrinkRate = _shrinkRate;
      }

      for (final fallingBody in hourBodies) {
        if (fallingBody.time.hour == currentHour) continue;
        fallingBody.shrinkRate = _shrinkRate;
      }

      await _createHourBody(backgroundColor);
    }
  }

  Future<void> _createSecondBody(Color backgroundColor) async {
    final renderObj = measureSecondsKey.currentContext?.findRenderObject();
    final syze = renderObj?.semanticBounds.size ?? Size.zero;
    final scale = screenToWorld(Vector2(syze.width / 2, syze.height / 2));

    final fallingBody = FallingBodyComponent(
      pos: Vector2(wallR!.end.x - scale.x, -scale.y),
      w: scale.x,
      h: scale.y,
      time: DateTime.now(),
      type: FallingBodyType.seconds,
      angularVelocity: -Random().nextDouble() * pi * 2,
      backgroundColor: backgroundColor,
      pool: _pool,
    );
    await add(fallingBody);
    secondBodies.add(fallingBody);
  }

  Future<void> _createMinuteBody(Color backgroundColor) async {
    final renderObj = measureMinutesKey.currentContext?.findRenderObject();
    final hrRenderObj = measureHoursKey.currentContext?.findRenderObject();

    final syze = renderObj?.semanticBounds.size ?? Size.zero;
    final hrSyze = hrRenderObj?.semanticBounds.size ?? Size.zero;

    final scale = screenToWorld(Vector2(syze.width / 2, syze.height / 2));
    final hrScale = screenToWorld(Vector2(hrSyze.width / 2, hrSyze.height / 2));

    final hrBlockWidth = hrScale.x * 2;

    final fallingBody = FallingBodyComponent(
      pos: Vector2(hrBlockWidth + scale.x + 0.2, -scale.y),
      w: scale.x,
      h: scale.y,
      time: DateTime.now(),
      type: FallingBodyType.minutes,
      backgroundColor: backgroundColor,
      pool: _pool,
    );
    await add(fallingBody);
    minuteBodies.add(fallingBody);
  }

  Future<void> _createHourBody(Color backgroundColor) async {
    final renderObj = measureHoursKey.currentContext?.findRenderObject();
    final syze = renderObj?.semanticBounds.size ?? Size.zero;
    final scale = screenToWorld(Vector2(syze.width / 2, syze.height / 2));

    final fallingBody = FallingBodyComponent(
      pos: Vector2(scale.x, -scale.y),
      w: scale.x,
      h: scale.y,
      time: DateTime.now(),
      type: FallingBodyType.hour,
      backgroundColor: backgroundColor,
      pool: _pool,
    );
    await add(fallingBody);
    hourBodies.add(fallingBody);
  }

  void _switchColor() {
    _materialColorIndex += 1;
    if (_materialColorIndex >= Colors.primaries.length) {
      _materialColorIndex = 0;
    }
  }

  Future<void> createBoundaries() async {
    final topLeft = Vector2.zero();
    final bottomRight = screenToWorld(camera.viewport.effectiveSize);
    final topRight = Vector2(bottomRight.x, topLeft.y);
    final bottomLeft = Vector2(topLeft.x, bottomRight.y);

    wallL = Wall(topLeft, bottomLeft);
    wallR = Wall(topRight, bottomRight);
    ground = Ground(bottomLeft, bottomRight);

    await addAll([
      wallL!,
      wallR!,
      ground!,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final allBodies = [...secondBodies, ...minuteBodies, ...hourBodies];

    for (final fallingBody in allBodies) {
      if (fallingBody.shrinkRate == 1) continue;

      fallingBody.w *= fallingBody.shrinkRate;
      fallingBody.h *= fallingBody.shrinkRate;

      for (final fixture in fallingBody.body.fixtures) {
        fixture.shape = PolygonShape()
          ..setAsBoxXY(
            fallingBody.w,
            fallingBody.h,
          );
      }
    }

    secondBodies.removeWhere((e) {
      final tooSmall = e.w < 0.2 || e.h < 0.2;
      if (tooSmall) e.removeFromParent();
      return tooSmall;
    });
    minuteBodies.removeWhere((e) {
      final tooSmall = e.w < 0.2 || e.h < 0.2;
      if (tooSmall) e.removeFromParent();
      return tooSmall;
    });
    hourBodies.removeWhere((e) {
      final tooSmall = e.w < 0.2 || e.h < 0.2;
      if (tooSmall) e.removeFromParent();
      return tooSmall;
    });
  }

  Future<void> reset() async {
    for (final fallingBody in [
      ...secondBodies,
      ...minuteBodies,
      ...hourBodies
    ]) {
      fallingBody.shrinkRate = _shrinkRate;
    }

    _second = -1;
    _minute = -1;
    _hour = -1;

    wallL?.removeFromParent();
    wallR?.removeFromParent();
    ground?.removeFromParent();
    await createBoundaries();
  }
}

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.3,
      filter: Filter()..groupIndex = -1,
    );
    final bodyDef = BodyDef(
      userData: this, // To be able to determine object in collision
      position: Vector2.zero(),
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class Ground extends Wall {
  Ground(super.start, super.end);
}

enum FallingBodyType {
  seconds,
  minutes,
  hour,
}

class FallingBodyComponent extends BodyComponent with ContactCallbacks {
  final Vector2 pos;
  final DateTime time;
  final FallingBodyType type;
  final double angularVelocity;
  final Color backgroundColor;
  double w;
  double h;
  double shrinkRate;
  AudioPool pool;

  FallingBodyComponent({
    required this.pos,
    required this.time,
    required this.type,
    required this.w,
    required this.h,
    required this.backgroundColor,
    required this.pool,
    this.angularVelocity = 0,
    this.shrinkRate = 1,
  });

  var _isContacted = false;

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    if (other is FallingBodyComponent || other is Ground) {
      if (!_isContacted) {
        _isContacted = true;
        final vol = min(body.linearVelocity.length, 200) / 200;
        pool.start(volume: vol);
      }
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      userData: this,
      angularVelocity: angularVelocity,
      position: pos,
      type: BodyType.dynamic,
    );

    final friction = type == FallingBodyType.seconds ? 0.2 : 0.3;

    final restitution = switch (type) {
      FallingBodyType.seconds => 0.3,
      FallingBodyType.minutes => 0.2,
      FallingBodyType.hour => 0.1,
    };

    final density = switch (type) {
      FallingBodyType.seconds => 10,
      FallingBodyType.minutes => 10,
      FallingBodyType.hour => 10,
    };

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()..setAsBoxXY(w, h);
    final fixtureDef = FixtureDef(
      shape,
      density: density.toDouble(),
      restitution: restitution,
      friction: friction,
    );
    body.createFixture(fixtureDef);
    renderBody = false;
    paint = Paint()..color = backgroundColor;

    add(FallingTextComponent(parent: this));

    return body;
  }

  @override
  void onRemove() {
    world.destroyBody(body);
    super.onRemove();
  }

  void onTap() {
    // final mag = body.mass * 50;
    // final xDirection = Random().nextBool() ? 1 : -1;
    // final impulse = Vector2(mag * xDirection, -mag);
    // body.applyLinearImpulse(impulse);

    shrinkRate = _shrinkRate;
  }
}

class FallingTextComponent extends TextComponent {
  @override
  final FallingBodyComponent parent;

  FallingTextComponent({
    super.text,
    super.textRenderer,
    super.anchor,
    required this.parent,
  });

  @override
  FutureOr<void> onLoad() {
    final msg = switch (parent.type) {
      FallingBodyType.seconds => parent.time.second,
      FallingBodyType.minutes => parent.time.minute,
      FallingBodyType.hour => parent.time.hour,
    };
    text = msg.toString().padLeft(2, '0');
    anchor = Anchor.center;

    return super.onLoad();
  }

  // @override
  // void update(double dt) {
  //   super.update(dt);
  //   size = Vector2(parent.w, parent.h);
  //   scale = Vector2(parent.w / 15, parent.h / 15);

  //   textRenderer = TextPaint(
  //     style: const TextStyle(
  //       color: Colors.white,
  //     ),
  //   );
  // }
}
