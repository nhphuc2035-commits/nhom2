import 'package:flutter_test/flutter_test.dart';
import 'package:app_hot_toc/main.dart';

void main() {
  testWidgets('AppHotToc login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppHotToc());

    // Verify that the login screen loads with branding and buttons
    expect(find.text('Tiệm Hớt Tóc'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Số điện thoại / Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}
