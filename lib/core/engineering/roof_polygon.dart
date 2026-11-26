import 'dart:math' as math;

/// A simple, non-self-intersecting roof outline in a local metre coordinate system.
/// The first and last vertices are implicitly connected.
class RoofPoint {
  const RoofPoint(this.x, this.y);

  final double x;
  final double y;
}

class RoofPolygon {
  RoofPolygon._(this.vertices);

  final List<RoofPoint> vertices;

  factory RoofPolygon.fromCoordinateText(String source) {
    final points = <RoofPoint>[];
    for (final rawLine in source.split(RegExp(r'[\\r\\n;]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parts = line.split(RegExp(r'[,\\s]+')).where((part) => part.isNotEmpty).toList();
      if (parts.length != 2) {
        throw FormatException('Each vertex must contain exactly two values: X, Y.');
      }
      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);
      if (x == null || y == null || !x.isFinite || !y.isFinite) {
        throw FormatException('Vertex coordinates must be finite numbers.');
      }
      points.add(RoofPoint(x, y));
    }
    return RoofPolygon(points);
  }

  factory RoofPolygon(List<RoofPoint> input) {
    final points = List<RoofPoint>.unmodifiable(input);
    if (points.length > 3 && _same(points.first, points.last)) {
      throw ArgumentError('Do not repeat the first vertex at the end; the boundary is closed automatically.');
    }
    if (points.length < 3) throw ArgumentError('A roof boundary needs at least three vertices.');
    for (var i = 0; i < points.length; i++) {
      if (_same(points[i], points[(i + 1) % points.length])) {
        throw ArgumentError('Adjacent roof vertices must be different.');
      }
    }
    final polygon = RoofPolygon._(points);
    if (polygon.areaM2 <= 1e-8) throw ArgumentError('Roof boundary area must be greater than zero.');
    if (polygon._hasSelfIntersection()) throw ArgumentError('Roof boundary must not cross itself.');
    return polygon;
  }

  double get signedAreaM2 {
    var sum = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum / 2;
  }

  double get areaM2 => signedAreaM2.abs();

  double get perimeterM {
    var sum = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      sum += math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    }
    return sum;
  }

  bool contains(RoofPoint point) {
    var inside = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final a = vertices[i];
      final b = vertices[j];
      final crosses = (a.y > point.y) != (b.y > point.y) &&
          point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  bool _hasSelfIntersection() {
    for (var i = 0; i < vertices.length; i++) {
      final a1 = vertices[i];
      final a2 = vertices[(i + 1) % vertices.length];
      for (var j = i + 1; j < vertices.length; j++) {
        if (j == i || j == (i + 1) % vertices.length || (j + 1) % vertices.length == i) continue;
        final b1 = vertices[j];
        final b2 = vertices[(j + 1) % vertices.length];
        if (_segmentsIntersect(a1, a2, b1, b2)) return true;
      }
    }
    return false;
  }

  static bool _same(RoofPoint a, RoofPoint b) =>
      (a.x - b.x).abs() < 1e-9 && (a.y - b.y).abs() < 1e-9;

  static bool _segmentsIntersect(RoofPoint a, RoofPoint b, RoofPoint c, RoofPoint d) {
    const epsilon = 1e-9;
    double orientation(RoofPoint p, RoofPoint q, RoofPoint r) =>
        (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
    bool onSegment(RoofPoint p, RoofPoint q, RoofPoint r) =>
        q.x >= math.min(p.x, r.x) - epsilon && q.x <= math.max(p.x, r.x) + epsilon &&
        q.y >= math.min(p.y, r.y) - epsilon && q.y <= math.max(p.y, r.y) + epsilon;
    final o1 = orientation(a, b, c);
    final o2 = orientation(a, b, d);
    final o3 = orientation(c, d, a);
    final o4 = orientation(c, d, b);
    if ((o1 > epsilon && o2 < -epsilon || o1 < -epsilon && o2 > epsilon) &&
        (o3 > epsilon && o4 < -epsilon || o3 < -epsilon && o4 > epsilon)) return true;
    if (o1.abs() <= epsilon && onSegment(a, c, b)) return true;
    if (o2.abs() <= epsilon && onSegment(a, d, b)) return true;
    if (o3.abs() <= epsilon && onSegment(c, a, d)) return true;
    if (o4.abs() <= epsilon && onSegment(c, b, d)) return true;
    return false;
  }
}
