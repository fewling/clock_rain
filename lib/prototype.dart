import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Transform;
import 'package:flutter/material.dart';

final streams =
    List.generate(50, (index) => StreamController<ButtonWidgetArg>());
final measureKey = GlobalKey();

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeWidget(),
      theme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        brightness: Brightness.dark,
      ),
    );
  }
}

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // To measure the size of the button
          Opacity(
            opacity: 0,
            child: ElevatedButton(
              key: measureKey,
              onPressed: null,
              child: const Text('Flutter Widget'),
            ),
          ),
          Opacity(
            // Set to (>0) to see the underlying BodyComponents
            opacity: 0.0,
            child: GameWidget(game: MyGame()),
          ),
          for (final streamController in streams)
            StreamBuilder(
                stream: streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final arg = snapshot.data as ButtonWidgetArg;
                    return LogoWidget(
                      left: arg.left,
                      top: arg.top,
                      angle: arg.angle,
                    );
                  }
                  return const SizedBox();
                }),
        ],
      ),
    );
  }
}

class MyGame extends Forge2DGame with MouseMovementDetector {
  final btnBodies = <LogoBody>[];

  @override
  Future<void> onLoad() async {
    final boundaries = createBoundaries(this);
    addAll(boundaries);

    final renderObj = measureKey.currentContext?.findRenderObject();
    final syze = renderObj?.semanticBounds.size ?? Size.zero;
    final scale = screenToWorld(Vector2(syze.width / 2, syze.height / 2));
    // print('syze: $syze, scale: $scale');

    for (var i = 0; i < streams.length; i++) {
      final x = size.x * Random().nextDouble();
      btnBodies.add(LogoBody(Vector2(x, 10), scale.x, scale.y));
    }
    addAll(btnBodies);
  }

  List<Wall> createBoundaries(Forge2DGame game) {
    final topLeft = Vector2.zero();
    final bottomRight = game.screenToWorld(game.camera.viewport.effectiveSize);
    final topRight = Vector2(bottomRight.x, topLeft.y);
    final bottomLeft = Vector2(topLeft.x, bottomRight.y);

    return [
      Wall(topLeft, topRight),
      Wall(topRight, bottomRight),
      Wall(bottomRight, bottomLeft),
      Wall(bottomLeft, topLeft),
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (var i = 0; i < streams.length; i++) {
      final stream = streams[i];
      final body = btnBodies[i].body;

      final renderObj = measureKey.currentContext?.findRenderObject();
      final syze = renderObj?.semanticBounds.size ?? Size.zero;
      final scale = screenToWorld(Vector2(syze.width / 2, syze.height / 2));
      final pos = worldToScreen(body.worldCenter - scale);
      final arg = ButtonWidgetArg(
        left: pos.x,
        top: pos.y,
        angle: body.angle,
      );
      stream.add(arg);
    }
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);

    for (final b in btnBodies) {
      final body = b.body;
      final dist = body.position.distanceTo(info.eventPosition.game);
      if (dist < 50) {
        body.applyForce((info.eventPosition.game - body.position) * 300);
      }
    }
  }
}

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape, friction: 0.3);
    final bodyDef = BodyDef(
      userData: this, // To be able to determine object in collision
      position: Vector2.zero(),
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class LogoBody extends BodyComponent {
  final Vector2 _position;
  final double hx;
  final double hy;
  LogoBody(this._position, this.hx, this.hy);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      angularVelocity: 3,
      position: _position,
      type: BodyType.dynamic,
    );
    final body = world.createBody(bodyDef);

    final shape = PolygonShape()..setAsBoxXY(hx, hy);
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      restitution: 0.8,
      friction: 0.2,
    );
    body.createFixture(fixtureDef);
    return body;
  }
}

class LogoWidget extends StatelessWidget {
  final double left;
  final double top;
  final double angle;

  const LogoWidget({
    Key? key,
    required this.left,
    required this.top,
    required this.angle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Flutter Widget'),
        ),
      ),
    );
  }
}

class ButtonWidgetArg {
  final double left;
  final double top;
  final double angle;

  ButtonWidgetArg({
    required this.left,
    required this.top,
    required this.angle,
  });
}



/// I want to create an effect that make various Flutter widget exhibit physics behavior.
/// Thus I chose to use Flame and FlameForge2D.
/// 
/// This app consists of two main layers under the Stack widget.
/// The bottom layer is [MyGame], a [Forge2DGame].
/// The upper layers are a list of [ButtonWidgets].
/// 
/// There is a global variable `streams` storing a list of [StreamController].
/// Each `streamController` is associated with a [ButtonWidget].
/// 
/// In [MyGame], 
/// In `onLoad()`, I loaded a list of [ButtonBody] by the length of [streams].
/// In `update()`, I collect the position and angle of each [ButtonBody] and send them to the corresponding [StreamController].
/// 
/// When the [StreamBuilder] receives the data, it will update the position and angle of the [ButtonWidget].