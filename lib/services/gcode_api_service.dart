import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class GcodeApiService {
  // URL base dell'API, da configurare in base all'ambiente
  final String baseUrl;
  
  // Costruttore con URL predefinito o personalizzato
  GcodeApiService({this.baseUrl = 'http://localhost:5000/api'});

  /// Verifica che l'API sia disponibile
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Errore durante la verifica della salute dell\'API: $e');
      return false;
    }
  }

  /// Genera il G-code da un file STL
  /// 
  /// [stlFileData] - Dati binari del file STL
  /// [fileName] - Nome del file STL
  /// [params] - Parametri di slicing
  Future<Map<String, dynamic>> sliceStl({
    required Uint8List stlFileData,
    required String fileName,
    required Map<String, dynamic> params,
  }) async {
    try {
      // Preparazione del file multipart
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/slice'));
      
      // Aggiunta del file STL alla richiesta
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        stlFileData,
        filename: fileName,
        contentType: MediaType('application', 'octet-stream'),
      ));
      
      // Aggiunta dei parametri di slicing alla richiesta
      request.fields['params'] = jsonEncode(params);
      
      // Invio della richiesta
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Errore durante lo slicing: ${response.body}');
      }
    } catch (e) {
      print('Errore durante lo slicing: $e');
      return {
        'success': false,
        'message': 'Errore durante lo slicing: $e',
      };
    }
  }

  /// Genera un'anteprima del G-code
  Future<Map<String, dynamic>> previewGcode({
    required Uint8List stlFileData,
    required String fileName,
    required Map<String, dynamic> params,
  }) async {
    try {
      // Preparazione del file multipart
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/preview'));
      
      // Aggiunta del file STL alla richiesta
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        stlFileData,
        filename: fileName,
        contentType: MediaType('application', 'octet-stream'),
      ));
      
      // Aggiunta dei parametri di slicing alla richiesta
      request.fields['params'] = jsonEncode(params);
      
      // Invio della richiesta
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Errore durante la generazione dell\'anteprima: ${response.body}');
      }
    } catch (e) {
      print('Errore durante la generazione dell\'anteprima: $e');
      return {
        'success': false,
        'message': 'Errore durante la generazione dell\'anteprima: $e',
      };
    }
  }

  /// Scarica il G-code generato
  Future<Uint8List?> downloadGcode(String gcodeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/download/$gcodeId'));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Errore durante il download del G-code: ${response.body}');
      }
    } catch (e) {
      print('Errore durante il download del G-code: $e');
      return null;
    }
  }

  /// Costruisce i parametri di slicing dai valori dell'UI
  static Map<String, dynamic> buildSlicingParams({
    required double layerHeight,
    required int nozzleTemp,
    required int bedTemp,
    required int printSpeed,
    required int infillDensity,
    required String infillPattern,
    required double retractionDistance,
    required double retractionSpeed,
    bool generateSupport = false,
    bool enableBrim = false,
    int brimWidth = 0,
  }) {
    return {
      'layer_height': layerHeight,
      'nozzle_temp': nozzleTemp,
      'bed_temp': bedTemp,
      'print_speed': printSpeed,
      'infill_density': infillDensity,
      'infill_pattern': infillPattern,
      'retraction_distance': retractionDistance,
      'retraction_speed': retractionSpeed,
      'generate_support': generateSupport,
      'enable_brim': enableBrim,
      'brim_width': brimWidth,
    };
  }
}
