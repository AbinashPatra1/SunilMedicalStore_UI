import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/app.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
