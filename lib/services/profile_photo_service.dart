import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_service.dart';

class ProfilePhotoService {
  static Future<String> upload(XFile photo) async {
    final email = await AuthService.getEmail();
    final safeId = email.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final bytes = await photo.readAsBytes();
    final reference = FirebaseStorage.instance
        .ref()
        .child('profile_photos/$safeId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await reference.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await reference.getDownloadURL();
    await AuthService.saveProfilePhotoUrl(url);
    return url;
  }
}