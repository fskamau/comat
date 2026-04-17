import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadItemImage(File imageFile) async {
    try {
      // Generate a unique file name using current timestamp
      String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';

      // Define the storage path
      Reference ref = _storage.ref().child('item_images/$fileName');

      // Upload file to Firebase Storage
      UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Return the download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // Return null if upload fails
      return null;
    }
  }
}