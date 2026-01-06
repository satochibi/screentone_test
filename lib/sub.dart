import 'dart:math';
import 'package:flutter/rendering.dart';

class SliverGridDelegateWithSnappedMaxCrossAxisExtentVariableAspect
    extends SliverGridDelegate {
  final double maxCrossAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final List<double> childAspectRatios; // 各セルのアスペクト比

  SliverGridDelegateWithSnappedMaxCrossAxisExtentVariableAspect({
    required this.maxCrossAxisExtent,
    required this.childAspectRatios,
    this.crossAxisSpacing = 0,
    this.mainAxisSpacing = 0,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final usableWidth = constraints.crossAxisExtent - crossAxisSpacing;
    int crossAxisCount =
        (usableWidth / (maxCrossAxisExtent + crossAxisSpacing)).ceil();

    // 整数化したセル幅
    final totalSpacing = (crossAxisCount - 1) * crossAxisSpacing;
    final rawCellWidth = (usableWidth - totalSpacing) / crossAxisCount;
    final cellWidth = rawCellWidth.floorToDouble();

    // 各セルごとに高さを計算するため、SliverGridRegularTileLayout は使えない
    // ここでは SliverGridDelegate に対応するカスタム Layout を返す必要がある
    return _SliverGridVariableHeightLayout(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      cellWidth: cellWidth,
      childAspectRatios: childAspectRatios,
    );
  }

  @override
  bool shouldRelayout(
      covariant SliverGridDelegateWithSnappedMaxCrossAxisExtentVariableAspect
          oldDelegate) {
    return oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.childAspectRatios != childAspectRatios;
  }
}

class _SliverGridVariableHeightLayout extends SliverGridLayout {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double cellWidth;
  final List<double> childAspectRatios;

  const _SliverGridVariableHeightLayout({
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.cellWidth,
    required this.childAspectRatios,
  });

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final row = index ~/ crossAxisCount;
    final column = index % crossAxisCount;

    // 各セルの高さ = width / 個別アスペクト比
    final aspectRatio = childAspectRatios[index];
    final cellHeight = (cellWidth / aspectRatio).floorToDouble();

    final crossAxisOffset = column * (cellWidth + crossAxisSpacing);
    // mainAxisOffset は前の行の最大高さを足す必要がある
    double mainAxisOffset = 0;
    for (int r = 0; r < row; r++) {
      int start = r * crossAxisCount;
      int end = start + crossAxisCount;
      double maxHeight = 0;
      for (int i = start; i < end && i < childAspectRatios.length; i++) {
        maxHeight =
            max(maxHeight, (cellWidth / childAspectRatios[i]).floorToDouble());
      }
      mainAxisOffset += maxHeight + mainAxisSpacing;
    }

    return SliverGridGeometry(
      scrollOffset: mainAxisOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: cellHeight,
      crossAxisExtent: cellWidth,
    );
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    // 適宜簡易的に全件返す
    return childAspectRatios.length - 1;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    return 0;
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount == 0) return 0;

    final rowCount = (childCount / crossAxisCount).ceil();
    double maxOffset = 0;

    for (int row = 0; row < rowCount; row++) {
      // その行の最大高さを取得
      int start = row * crossAxisCount;
      int end = min(start + crossAxisCount, childAspectRatios.length);
      double maxHeight = 0;
      for (int i = start; i < end; i++) {
        double cellHeight = (cellWidth / childAspectRatios[i]).floorToDouble();
        maxHeight = max(maxHeight, cellHeight);
      }
      maxOffset += maxHeight;
    }

    // mainAxisSpacing を加算
    maxOffset += max((rowCount - 1), 0) * mainAxisSpacing;

    return maxOffset;
  }
}
