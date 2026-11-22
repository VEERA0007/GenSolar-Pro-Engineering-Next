import 'package:flutter_test/flutter_test.dart';
import 'package:gensolar_pro_engineering/core/providers.dart';

void main() {
  group('project workflow dependency propagation', () {
    test('a survey edit marks its dependent design sections for review', () {
      final current = <String, Object?>{
        'survey': <String, Object?>{'roofLengthM': 30},
        'pv': <String, Object?>{'moduleCount': 80},
        'yield': <String, Object?>{'annualKwh': 12000},
        'electrical': <String, Object?>{'stringCount': 4},
        'structural': <String, Object?>{'effectiveAreaM2': 600},
        'bom': <String, Object?>{'moduleCount': 80},
        'battery': <String, Object?>{'nominalKwh': 20},
      };

      final next = markDownstreamReview(current, 'survey');

      for (final key in ['pv', 'yield', 'electrical', 'structural', 'bom']) {
        expect((next[key] as Map)['needsReview'], isTrue, reason: '$key must be reviewed');
      }
      expect((next['survey'] as Map)['needsReview'], isNull);
      expect((next['battery'] as Map)['needsReview'], isNull);
      expect((next['pv'] as Map)['moduleCount'], 80, reason: 'Existing values are preserved for review');
    });

    test('a BOM update marks procurement and delivery for review', () {
      final next = markDownstreamReview({
        'procurement': <String, Object?>{'vendor': 'Sample supplier'},
        'delivery': <String, Object?>{'construction': <bool>[true, false]},
        'cad': <String, Object?>{'drawingRevision': 'A'},
      }, 'bom');

      expect((next['procurement'] as Map)['needsReview'], isTrue);
      expect((next['delivery'] as Map)['needsReview'], isTrue);
      expect(next['cad'], {'drawingRevision': 'A'});
    });

    test('empty downstream sections are not created by invalidation', () {
      final next = markDownstreamReview({'pv': <String, Object?>{}}, 'survey');
      expect(next.keys.toList(), ['pv']);
      expect(next['pv'], isEmpty);
    });

    test('design changes make exported CAD and DPR snapshots stale', () {
      final next = markDownstreamReview({
        'cad': <String, Object?>{'fileExtension': 'dxf'},
        'report': <String, Object?>{'fileExtension': 'pdf'},
        'pv': <String, Object?>{'moduleCount': 72},
      }, 'pv');

      expect((next['cad'] as Map)['needsReview'], isTrue);
      expect((next['report'] as Map)['needsReview'], isTrue);
      expect((next['pv'] as Map)['needsReview'], isNull);
    });

    test('a CAD revision makes the previous DPR snapshot stale', () {
      final next = markDownstreamReview({
        'cad': <String, Object?>{'revision': 'B'},
        'report': <String, Object?>{'revision': 'A'},
      }, 'cad');

      expect((next['report'] as Map)['needsReview'], isTrue);
      expect((next['cad'] as Map)['needsReview'], isNull);
    });

    test('project metadata edits can flag the source section itself', () {
      final next = markSectionReview({
        'survey': <String, Object?>{'latitude': 17.3, 'longitude': 78.4},
        'pv': <String, Object?>{'moduleCount': 80},
      }, 'survey', reason: 'Site location changed.');

      expect((next['survey'] as Map)['needsReview'], isTrue);
      expect((next['survey'] as Map)['latitude'], 17.3);
      expect((next['survey'] as Map)['reviewReason'], 'Site location changed.');
      expect((next['pv'] as Map)['needsReview'], isNull);
    });


    test('project status is derived from current saved workflow evidence', () {
      expect(deriveProjectStatus({}), 'Draft');
      expect(deriveProjectStatus({'survey': <String, Object?>{'roofLengthM': 30}}), 'In progress');
      expect(
        deriveProjectStatus({
          for (final key in ['survey', 'pv', 'yield', 'electrical', 'structural', 'bom', 'cad', 'report'])
            key: <String, Object?>{'savedAtUtc': '2026-11-22T00:00:00Z'},
        }),
        'In progress',
        reason: 'Procurement and delivery evidence are required for workflow completion.',
      );
      final ready = <String, Object?>{
        for (final key in ['survey', 'pv', 'yield', 'electrical', 'structural', 'bom', 'procurement', 'delivery', 'cad', 'report'])
          key: <String, Object?>{'savedAtUtc': '2026-11-22T00:00:00Z'},
      };
      expect(deriveProjectStatus(ready), 'Engineering ready');
      (ready['pv'] as Map<String, Object?>)['needsReview'] = true;
      expect(deriveProjectStatus(ready), 'In progress');
    });

    test('the input project map is not mutated', () {
      final original = <String, Object?>{'pv': <String, Object?>{'moduleCount': 40}};
      markDownstreamReview(original, 'survey');
      expect((original['pv'] as Map).containsKey('needsReview'), isFalse);
    });
  });
}
