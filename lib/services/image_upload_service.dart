import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class _CloudinaryConfig {
  static const cloudName = 'ufoxojxe';
  static const uploadPreset = 'campus_connect';
  static const uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

/// Handles picking images from camera/gallery and uploading to Cloudinary.
/// No server required — uses Cloudinary's unsigned upload API (free tier).
class ImageUploadService {
  static final _picker = ImagePicker();

  // ── Pick

  /// Opens camera or gallery. Returns the [XFile], or null if cancelled.
  static Future<XFile?> pickImage(String source) async {
    final src = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
    return _picker.pickImage(
      source: src,
      imageQuality: 75, // compress to ~75% — keeps file size small
      maxWidth: 1080,
    );
  }

  // ── Upload

  /// Uploads [file] to Cloudinary and returns the secure HTTPS download URL.
  /// [folder] is the Cloudinary folder to organise uploads (e.g. 'lost_found').
  /// Throws a [Exception] if the upload fails.
  static Future<String> uploadFile({
    required XFile file,
    String folder = 'lost_found',
  }) async {
    final uri = Uri.parse(_CloudinaryConfig.uploadUrl);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      if (url != null) return url;
    }

    throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}');
  }

  // ── Pick + Upload

  /// Convenience: pick then upload in one call.
  /// Returns the Cloudinary URL, or null if the user cancelled.
  static Future<String?> pickAndUpload({
    required String source,
    String folder = 'lost_found',
  }) async {
    final file = await pickImage(source);
    if (file == null) return null;
    return uploadFile(file: file, folder: folder);
  }
}
