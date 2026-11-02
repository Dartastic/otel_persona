// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_persona_suppression.dart';

const _tracerName = 'dartastic_otel_libs_persona';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class PersonaResult {
  /// Creates a result.
  const PersonaResult({
    this.itemCount,
    this.inquiryId,
    this.inquiryStatus,
    this.templateId,
    this.checksRun,
    this.governmentIdCheck,
    this.documentClass,
    this.fraudScore,
    this.workflowKind,
    this.country,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `inquiry.id`.
  final String? inquiryId;

  /// `created` / `pending` / `completed` / `approved` / `declined` /
  /// `expired` / `failed` / `needs_review`.
  final String? inquiryStatus;

  /// `template_id` (`itmpl_*`) — distinct verification flow.
  final String? templateId;

  /// Number of checks run on this inquiry (Persona's billing dim —
  /// each check is metered).
  final int? checksRun;

  /// `passed` / `failed` / `not_applicable` for the document check.
  final String? governmentIdCheck;

  /// `dl` / `passport` / `id_card` / `residence_permit` — document
  /// class detected.
  final String? documentClass;

  /// Persona's composite fraud score (0-100 when surfaced).
  final int? fraudScore;

  /// `kyc` / `kyb` / `aml` / `phone_check` / `email_check` /
  /// `database_verification`.
  final String? workflowKind;

  /// ISO 3166 country of subject.
  final String? country;

  /// `Persona-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class PersonaCallResult<T> {
  /// Creates a call result.
  const PersonaCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final PersonaResult? result;
}

/// Wraps a Persona API call in a CLIENT span. [operation] is one of
/// `inquiries.list`, `inquiries.get`, `inquiries.create`,
/// `inquiries.submit`, `inquiries.approve`, `inquiries.decline`,
/// `accounts.list`, `accounts.get`, `cases.list`, `cases.update`,
/// `reports.list`, `workflows.list`, `webhooks.list`,
/// `webhooks.create`.
Future<T> tracedPersona<T>({
  required String operation,
  required Future<PersonaCallResult<T>> Function() invoke,
}) async {
  if (personaInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'persona',
    'rpc.method': operation,
    'persona.operation': operation,
  };

  final span = _tracer().startSpan(
    'persona $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'persona.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.inquiryId != null) {
        extras.add(OTelAPI.attributeString(
          'persona.inquiry.id',
          r.result!.inquiryId!,
        ));
      }
      if (r.result!.inquiryStatus != null) {
        extras.add(OTelAPI.attributeString(
          'persona.inquiry.status',
          r.result!.inquiryStatus!,
        ));
        if (r.result!.inquiryStatus == 'declined' ||
            r.result!.inquiryStatus == 'failed' ||
            r.result!.inquiryStatus == 'expired') {
          span.setStatus(
            SpanStatusCode.Error,
            'Persona inquiry ${r.result!.inquiryStatus}',
          );
        }
      }
      if (r.result!.templateId != null) {
        extras.add(OTelAPI.attributeString(
          'persona.template.id',
          r.result!.templateId!,
        ));
      }
      if (r.result!.checksRun != null) {
        extras.add(OTelAPI.attributeInt(
          'persona.checks_run',
          r.result!.checksRun!,
        ));
      }
      if (r.result!.governmentIdCheck != null) {
        extras.add(OTelAPI.attributeString(
          'persona.government_id.check',
          r.result!.governmentIdCheck!,
        ));
      }
      if (r.result!.documentClass != null) {
        extras.add(OTelAPI.attributeString(
          'persona.document.class',
          r.result!.documentClass!,
        ));
      }
      if (r.result!.fraudScore != null) {
        extras.add(OTelAPI.attributeInt(
          'persona.fraud_score',
          r.result!.fraudScore!,
        ));
      }
      if (r.result!.workflowKind != null) {
        extras.add(OTelAPI.attributeString(
          'persona.workflow.kind',
          r.result!.workflowKind!,
        ));
      }
      if (r.result!.country != null) {
        extras.add(OTelAPI.attributeString(
          'persona.country',
          r.result!.country!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'persona.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Persona HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
