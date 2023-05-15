import 'package:flutter/material.dart';

class FakeDevicePixelRatio extends StatelessWidget {
  final num fakeDevicePixelRatio;
  final Widget child;

  const FakeDevicePixelRatio(
      {Key? key, required this.fakeDevicePixelRatio, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio =
        WidgetsBinding.instance.window.devicePixelRatio;

    final ratio = fakeDevicePixelRatio / devicePixelRatio;

    return FractionallySizedBox(
        widthFactor: 1 / ratio,
        heightFactor: 1 / ratio,
        child: Transform.scale(scale: ratio, child: child));
  }
}
