// upupa_frontend/lib/features/logs/models/request_log.dart
class RequestLog {
  final int id;
  final String method;
  final String url;
  final int status;
  final String ip;
  final String referer;
  final DateTime createdAt;

  RequestLog({
    required this.id,
    required this.method,
    required this.url,
    required this.status,
    required this.ip,
    required this.referer,
    required this.createdAt,
  });

  factory RequestLog.fromJson(Map<String, dynamic> json) {
    return RequestLog(
      id: json['id'] ?? 0,
      method: json['method'] ?? 'GET',
      url: json['url'] ?? '',
      status: json['status'] ?? 200,
      ip: json['ip'] ?? 'N/A',
      referer: json['referer'] ?? 'N/A',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
