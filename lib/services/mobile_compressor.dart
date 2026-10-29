import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class CompressionResult {
  final File file;
  final File? thumbnailFile;
  final String type; // 'image' | 'video' | 'pdf' | 'document'
  final int originalSizeBytes;
  final int compressedSizeBytes;

  CompressionResult({
    required this.file,
    this.thumbnailFile,
    required this.type,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  double get savingsPercent {
    if (originalSizeBytes <= 0) return 0.0;
    final saved = originalSizeBytes - compressedSizeBytes;
    if (saved <= 0) return 0.0;
    return (saved / originalSizeBytes) * 100;
  }
}

class MobileCompressor {
  static const int maxFileSizeBytes = 60 * 1024 * 1024; // 60 MB hard limit
  static const int maxFilesCount = 20; // 20 files hard limit

  /// Hard size check: whether a file exceeds 60 MB
  static bool isFileTooLarge(File file) {
    try {
      return file.lengthSync() > maxFileSizeBytes;
    } catch (_) {
      return false;
    }
  }

  /// Hard size check from byte count
  static bool isSizeBytesTooLarge(int sizeBytes) {
    return sizeBytes > maxFileSizeBytes;
  }

  /// Main compression router across all attachment types
  static Future<CompressionResult> compressAttachment(
    File originalFile, {
    void Function(double progress)? onProgress,
  }) async {
    final int originalSize = await originalFile.length();
    final String path = originalFile.path;
    final String ext = path.split('.').last.toLowerCase();

    try {
      // 1. Video Compression (720p @ 1.8 Mbps + 480px poster)
      if (['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm', '3gp'].contains(ext)) {
        return await _compressVideo(originalFile, originalSize, onProgress);
      }

      // 2. Image Compression (1920px @ 80% JPEG + 480px thumbnail)
      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
        return await _compressImage(originalFile, originalSize, onProgress);
      }

      // 3. Office Docs (.docx, .xlsx via OpenXML media optimization + level 9 deflate)
      if (['docx', 'xlsx'].contains(ext)) {
        return await _compressOfficeDoc(originalFile, originalSize, ext, onProgress);
      }

      // 4. PDF Compression (object cross-reference stream & bloat stripping)
      if (ext == 'pdf') {
        return await _compressPdf(originalFile, originalSize, onProgress);
      }
    } catch (e) {
      debugPrint('MobileCompressor warning: error compressing $path: $e. Falling back to original.');
    }

    // Fallback: return original file
    if (onProgress != null) onProgress(1.0);
    return CompressionResult(
      file: originalFile,
      thumbnailFile: null,
      type: 'document',
      originalSizeBytes: originalSize,
      compressedSizeBytes: originalSize,
    );
  }

  // --- Image Compression ---
  static Future<CompressionResult> _compressImage(
    File originalFile,
    int originalSize,
    void Function(double progress)? onProgress,
  ) async {
    if (onProgress != null) onProgress(0.1);
    final tempDir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final targetPath = '${tempDir.path}/img_$timestamp.jpg';
    final thumbPath = '${tempDir.path}/thumb_$timestamp.jpg';

    // 1. Compress main photo: max 1920x1920, quality 80
    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1920,
      minHeight: 1920,
      format: CompressFormat.jpeg,
    );

    if (onProgress != null) onProgress(0.7);

    // 2. Generate lightweight 480px thumbnail
    File? thumbnailFile;
    try {
      final XFile? thumbXFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        thumbPath,
        quality: 70,
        minWidth: 480,
        minHeight: 480,
        format: CompressFormat.jpeg,
      );
      if (thumbXFile != null) {
        thumbnailFile = File(thumbXFile.path);
      }
    } catch (e) {
      debugPrint('MobileCompressor: Failed to generate image thumbnail: $e');
    }

    if (onProgress != null) onProgress(1.0);

    // Zero negative compression check
    if (compressedXFile != null) {
      final compFile = File(compressedXFile.path);
      final compSize = await compFile.length();
      if (compSize < originalSize && compSize > 0) {
        return CompressionResult(
          file: compFile,
          thumbnailFile: thumbnailFile,
          type: 'image',
          originalSizeBytes: originalSize,
          compressedSizeBytes: compSize,
        );
      }
    }

    return CompressionResult(
      file: originalFile,
      thumbnailFile: thumbnailFile,
      type: 'image',
      originalSizeBytes: originalSize,
      compressedSizeBytes: originalSize,
    );
  }

  // --- Video Compression ---
  static Future<CompressionResult> _compressVideo(
    File originalFile,
    int originalSize,
    void Function(double progress)? onProgress,
  ) async {
    Subscription? subscription;
    if (onProgress != null) {
      subscription = VideoCompress.compressProgress$.subscribe((progress) {
        onProgress(progress / 100.0);
      });
    }

    File? thumbnailFile;
    try {
      // Generate 480px poster thumbnail from video first frame
      final thumbFile = await VideoCompress.getFileThumbnail(
        originalFile.path,
        quality: 75,
        position: -1,
      );
      thumbnailFile = thumbFile;
    } catch (e) {
      debugPrint('MobileCompressor: Failed to extract video thumbnail: $e');
    }

    final MediaInfo? info = await VideoCompress.compressVideo(
      originalFile.path,
      quality: VideoQuality.MediumQuality, // 720p H.264 @ ~1.8 Mbps
      deleteOrigin: false,
      includeAudio: true,
    );

    subscription?.unsubscribe();
    if (onProgress != null) onProgress(1.0);

    if (info != null && info.file != null) {
      final compFile = info.file!;
      final compSize = await compFile.length();
      if (compSize < originalSize && compSize > 0) {
        return CompressionResult(
          file: compFile,
          thumbnailFile: thumbnailFile,
          type: 'video',
          originalSizeBytes: originalSize,
          compressedSizeBytes: compSize,
        );
      }
    }

    return CompressionResult(
      file: originalFile,
      thumbnailFile: thumbnailFile,
      type: 'video',
      originalSizeBytes: originalSize,
      compressedSizeBytes: originalSize,
    );
  }

  // --- Office Document Compression (.docx, .xlsx) ---
  static Future<CompressionResult> _compressOfficeDoc(
    File originalFile,
    int originalSize,
    String extension,
    void Function(double progress)? onProgress,
  ) async {
    if (onProgress != null) onProgress(0.2);

    final bytes = await originalFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final outputArchive = Archive();

    int totalMedia = 0;
    for (final file in archive.files) {
      final name = file.name.toLowerCase();
      if ((name.startsWith('word/media/') || name.startsWith('xl/media/')) &&
          (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'))) {
        totalMedia++;
      }
    }

    int processedMedia = 0;
    for (final file in archive.files) {
      if (file.isFile) {
        final name = file.name.toLowerCase();
        final isMedia = (name.startsWith('word/media/') || name.startsWith('xl/media/')) &&
            (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'));

        List<int> fileData = file.content as List<int>;

        // If embedded image is larger than 350 KB, compress it
        if (isMedia && fileData.length > 350 * 1024) {
          try {
            final compressedImg = await FlutterImageCompress.compressWithList(
              Uint8List.fromList(fileData),
              quality: 75,
              minWidth: 1600,
              minHeight: 1600,
              format: name.endsWith('.png') ? CompressFormat.png : CompressFormat.jpeg,
            );
            if (compressedImg.length < fileData.length) {
              fileData = compressedImg;
            }
          } catch (_) {
            // Keep original media bytes
          }
          processedMedia++;
          if (onProgress != null && totalMedia > 0) {
            onProgress(0.2 + (processedMedia / totalMedia) * 0.6);
          }
        }

        outputArchive.addFile(ArchiveFile(file.name, fileData.length, fileData));
      }
    }

    if (onProgress != null) onProgress(0.9);

    final encoded = ZipEncoder().encode(outputArchive, level: Deflate.BEST_COMPRESSION);
    if (encoded != null && encoded.length < originalSize) {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/opt_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final compFile = File(targetPath);
      await compFile.writeAsBytes(encoded, flush: true);

      if (onProgress != null) onProgress(1.0);
      return CompressionResult(
        file: compFile,
        thumbnailFile: null,
        type: 'document',
        originalSizeBytes: originalSize,
        compressedSizeBytes: encoded.length,
      );
    }

    if (onProgress != null) onProgress(1.0);
    return CompressionResult(
      file: originalFile,
      thumbnailFile: null,
      type: 'document',
      originalSizeBytes: originalSize,
      compressedSizeBytes: originalSize,
    );
  }

  // --- PDF Compression ---
  static Future<CompressionResult> _compressPdf(
    File originalFile,
    int originalSize,
    void Function(double progress)? onProgress,
  ) async {
    if (onProgress != null) onProgress(0.3);

    final bytes = await originalFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    document.compressionLevel = PdfCompressionLevel.best;

    if (onProgress != null) onProgress(0.7);

    final List<int> compressedBytes = document.saveSync();
    document.dispose();

    if (compressedBytes.length < originalSize) {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/opt_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final compFile = File(targetPath);
      await compFile.writeAsBytes(compressedBytes, flush: true);

      if (onProgress != null) onProgress(1.0);
      return CompressionResult(
        file: compFile,
        thumbnailFile: null,
        type: 'pdf',
        originalSizeBytes: originalSize,
        compressedSizeBytes: compressedBytes.length,
      );
    }

    if (onProgress != null) onProgress(1.0);
    return CompressionResult(
      file: originalFile,
      thumbnailFile: null,
      type: 'pdf',
      originalSizeBytes: originalSize,
      compressedSizeBytes: originalSize,
    );
  }
}
