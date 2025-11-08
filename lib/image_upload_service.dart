import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgbbService {
  static const String apiKey = "e506a5d58e499d6cabd5d7c8638d690b"; // 🔑 letak API Key sini

  static Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);
      final imageUrl = data['data']['url'] as String;
      return imageUrl; 
    } else {
      print("❌ Upload failed: ${response.statusCode}");
      return null;
    }
  }
}
