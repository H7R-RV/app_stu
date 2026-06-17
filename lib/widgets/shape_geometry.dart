import 'dart:math' as math;

import '../models/doc_element.dart';

/// Returns the outline of a shape as normalised points (0..1, y-down) that can
/// be scaled onto any box — used identically by the Flutter painter and the
/// PDF exporter so shapes look the same on screen and in print.
List<List<double>> shapePoints(ShapeKind kind) {
  switch (kind) {
    case ShapeKind.triangle:
      return [
        [0.5, 0.0],
        [1.0, 1.0],
        [0.0, 1.0],
      ];
    case ShapeKind.diamond:
      return [
        [0.5, 0.0],
        [1.0, 0.5],
        [0.5, 1.0],
        [0.0, 0.5],
      ];
    case ShapeKind.pentagon:
      return _regular(5);
    case ShapeKind.hexagon:
      return _regular(6);
    case ShapeKind.star:
      return _star(5, 0.5, 0.21);
    case ShapeKind.arrow:
      return [
        [0.0, 0.32],
        [0.6, 0.32],
        [0.6, 0.1],
        [1.0, 0.5],
        [0.6, 0.9],
        [0.6, 0.68],
        [0.0, 0.68],
      ];
  }
}

List<List<double>> _regular(int sides) {
  final pts = <List<double>>[];
  for (var i = 0; i < sides; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / sides;
    pts.add([0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a)]);
  }
  return pts;
}

List<List<double>> _star(int points, double outer, double inner) {
  final pts = <List<double>>[];
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = -math.pi / 2 + i * math.pi / points;
    pts.add([0.5 + r * math.cos(a), 0.5 + r * math.sin(a)]);
  }
  return pts;
}
