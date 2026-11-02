// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_persona/otel_persona.dart';

/// Traces Persona calls with OpenTelemetry.
///
/// `otel_persona` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Persona call in
/// [tracedPersona]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'persona-example');

  // Wraps a Persona API call in a CLIENT span.
  final personaId = await tracedPersona<String>(
    operation: 'inquiries.create',
    invoke: () async {
      // Make the Persona call here, then report what it returned.
      const id = 'persona_8f3a2c';
      return const PersonaCallResult(
          value: id,
          result: PersonaResult(
              itemCount: 3,
              inquiryId: 'inquiry.id',
              inquiryStatus: 'created',
              templateId: 'template_id',
              checksRun: 1,
              governmentIdCheck: 'passed',
              documentClass: 'dl',
              fraudScore: 1,
              workflowKind: 'kyc',
              country: 'example',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedPersona inquiries.create returned $personaId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPersonaInstrumentationAsync.
  await runWithoutPersonaInstrumentationAsync(
    () => tracedPersona<String>(
      operation: 'inquiries.create',
      invoke: () async {
        const id = 'persona_8f3a2c';
        return const PersonaCallResult(
            value: id,
            result: PersonaResult(
                itemCount: 3,
                inquiryId: 'inquiry.id',
                inquiryStatus: 'created',
                templateId: 'template_id',
                checksRun: 1,
                governmentIdCheck: 'passed',
                documentClass: 'dl',
                fraudScore: 1,
                workflowKind: 'kyc',
                country: 'example',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
