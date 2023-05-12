import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PictureRecorder Test'),
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FutureBuilder(
            future: getPattern(),
            builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
              return CustomPaint(
                painter: _SamplePainter(snapshot.data),
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<ui.Image> getPattern() async {
  var pictureRecorder = ui.PictureRecorder();
  Canvas patternCanvas = Canvas(pictureRecorder);

  const colorList = [
    Colors.black,
    Color(0xffff7f7f),
    Color(0xffff7fff),
    Color(0xff7f7fff),
    Color(0xff7fbfff),
    Color(0xff7fffff),
    Color(0xff7fff7f),
    Color(0xffffff7f),
    Color(0xffffbf7f)
  ];

  final paintList = colorList
      .map((e) => Paint()
        ..color = e
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = false)
      .toList();

  paintList.asMap().forEach((index, element) => patternCanvas.drawPoints(
      ui.PointMode.points, [Offset(index % 3, index / 3)], paintList[index]));

  final aPatternPicture = pictureRecorder.endRecording();

  return aPatternPicture.toImage(3, 3);
}

class _SamplePainter extends CustomPainter {
  final ui.Image? aPattern;

  _SamplePainter(this.aPattern);

  @override
  void paint(Canvas canvas, Size size) {
    if (aPattern != null) {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..isAntiAlias = false
        ..shader = ImageShader(aPattern!, TileMode.repeated, TileMode.repeated,
            Matrix4.identity().storage);

      var path = Path();
      path.moveTo(size.width / 2, size.height / 5);
      path.lineTo(size.width / 4, size.height / 5 * 4);
      path.lineTo(size.width / 4 * 3, size.height / 5 * 4);
      path.close();

      canvas.drawPath(path, paint);

      //Depending on the environment, the Offset(0, 0) point of the pattern is not displayed.
      canvas.drawImage(
          aPattern!, Offset(size.width / 2, size.height / 2), Paint());
    }
  }

  @override
  bool shouldRepaint(_SamplePainter oldDelegate) {
    return aPattern != oldDelegate.aPattern;
  }
}
