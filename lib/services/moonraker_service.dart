import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MoonrakerService {
  final Dio _dio;
  late WebSocketChannel? _websocket;
  final String baseUrl;

  MoonrakerService({required this.baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<Map<String, dynamic>> getPrinterInfo() async {
    try {
      final response = await _dio.get('/printer/info');
      return response.data;
    } catch (e) {
      throw Exception('Errore nel recupero delle informazioni della stampante: $e');
    }
  }

  Future<Map<String, dynamic>> getPrinterStatus() async {
    try {
      final response = await _dio.get('/printer/objects/query?objects=print_stats,toolhead,heater_bed');
      return response.data;
    } catch (e) {
      throw Exception('Errore nel recupero dello stato della stampante: $e');
    }
  }

  void connectWebSocket() {
    final wsUrl = baseUrl.replaceFirst('http', 'ws') + '/websocket';
    _websocket = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  void disconnectWebSocket() {
    _websocket?.sink.close();
    _websocket = null;
  }

  Stream get printerUpdates => _websocket!.stream;

  Future<void> sendGcode(String command) async {
    try {
      await _dio.post('/printer/gcode/script', data: {'script': command});
    } catch (e) {
      throw Exception('Errore nell\'invio del comando G-code: $e');
    }
  }
}
