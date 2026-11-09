// upupa_frontend/lib/features/collections/services/realtime_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class RealtimeService {
  static const String baseUrl = 'http://localhost:8090/api/v1';

  StreamSubscription<String>? _subscription;

  void connect({
    required Function(String event, String collection, dynamic data) onEvent,
    required Function(String error) onError,
  }) {
    disconnect();

    try {
      final uri = Uri.parse('$baseUrl/realtime');
      final request = http.Request('GET', uri);

      request.headers['Accept'] = 'text/event-stream';

      http.Client()
          .send(request)
          .then((response) {
            if (response.statusCode == 200) {
              String currentEvent = 'message';

              _subscription = response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())
                  .listen(
                    (line) {
                      if (line.isEmpty) return;

                      if (line.startsWith('event:')) {
                        currentEvent = line.substring(6).trim();
                      } else if (line.startsWith('data:')) {
                        final rawData = line.substring(5).trim();
                        try {
                          final decodedData = jsonDecode(rawData);
                          if (decodedData is Map &&
                              decodedData.containsKey('event')) {
                            final ev = decodedData['event'] ?? currentEvent;
                            final ch = decodedData['channel'] ?? '';
                            final dt = decodedData['data'];
                            onEvent(ev, ch, dt);
                          }
                        } catch (e) {
                          log('Error decoding SSE data: $e');
                        }
                      }
                    },
                    onError: (err) {
                      onError(err.toString());
                    },
                    onDone: () {
                      log('SSE connection closed.');
                    },
                  );
            } else {
              onError(
                'Failed to connect to SSE: status ${response.statusCode}',
              );
            }
          })
          .catchError((err) {
            onError(err.toString());
          });
    } catch (e) {
      onError(e.toString());
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }
}
