// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_persona/otel_persona.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_persona-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('inquiries.submit records template + checks + fraud', () async {
    await tracedPersona<String>(
      operation: 'inquiries.submit',
      invoke: () async => const PersonaCallResult(
        value: 'ok',
        result: PersonaResult(
          inquiryId: 'inq-1',
          inquiryStatus: 'completed',
          templateId: 'itmpl_abc',
          checksRun: 5,
          governmentIdCheck: 'passed',
          documentClass: 'passport',
          fraudScore: 12,
          workflowKind: 'kyc',
          country: 'US',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('persona inquiries.submit')!);
    expect(a['persona.inquiry.id'], 'inq-1');
    expect(a['persona.template.id'], 'itmpl_abc');
    expect(a['persona.checks_run'], 5);
    expect(a['persona.government_id.check'], 'passed');
    expect(a['persona.document.class'], 'passport');
    expect(a['persona.fraud_score'], 12);
  });

  test('declined sets span error', () async {
    await tracedPersona<String>(
      operation: 'inquiries.decline',
      invoke: () async => const PersonaCallResult(
        value: 'ok',
        result: PersonaResult(inquiryStatus: 'declined'),
      ),
    );
    expect(
      spans.findSpanByName('persona inquiries.decline')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutPersonaInstrumentationAsync(() async {
      await tracedPersona<String>(
        operation: 'inquiries.list',
        invoke: () async => const PersonaCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('persona '), isEmpty);
  });
}
