import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';

/// Service for managing file operations and storage
class FileManagementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _loadingMessage = '';

  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get loadingMessage => _loadingMessage;

  /// Upload multiple files
  Future<List<FileMeta>> uploadFiles(
    List<PlatformFile> files, {
    String? folderId,
  }) async {
    if (files.isEmpty) return [];

    setUploadState(true, 'Uploading files...');
    final results = <FileMeta>[];
    int completed = 0;

    try {
      for (final file in files) {
        final result = await _uploadSingleFile(file, folderId: folderId);
        if (result != null) {
          results.add(result);
        }
        completed++;
        _updateUploadProgress(completed / files.length);
      }
      return results;
    } finally {
      setUploadState(false);
    }
  }

  /// Upload a single file
  Future<FileMeta?> _uploadSingleFile(
    PlatformFile file, {
    String? folderId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Upload to Firebase Storage
      final storageRef = _getStorageReference(file.name, folderId, user.uid);
      final uploadTask = await storageRef.putData(file.bytes!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create Firestore document
      final docRef = _getFirestoreReference(folderId, user.uid);
      final fileMeta = FileMeta(
        id: docRef.id,
        name: file.name,
        size: file.size,
        url: downloadUrl,
        type: file.extension ?? '',
        uploadedAt: DateTime.now(),
        folderId: folderId,
      );

      await docRef.set(fileMeta.toMap());
      return fileMeta;
    } catch (e) {
      debugPrint('Error uploading file ${file.name}: $e');
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(FileMeta file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Delete from Storage
      final storagePath = _getStoragePath(file, user.uid);
      try {
        await _storage.ref(storagePath).delete();
      } catch (e) {
        debugPrint('Storage deletion failed (might be okay): $e');
      }

      // Delete from Firestore
      final docRef = _getFileDocumentReference(file, user.uid);
      await docRef.delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Delete a folder and all its contents
  Future<bool> deleteFolder(Folder folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Get all files in the folder
      final filesSnapshot =
          await _firestore
              .collection('users/${user.uid}/folders/${folder.id}/files')
              .get();

      // Delete each file
      for (final doc in filesSnapshot.docs) {
        final file = FileMeta.fromDoc(doc);
        await deleteFile(file);
      }

      // Delete the folder document
      await _firestore
          .collection('users/${user.uid}/folders')
          .doc(folder.id)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting folder: $e');
      return false;
    }
  }

  /// Move a file to a different folder
  Future<bool> moveFile(FileMeta file, String? targetFolderId) async {
    if (file.folderId == targetFolderId) return true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final batch = _firestore.batch();

      // Create new document in target location
      final newDocRef = _getFirestoreReference(targetFolderId, user.uid);
      final newFileData = {
        'name': file.name,
        'size': file.size,
        'type': file.type,
        'url': file.url,
        'uploadedAt': Timestamp.fromDate(file.uploadedAt),
        'folderId': targetFolderId,
      };
      batch.set(newDocRef, newFileData);

      // Delete old document
      final oldDocRef = _getFileDocumentReference(file, user.uid);
      batch.delete(oldDocRef);

      // Commit the batch
      await batch.commit();

      return true;
    } catch (e) {
      debugPrint('Error moving file: $e');
      return false;
    }
  }

  /// Create a new folder
  Future<Folder?> createFolder(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final folder = Folder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      );

      await _firestore
          .collection('users/${user.uid}/folders')
          .doc(folder.id)
          .set({
            'name': folder.name,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return folder;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return null;
    }
  }

  /// Rename a folder
  Future<bool> renameFolder(Folder folder, String newName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final cleanName = newName.trim();
      if (cleanName.isEmpty || cleanName == folder.name) return false;

      await _firestore
          .collection('users/${user.uid}/folders')
          .doc(folder.id)
          .update({'name': cleanName});

      return true;
    } catch (e) {
      debugPrint('Error renaming folder: $e');
      return false;
    }
  }

  /// Clear all user data
  Future<bool> clearAllData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      setUploadState(true, 'Clearing all data...');

      // Get all folders
      final foldersSnapshot =
          await _firestore.collection('users/${user.uid}/folders').get();

      // Delete each folder and its contents
      for (final folderDoc in foldersSnapshot.docs) {
        final folder = Folder.fromDoc(folderDoc);
        await deleteFolder(folder);
      }

      // Get all top-level files
      final topLevelFilesSnapshot =
          await _firestore.collection('users/${user.uid}/files').get();

      // Delete each top-level file
      for (final fileDoc in topLevelFilesSnapshot.docs) {
        final file = FileMeta.fromDoc(fileDoc);
        await deleteFile(file);
      }

      return true;
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      return false;
    } finally {
      setUploadState(false);
    }
  }

  /// Set upload state
  void setUploadState(bool uploading, [String message = '']) {
    _isUploading = uploading;
    _loadingMessage = message;
    if (!uploading) {
      _uploadProgress = 0.0;
    }
    notifyListeners();
  }

  /// Update upload progress
  void _updateUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  /// Get storage reference
  Reference _getStorageReference(
    String fileName,
    String? folderId,
    String uid,
  ) {
    final path =
        folderId == null
            ? 'users/$uid/files/$fileName'
            : 'users/$uid/folders/$folderId/$fileName';
    return _storage.ref(path);
  }

  /// Get storage path
  String _getStoragePath(FileMeta file, String uid) {
    return file.folderId == null
        ? 'users/$uid/files/${file.name}'
        : 'users/$uid/folders/${file.folderId}/${file.name}';
  }

  /// Get Firestore reference
  DocumentReference _getFirestoreReference(String? folderId, String uid) {
    return folderId == null
        ? _firestore.collection('users/$uid/files').doc()
        : _firestore.collection('users/$uid/folders/$folderId/files').doc();
  }

  /// Get file document reference
  DocumentReference _getFileDocumentReference(FileMeta file, String uid) {
    return file.folderId == null
        ? _firestore.doc('users/$uid/files/${file.id}')
        : _firestore.doc(
          'users/$uid/folders/${file.folderId}/files/${file.id}',
        );
  }
}
