import 'package:flutter_test/flutter_test.dart';
import 'package:gensolar_pro_engineering/core/engineering/roof_polygon.dart';

void main() {
  group('RoofPolygon', () {
    test('calculates area and perimeter for a rectangle', () {
      final polygon = RoofPolygon.fromCoordinateText('0, 0\\n30, 0\\n30, 20\\n0, 20');
      expect(polygon.areaM2, 600);
      expect(polygon.perimeterM, 100);
      expect(polygon.vertices, hasLength(4));
    });

    test('calculates area independent of winding direction', () {
      final polygon = RoofPolygon.fromCoordinateText('0,0\\n0,20\\n30,20\\n30,0');
      expect(polygon.areaM2, 600);
      expect(polygon.signedAreaM2, lessThan(0));
    });

    test('supports concave roof outlines and point containment', () {
      final polygon = RoofPolygon.fromCoordinateText('0,0\\n10,0\\n10,4\\n4,4\\n4,10\\n0,10');
      expect(polygon.areaM2, 64);
      expect(polygon.contains(const RoofPoint(2, 8)), isTrue);
      expect(polygon.contains(const RoofPoint(8, 8)), isFalse);
    });

    test('rejects fewer than three points', () {
      expect(() => RoofPolygon.fromCoordinateText('0,0\\n10,0'), throwsArgumentError);
    });

    test('rejects duplicate adjacent points', () {
      expect(() => RoofPolygon.fromCoordinateText('0,0\\n10,0\\n10,0\\n0,10'), throwsArgumentError);
    });

    test('rejects zero-area and collinear outlines', () {
      expect(() => RoofPolygon.fromCoordinateText('0,0\\n5,0\\n10,0'), throwsArgumentError);
    });

    test('rejects self-intersecting bow-tie outlines', () {
      expect(() => RoofPolygon.fromCoordinateText('0,0\\n10,10\\n0,10\\n10,0'), throwsArgumentError);
    });

    test('rejects a repeated closing point', () {
      expect(() => RoofPolygon.fromCoordinateText('0,0\\n10,0\\n10,10\\n0,0'), throwsArgumentError);
    });

    test('rejects malformed and non-finite coordinates', () {
      expect(() => RoofPolygon.fromCoordinateText('0,0\\nabc,4\\n3,5'), throwsFormatException);
      expect(() => RoofPolygon.fromCoordinateText('0,0\\nNaN,4\\n3,5'), throwsFormatException);
    });
  });
}
