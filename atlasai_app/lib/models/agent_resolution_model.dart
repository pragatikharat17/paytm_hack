class WorkflowStep {
  final String agent;
  final String action;
  final String status;
  final String detail;

  WorkflowStep({
    required this.agent,
    required this.action,
    required this.status,
    required this.detail,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      agent: json['agent'] ?? '',
      action: json['action'] ?? '',
      status: json['status'] ?? 'DONE',
      detail: json['detail'] ?? '',
    );
  }
}

class RefundInfo {
  final String refundId;
  final String paymentId;
  final double amount;
  final String status;
  final String reason;
  final String? gatewayRefundRef;

  RefundInfo({
    required this.refundId,
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.reason,
    this.gatewayRefundRef,
  });

  factory RefundInfo.fromJson(Map<String, dynamic> json) {
    return RefundInfo(
      refundId: json['refund_id'] ?? '',
      paymentId: json['payment_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      gatewayRefundRef: json['gateway_refund_ref'],
    );
  }
}

class ApprovalInfo {
  final String approvalId;
  final String complaintId;
  final double amount;
  final String reason;
  final double riskScore;
  final String status;

  ApprovalInfo({
    required this.approvalId,
    required this.complaintId,
    required this.amount,
    required this.reason,
    required this.riskScore,
    required this.status,
  });

  factory ApprovalInfo.fromJson(Map<String, dynamic> json) {
    return ApprovalInfo(
      approvalId: json['approval_id'] ?? '',
      complaintId: json['complaint_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
    );
  }
}

class TicketInfo {
  final String ticketId;
  final String? complaintId;
  final String priority;
  final String category;
  final String subject;
  final String status;

  TicketInfo({
    required this.ticketId,
    this.complaintId,
    required this.priority,
    required this.category,
    required this.subject,
    required this.status,
  });

  factory TicketInfo.fromJson(Map<String, dynamic> json) {
    return TicketInfo(
      ticketId: json['ticket_id'] ?? '',
      complaintId: json['complaint_id'],
      priority: json['priority'] ?? 'MEDIUM',
      category: json['category'] ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'OPEN',
    );
  }
}

class AgentResolution {
  final String outcome;
  final String finalMessage;
  final String? translatedMessage;
  final String language;
  final double? confidence;
  final String? paymentId;
  final RefundInfo? refund;
  final ApprovalInfo? approval;
  final TicketInfo? ticket;
  final List<dynamic> toolsCalled;
  final List<WorkflowStep> workflowSteps;
  final String? audioBase64;
  final String? audioFormat;

  AgentResolution({
    required this.outcome,
    required this.finalMessage,
    this.translatedMessage,
    required this.language,
    required this.confidence,
    this.paymentId,
    this.refund,
    this.approval,
    this.ticket,
    this.toolsCalled = const [],
    this.workflowSteps = const [],
    this.audioBase64,
    this.audioFormat,
  });

  factory AgentResolution.fromJson(Map<String, dynamic> json) {
    return AgentResolution(
      outcome: json['outcome'] ?? 'INFO_ONLY',
      finalMessage: json['final_message'] ?? '',
      translatedMessage: json['translated_message'],
      language: json['language'] ?? 'en',
      confidence: (json['confidence'] as num?)?.toDouble(),
      paymentId: json['payment_id'],
      refund: json['refund'] != null
          ? RefundInfo.fromJson(json['refund'])
          : null,
      approval: json['approval'] != null
          ? ApprovalInfo.fromJson(json['approval'])
          : null,
      ticket: json['ticket'] != null
          ? TicketInfo.fromJson(json['ticket'])
          : null,
      toolsCalled: json['tools_called'] ?? [],
      workflowSteps:
          (json['workflow_steps'] as List<dynamic>?)
              ?.map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      audioBase64: json['audio_base64'],
      audioFormat: json['audio_format'],
    );
  }
}
