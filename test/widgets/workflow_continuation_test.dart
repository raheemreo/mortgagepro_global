// test/widgets/workflow_continuation_test.dart
//
// PHASE-3: Tests for WorkflowContinuationCard.
// Verifies:
//   - Country-tool filtering returns correct tools for USA, UK, and EU.
//   - Tools NOT in a country's list don't appear for that country.
//   - CalculatorDraft is correctly formed from calculation values.
//
// Run: flutter test test/widgets/workflow_continuation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mortgagepro_global/shared/widgets/workflow_continuation_card.dart';
import 'package:mortgagepro_global/models/calculator_draft.dart';

void main() {
  // Helper: build the card in a minimal testable widget tree.
  Widget buildCard({
    required String country,
    required String countryPath,
    CalculatorDraft? draft,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WorkflowContinuationCard(
            country: country,
            countryPath: countryPath,
            draft: draft,
          ),
        ),
      ),
    );
  }

  group('WorkflowContinuationCard — country-tool filtering', () {
    testWidgets('USA shows property tax, affordability, and DTI', (tester) async {
      await tester.pumpWidget(buildCard(country: 'USA', countryPath: 'usa'));
      await tester.pump();

      expect(find.text('Property Tax'), findsOneWidget);
      expect(find.text('Affordability'), findsOneWidget);
      expect(find.text('DTI Calculator'), findsOneWidget);
    });

    testWidgets('USA does NOT show Notary Fee (EU-only tool)', (tester) async {
      await tester.pumpWidget(buildCard(country: 'USA', countryPath: 'usa'));
      await tester.pump();

      expect(find.text('Notary Fee'), findsNothing);
    });

    testWidgets('UK shows SDLT and LTV but not property tax (USA-specific)', (tester) async {
      await tester.pumpWidget(buildCard(country: 'UK', countryPath: 'uk'));
      await tester.pump();

      expect(find.text('SDLT Calculator'), findsOneWidget);
      expect(find.text('LTV Calculator'), findsOneWidget);
      // USA-specific tool — should not appear for UK
      expect(find.text('Property Tax'), findsNothing);
    });

    testWidgets('EUROPE shows Notary Fee', (tester) async {
      await tester.pumpWidget(buildCard(country: 'EUROPE', countryPath: 'europe'));
      await tester.pump();

      expect(find.text('Notary Fee'), findsOneWidget);
    });

    testWidgets('EUROPE does NOT show SDLT (UK-specific)', (tester) async {
      await tester.pumpWidget(buildCard(country: 'EUROPE', countryPath: 'europe'));
      await tester.pump();

      expect(find.text('SDLT Calculator'), findsNothing);
    });

    testWidgets('Unknown country renders nothing (empty tools list)', (tester) async {
      await tester.pumpWidget(buildCard(country: 'XX', countryPath: 'xx'));
      await tester.pump();

      // SizedBox.shrink means no text at all
      expect(find.text('Continue Your Mortgage Planning'), findsNothing);
    });
  });

  group('WorkflowContinuationCard — title rendered when tools exist', () {
    testWidgets('Shows "Continue Your Mortgage Planning" header for USA', (tester) async {
      await tester.pumpWidget(buildCard(country: 'USA', countryPath: 'usa'));
      await tester.pump();

      expect(find.text('Continue Your Mortgage Planning'), findsOneWidget);
    });
  });

  group('CalculatorDraft — model correctness', () {
    test('copyWith preserves unchanged fields', () {
      const draft = CalculatorDraft(
        loanAmount: 360000,
        propertyPrice: 450000,
        interestRate: 6.82,
        loanTermYears: 30,
        country: 'USA',
        currency: 'USD',
        downPayment: 90000,
      );

      final updated = draft.copyWith(interestRate: 7.0);

      expect(updated.interestRate, 7.0);
      // All other fields preserved
      expect(updated.loanAmount, 360000);
      expect(updated.propertyPrice, 450000);
      expect(updated.loanTermYears, 30);
      expect(updated.country, 'USA');
      expect(updated.currency, 'USD');
      expect(updated.downPayment, 90000);
    });

    test('CalculatorDraft allows all nullable fields to be null', () {
      const draft = CalculatorDraft(
        country: 'UK',
        currency: 'GBP',
      );

      expect(draft.loanAmount, isNull);
      expect(draft.propertyPrice, isNull);
      expect(draft.interestRate, isNull);
      expect(draft.loanTermYears, isNull);
      expect(draft.downPayment, isNull);
    });

    test('Down payment calculation consistency', () {
      const homePrice = 450000.0;
      const downPct = 20.0;
      const expectedDownPayment = homePrice * downPct / 100; // 90000

      const draft = CalculatorDraft(
        loanAmount: 360000,
        propertyPrice: 450000,
        interestRate: 6.82,
        loanTermYears: 30,
        country: 'USA',
        currency: 'USD',
        downPayment: 90000,
      );

      expect(draft.downPayment, expectedDownPayment);
      expect(
        draft.loanAmount,
        closeTo(homePrice - expectedDownPayment, 0.01),
      );
    });
  });
}
