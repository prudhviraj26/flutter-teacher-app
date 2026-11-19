import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';

/// WhatsApp-style local file store on flash disk for School Notice, Staff Notice, Class Notice, and Class Update attachments.
/// Saves attachments directly in the private Veyho App Space (`getApplicationSupportDirectory()/veyho_attachments`).
/// The OS will NEVER purge these files under storage pressure.
/// Once saved, repeat visits read directly from local flash storage at $0.00 Azure egress.
/// Automatically cleans up prior academic year attachments upon session transition.
class AttachmentLocalStore {
  static Directory? _cachedDir;

  static Future<Directory> get _attachmentDir async {
    if (_cachedDir != null && await _cachedDir!.exists()) {
      return _cachedDir!;
    }
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory('${baseDir.path}/veyho_attachments');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  static String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static String _formatDateSlug(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }
    } catch (_) {}
    final cleaned = dateStr.replaceAll(RegExp(r'[^0-9-]'), '');
    return cleaned.length >= 10 ? cleaned.substring(0, 10) : cleaned;
  }

  static String _buildFilename(String key, String? dateStr, String? originalFileName) {
    final safeKey = _sanitize(key);
    final dateSlug = _formatDateSlug(dateStr);
    final safeName = originalFileName != null && originalFileName.isNotEmpty
        ? _sanitize(originalFileName)
        : 'attachment.bin';

    if (dateSlug.isNotEmpty) {
      return '${dateSlug}_${safeKey}_$safeName';
    }
    return '${safeKey}_$safeName';
  }

  /// Check if attachment already exists on local flash disk
  static Future<File?> getLocalFile(
    String key, {
    String? dateStr,
    String? originalFileName,
  }) async {
    try {
      final dir = await _attachmentDir;
      final filename = _buildFilename(key, dateStr, originalFileName);
      final file = File('${dir.path}/$filename');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      // Fallback: check if any file in dir contains the safe key
      final safeKey = _sanitize(key);
      if (safeKey.isNotEmpty && await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final name = entity.uri.pathSegments.isNotEmpty
                ? entity.uri.pathSegments.last
                : entity.path.split(Platform.pathSeparator).last;
            if (name.contains(safeKey) && await entity.length() > 0) {
              return entity;
            }
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get locally cached file or download once from Azure SAS URL
  static Future<File?> getOrDownloadAttachment({
    required String key,
    required String url,
    String? dateStr,
    String? originalFileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Check local flash cache first
      final existing = await getLocalFile(key, dateStr: dateStr, originalFileName: originalFileName);
      if (existing != null) {
        debugPrint('AttachmentLocalStore: Cache HIT for $key -> ${existing.path}');
        return existing;
      }

      debugPrint('AttachmentLocalStore: Cache MISS for $key -> Downloading from Azure');
      final dir = await _attachmentDir;
      final filename = _buildFilename(key, dateStr, originalFileName);
      final targetFile = File('${dir.path}/$filename');
      final tempFile = File('${dir.path}/temp_$filename');

      // 2. Stream download from Azure
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      final response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = tempFile.openWrite();
        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0 && onProgress != null) {
              onProgress(receivedBytes / totalBytes);
            }
          },
          cancelOnError: true,
        ).asFuture();

        await sink.flush();
        await sink.close();

        // Atomic rename to final target file
        if (await tempFile.exists()) {
          await tempFile.rename(targetFile.path);
        }

        debugPrint('AttachmentLocalStore: Download complete & saved to ${targetFile.path} (${await targetFile.length()} bytes)');
        return targetFile;
      } else {
        debugPrint('AttachmentLocalStore: HTTP download failed with status ${response.statusCode}');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        return null;
      }
    } catch (e) {
      debugPrint('AttachmentLocalStore: Download error: $e');
      return null;
    }
  }

  /// Open attachment with native viewer (OpenFilex) or fallback to browser (url_launcher)
  static Future<void> openAttachment({
    required BuildContext context,
    required String key,
    required String url,
    String? dateStr,
    String? originalFileName,
  }) async {
    // 1. Check local cache
    File? file = await getLocalFile(key, dateStr: dateStr, originalFileName: originalFileName);

    if (file != null && await file.exists()) {
      debugPrint('Opening cached attachment directly: ${file.path}');
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint('OpenFilex failed: ${result.message}, falling back to browser');
        if (context.mounted) {
          await _openUrl(context, url);
        }
      }
      return;
    }

    // 2. Not cached: show modal progress dialog and download
    if (!context.mounted) return;

    double progress = 0.0;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            dialogSetState = setState;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Downloading Attachment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalFileName ?? 'Please wait...',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      progress > 0
                          ? '${(progress * 100).toInt()}%'
                          : 'Connecting...',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    file = await getOrDownloadAttachment(
      key: key,
      url: url,
      dateStr: dateStr,
      originalFileName: originalFileName,
      onProgress: (p) {
        if (dialogSetState != null) {
          dialogSetState!(() {
            progress = p;
          });
        }
      },
    );

    // Dismiss download dialog
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (file != null && await file.exists()) {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint('OpenFilex failed: ${result.message}, falling back to browser');
        if (context.mounted) {
          await _openUrl(context, url);
        }
      }
    } else {
      if (context.mounted) {
        await _openUrl(context, url);
      }
    }
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment link')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  /// Automatically cleans up locally stored attachments belonging to prior academic years.
  /// Runs asynchronously in background to ensure zero UI delay.
  static Future<int> autoCleanupPriorAcademicYear(DateTime activeAcademicYearStartDate) async {
    int deletedCount = 0;
    try {
      final dir = await _attachmentDir;
      if (!await dir.exists()) return 0;

      final entities = dir.listSync();
      final datePattern = RegExp(r'^(\d{4}-\d{2}-\d{2})_(.+)$');

      for (final entity in entities) {
        if (entity is! File) continue;
        final filename = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : entity.path.split(Platform.pathSeparator).last;

        final match = datePattern.firstMatch(filename);
        if (match != null) {
          final dateStr = match.group(1);
          if (dateStr != null) {
            final fileDate = DateTime.tryParse(dateStr);
            if (fileDate != null && fileDate.isBefore(activeAcademicYearStartDate)) {
              await entity.delete();
              deletedCount++;
              continue;
            }
          }
        } else {
          // Legacy file without date prefix: check physical disk modification date
          try {
            final lastModified = await entity.lastModified();
            if (lastModified.isBefore(activeAcademicYearStartDate)) {
              await entity.delete();
              deletedCount++;
            }
          } catch (_) {}
        }
      }

      if (deletedCount > 0) {
        debugPrint(
          'Veyho Attachment Auto-Cleanup: Freed $deletedCount prior-year artifacts (Threshold: $activeAcademicYearStartDate)',
        );
      }
    } catch (e) {
      debugPrint('Veyho Attachment Auto-Cleanup error: $e');
    }
    return deletedCount;
  }
}
