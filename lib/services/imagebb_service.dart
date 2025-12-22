import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class ImageBBService {
  static const String apiKey = '6f0ead1d22839466563ab662627b87b6';
  static const String uploadUrl = 'https://api.imgbb.com/1/upload';
  final Dio _dio = Dio();

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = path.basename(imageFile.path);
      final formData = FormData.fromMap({
        'key': apiKey,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      print('ImageBB upload error: $e');
      return null;
    }
  }
}

