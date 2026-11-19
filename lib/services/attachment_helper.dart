import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AttachmentResult {
  final String name;
  final String path;
  final int sizeBytes;

  AttachmentResult({
    required this.name,
    required this.path,
    this.sizeBytes = 0,
  });

  bool get isOversized => sizeBytes > 60 * 1024 * 1024;

  double get sizeInMB => sizeBytes / (1024 * 1024);
}

class AttachmentHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Generates clean, human-readable file names eliminating OS temporary cache names like scaled_39580.jpg
  static String formatUnifiedFileName(String rawName, {required String source, int? index}) {
    final ext = rawName.contains('.') ? rawName.split('.').last.toLowerCase() : 'jpg';
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final dateSlug = '$y$m$d';
    final timeSlug = '$hh$mm$ss';
    final idxSuffix = index != null ? '_$index' : '';

    if (source == 'camera') {
      return 'Photo_${dateSlug}_$timeSlug$idxSuffix.$ext';
    }

    // Check if name is a generic OS/picker cache prefix (e.g. scaled_..., image_picker..., or numbers like 1000039580)
    final isGenericCache = rawName.startsWith('scaled_') ||
        rawName.startsWith('image_picker') ||
        RegExp(r'^\d{5,}\.').hasMatch(rawName) ||
        RegExp(r'^[a-f0-9-]{16,}\.').hasMatch(rawName);

    if (isGenericCache) {
      return 'Photo_${dateSlug}_$timeSlug$idxSuffix.$ext';
    }

    // Clean user original file name from file manager / genuine uploads
    return rawName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
  }

  // Open native camera
  static Future<AttachmentResult?> pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        int length = 0;
        try {
          length = await File(photo.path).length();
        } catch (_) {}
        final cleanName = formatUnifiedFileName(photo.name, source: 'camera');
        return AttachmentResult(name: cleanName, path: photo.path, sizeBytes: length);
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
    return null;
  }

  // Open native photo gallery (single image)
  static Future<AttachmentResult?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        int length = 0;
        try {
          length = await File(image.path).length();
        } catch (_) {}
        final cleanName = formatUnifiedFileName(image.name, source: 'gallery');
        return AttachmentResult(name: cleanName, path: image.path, sizeBytes: length);
      }
    } catch (e) {
      debugPrint('Error opening gallery: $e');
    }
    return null;
  }

  // Open native photo gallery (multiple images)
  static Future<List<AttachmentResult>> pickMultipleFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      final List<AttachmentResult> results = [];
      int idx = 1;
      for (final img in images) {
        int length = 0;
        try {
          length = await File(img.path).length();
        } catch (_) {}
        final cleanName = formatUnifiedFileName(
          img.name,
          source: 'gallery',
          index: images.length > 1 ? idx++ : null,
        );
        results.add(AttachmentResult(name: cleanName, path: img.path, sizeBytes: length));
      }
      return results;
    } catch (e) {
      debugPrint('Error opening multi-image gallery: $e');
    }
    return [];
  }

  // Open native file manager (single file)
  static Future<AttachmentResult?> pickFromFileManager() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg', 'mp4', 'mov', 'webm'
        ],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          int length = file.size;
          if (length <= 0) {
            try {
              length = await File(file.path!).length();
            } catch (_) {}
          }
          final cleanName = formatUnifiedFileName(file.name, source: 'file');
          return AttachmentResult(name: cleanName, path: file.path!, sizeBytes: length);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  // Open native file manager (multiple files)
  static Future<List<AttachmentResult>> pickMultipleFromFileManager() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg', 'mp4', 'mov', 'webm'
        ],
      );
      if (result != null && result.files.isNotEmpty) {
        final List<AttachmentResult> results = [];
        int idx = 1;
        for (final file in result.files) {
          if (file.path != null) {
            int length = file.size;
            if (length <= 0) {
              try {
                length = await File(file.path!).length();
              } catch (_) {}
            }
            final cleanName = formatUnifiedFileName(
              file.name,
              source: 'file',
              index: result.files.length > 1 ? idx++ : null,
            );
            results.add(AttachmentResult(name: cleanName, path: file.path!, sizeBytes: length));
          }
        }
        return results;
      }
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
    }
    return [];
  }

  // Get matching icon based on file extension
  static IconData getFileIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.webm') || lower.endsWith('.mkv')) {
      return Icons.video_file;
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
    } else if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.webm') || lower.endsWith('.mkv')) {
      return Colors.purple.shade600;
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
