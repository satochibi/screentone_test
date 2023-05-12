import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'dart:async';

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
  final ByteData data = await rootBundle.load("img/screentone.png");
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
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
