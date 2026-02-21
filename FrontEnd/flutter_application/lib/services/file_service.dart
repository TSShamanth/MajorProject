import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class FileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> pickAndUploadFile({String folder = 'mentorship_attachments'}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      PlatformFile file = result.files.first;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      Reference ref = _storage.ref().child(folder).child(fileName);

      String downloadUrl;
      if (kIsWeb) {
        if (file.bytes == null) return null;
        UploadTask task = ref.putData(file.bytes!);
        TaskSnapshot snapshot = await task;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        if (file.path == null) return null;
        UploadTask task = ref.putFile(File(file.path!));
        TaskSnapshot snapshot = await task;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }
}
