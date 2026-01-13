import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>?> pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return null;

    final String fileName = '${DateTime.now().toIso8601String()}_${image.name}';
    final storageRef = FirebaseStorage.instance.ref().child('user_photos').child(fileName);

    try {
      String downloadUrl;
      Uint8List imageBytes;

      if (kIsWeb) {
        // For web, upload bytes directly
        imageBytes = await image.readAsBytes();
        final uploadTask = storageRef.putData(imageBytes);
        final snapshot = await uploadTask.whenComplete(() => {});
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        // For mobile, upload the file
        final uploadTask = storageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() => {});
        downloadUrl = await snapshot.ref.getDownloadURL();
        imageBytes = await image.readAsBytes(); // Read bytes for displaying in UI
      }
      
      return {
        'downloadUrl': downloadUrl,
        'imageBytes': imageBytes,
      };

    } catch (e) {
      // print('Error uploading image: $e'); // Removed print statement
      return null;
    }
  }
}
