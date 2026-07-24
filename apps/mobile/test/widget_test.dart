import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smeda_hebat/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: SmedaHebatApp(),
    ));
    expect(find.text('SMEDA HEBAT'), findsOneWidget);
  });
}
