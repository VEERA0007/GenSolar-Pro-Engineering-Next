import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gensolar_pro_engineering/app/gensolar_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GenSolar Pro Engineering application boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GenSolarApp()));
    await tester.pump();

    expect(find.byType(GenSolarApp), findsOneWidget);
    expect(find.text('GenSolar Pro'), findsWidgets);
  });
}
