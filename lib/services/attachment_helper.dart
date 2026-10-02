import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AttachmentResult {
  final String name;
  final String path;

  AttachmentResult({required this.name, required this.path});
}

class AttachmentHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  // Open native camera
  static Future<AttachmentResult?> pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        return AttachmentResult(name: photo.name, path: photo.path);
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
    return null;
  }

  // Open native photo gallery
  static Future<AttachmentResult?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        return AttachmentResult(name: image.name, path: image.path);
      }
    } catch (e) {
      debugPrint('Error opening gallery: $e');
    }
    return null;
  }

  // Open native file manager (PDF, docs, images, etc.)
  static Future<AttachmentResult?> pickFromFileManager() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return AttachmentResult(name: file.name, path: file.path!);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  // Get matching icon based on file extension
  static IconData getFileIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
      return Icons.image;
    } else if (lower.endsWith('.doc') || lower.endsWith('.docx') || lower.endsWith('.txt')) {
      return Icons.description;
    } else if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  // Get matching color based on file extension
  static Color getFileColor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Colors.red.shade600;
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
      return Colors.blue.shade600;
    } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Colors.indigo.shade600;
    } else if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return Colors.green.shade600;
    }
    return Colors.grey.shade700;
  }
}
