import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:screentone_test/sub.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WatchLocalPage(),
    );
  }
}

class WatchLocalPage extends StatelessWidget {
  WatchLocalPage({super.key});

  final aspectRatios = [
    4 / 3,
    16 / 9,
    1 / 1,
    16 / 9,
    4 / 3,
    1 / 1,
    4 / 3,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch'),
        bottomOpacity: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: EdgeInsets.all(12),
          gridDelegate:
              SliverGridDelegateWithSnappedMaxCrossAxisExtentVariableAspect(
            maxCrossAxisExtent: 320,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatios: aspectRatios,
          ),
          itemCount: aspectRatios.length,
          itemBuilder: (context, index) {
            return PixelSnap(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 4.0),
                ),
                child: Center(
                  child: ArtBoard(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ArtBoard extends StatefulWidget {
  const ArtBoard({super.key});

  @override
  ArtBoardState createState() => ArtBoardState();
}

class ArtBoardState extends State<ArtBoard> {
  StrokesModel strokes = StrokesModel();
  final repaint = ValueNotifier<int>(0);

  void refresh(ValueNotifier<int> repaint) {
    repaint.value++;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: GestureDetector(
        onPanDown: (details) {
          strokes.onPress(details.localPosition);
          refresh(repaint);
        },
        onPanUpdate: (details) {
          strokes.drawing(details.localPosition);
          refresh(repaint);
        },
        onPanEnd: (details) {
          refresh(repaint);
        },
        child: FutureBuilder(
          future: strokes.screentoneImage(),
          builder: (context, snapshot) {
            final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
            return CustomPaint(
              painter: _DrawingPainter(strokes, devicePixelRatio),
            );
          },
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final StrokesModel strokes;
  final double devicePixelRatio;

  _DrawingPainter(this.strokes, this.devicePixelRatio);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.all.isEmpty) return;

    final dpr = devicePixelRatio;

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    var path = Path();

    print(size);

    final matrix = Matrix4.identity();

    strokes.all.forEach((Stroke stroke) {
      if (stroke.screentoneImage != null) {
        paint = Paint()
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..shader = ImageShader(
            stroke.screentoneImage!,
            TileMode.repeated,
            TileMode.repeated,
            matrix.storage,
          );
      }

      stroke._points.asMap().forEach((int index, Offset anOffset) {
        if (index == 0) {
          path.moveTo(anOffset.dx, anOffset.dy);
        } else {
          path.lineTo(anOffset.dx, anOffset.dy);
        }
      });
    });

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return true;
  }
}

Future<ui.Image> getPattern() async {
  final data = await rootBundle.load('img/rough2x2.png');
  final bytes = data.buffer.asUint8List();
  return decodeImageFromList(bytes);
}

class StrokesModel {
  List<Stroke> _strokes = [];

  get all => _strokes;

  Future<void> screentoneImage() async {
    var strokesCopy = List<Stroke>.from(_strokes);
    for (var stroke in strokesCopy) {
      stroke.screentoneImage ??= await getPattern();
    }
  }

  void onPress(Offset offset) {
    _strokes.add(Stroke()..add(offset));
  }

  void drawing(Offset offset) {
    _strokes.last.add(offset);
  }

  void clear() {
    _strokes = [];
  }
}

class Stroke {
  final List<Offset> _points = [];
  ui.Image? screentoneImage;

  Stroke();

  add(Offset offset) {
    _points.add(offset);
  }

  all() {
    return _points;
  }
}

/// 子ウィジェットのレイアウト結果をいったん受け取り、
/// サイズと描画位置を必ず整数論理ピクセルに丸めてから描画する
class PixelSnap extends SingleChildRenderObjectWidget {
  const PixelSnap({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPixelSnap();
  }
}

class _RenderPixelSnap extends RenderProxyBox {
  /// サイズを整数化
  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);

      final snappedSize = Size(
        child!.size.width.floorToDouble(),
        child!.size.height.floorToDouble(),
      );

      size = constraints.constrain(snappedSize);
    } else {
      size = constraints.smallest;
    }
  }

  /// 位置を整数化
  @override
  void paint(PaintingContext context, Offset offset) {
    final snappedOffset = Offset(
      offset.dx.floorToDouble(),
      offset.dy.floorToDouble(),
    );

    if (child != null) {
      context.paintChild(child!, snappedOffset);
    }
  }
}
