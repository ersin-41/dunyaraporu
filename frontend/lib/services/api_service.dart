import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CANLI: Hugging Face sunucusu bağlandı
  final String baseUrl = 'https://ersn-dunyaraporu-ai-backend.hf.space'; 

  Future<List<dynamic>> fetchLatestNews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/news/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('news')) {
          return data['news'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Haber hatası: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> generateScenario(String newsContent) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scripts/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'news_content': newsContent}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var scriptData = data['script_data'];
        if (scriptData is String) {
          return json.decode(scriptData);
        }
        return scriptData as Map<String, dynamic>;
      }
      throw Exception('Senaryo hatası: ${response.statusCode}');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<String> generateAudio(String text, String projectName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-audio'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'project_name': projectName,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['file_path'];
    }
    throw Exception('Ses hatası');
  }

  Future<String> renderVideo(
    Map<String, dynamic> scenario,
    String audioPath,
    String projectName,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/render-video'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'script_data': scenario,
        'audio_path': audioPath,
        'project_name': projectName,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['video_path'];
    }
    throw Exception('Video render hatası');
  }

  String getFullUrl(String relativePath) {
    if (relativePath.contains('http')) return relativePath;
    // Backend'deki yolu temizler ve baseUrl ile birleştirir
    final cleanPath = relativePath.replaceAll('\\', '/').replaceAll('backend/', '');
    return '$baseUrl/$cleanPath';
  }
}

