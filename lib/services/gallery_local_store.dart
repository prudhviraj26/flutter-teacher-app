import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// WhatsApp-style local file store on flash disk.
/// Saves event photos directly in the private Veyho App Space (`getApplicationSupportDirectory()`).
/// The OS will NEVER purge these files under storage pressure.
/// Once saved, repeat visits 3 days or 6 months later read directly from local flash storage at $0.00 Azure egress.
/// Automatically cleans up prior academic year photos upon session transition.
class GalleryLocalStore {
  static Directory? _cachedDir;

  static Future<Directory> get _galleryDir async {
    if (_cachedDir != null && await _cachedDir!.exists()) {
      return _cachedDir!;
    }
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory('${baseDir.path}/veyho_gallery');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  static String _sanitizeId(String mediaId) {
    return mediaId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  static String _formatDateSlug(String? eventDate) {
    if (eventDate == null || eventDate.trim().isEmpty) return '';
    final trimmed = eventDate.trim();
    try {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }
    } catch (_) {}

    // Handle DD-MM-YYYY or DD/MM/YYYY
    if (RegExp(r'^\d{1,2}[-/]\d{1,2}[-/]\d{4}').hasMatch(trimmed)) {
      final parts = trimmed.split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        final d = parts[0].padLeft(2, '0');
        final m = parts[1].padLeft(2, '0');
        final y = parts[2].substring(0, 4);
        return '$y-$m-$d';
      }
    }

    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9-]'), '');
    return cleaned.length >= 10 ? cleaned.substring(0, 10) : cleaned;
  }

  /// Check if local file exists in Veyho App Space
  static Future<File?> getLocalImageFile(
    String mediaId, {
    String? eventDate,
    bool isThumbnail = false,
  }) async {
    try {
      final dir = await _galleryDir;
      final prefix = isThumbnail ? 'thumb' : 'full';
      final safeId = _sanitizeId(mediaId);
      final dateSlug = _formatDateSlug(eventDate);

      // 1. Try date-prefixed file: e.g. thumb_2026-04-10_media123.jpg
      if (dateSlug.isNotEmpty) {
        final datedFile = File('${dir.path}/${prefix}_${dateSlug}_$safeId.jpg');
        if (await datedFile.exists() && await datedFile.length() > 0) {
          return datedFile;
        }
      }

      // 2. Try legacy file: e.g. thumb_media123.jpg
      final legacyFile = File('${dir.path}/${prefix}_$safeId.jpg');
      if (await legacyFile.exists() && await legacyFile.length() > 0) {
        return legacyFile;
      }

      // 3. Fallback: check if any file with this safeId exists for this prefix
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final name = entity.uri.pathSegments.isNotEmpty
                ? entity.uri.pathSegments.last
                : entity.path.split(Platform.pathSeparator).last;
            if (name.startsWith('${prefix}_') && name.endsWith('_$safeId.jpg')) {
              if (await entity.length() > 0) return entity;
            }
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save raw image bytes into Veyho App Space
  static Future<File?> saveImageBytes(
    String mediaId,
    Uint8List bytes, {
    String? eventDate,
    bool isThumbnail = false,
  }) async {
    try {
      final dir = await _galleryDir;
      final prefix = isThumbnail ? 'thumb' : 'full';
      final safeId = _sanitizeId(mediaId);
      final dateSlug = _formatDateSlug(eventDate);

      final filename = dateSlug.isNotEmpty
          ? '${prefix}_${dateSlug}_$safeId.jpg'
          : '${prefix}_$safeId.jpg';

      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Fetch photo from local flash storage or download once from Azure
  static Future<File?> getOrDownloadImage(
    String mediaId,
    String url, {
    String? eventDate,
    bool isThumbnail = false,
  }) async {
    // 1. Check local flash storage first
    final existing = await getLocalImageFile(
      mediaId,
      eventDate: eventDate,
      isThumbnail: isThumbnail,
    );
    if (existing != null) {
      return existing;
    }

    if (url.isEmpty) return null;

    // 2. Download 1 time only from Azure SAS URL
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return await saveImageBytes(
          mediaId,
          response.bodyBytes,
          eventDate: eventDate,
          isThumbnail: isThumbnail,
        );
      }
    } catch (_) {
      // Return null on failure, widget displays error placeholder
    }
    return null;
  }

  /// Automatically cleans up locally stored gallery photos belonging to prior academic years.
  /// Runs asynchronously in background to ensure zero UI delay.
  static Future<int> autoCleanupPriorAcademicYear(DateTime activeAcademicYearStartDate) async {
    int deletedCount = 0;
    try {
      final dir = await _galleryDir;
      if (!await dir.exists()) return 0;

      final entities = dir.listSync();
      final datePattern = RegExp(r'^(thumb|full)_(\d{4}-\d{2}-\d{2})_(.+)\.jpg$');

      for (final entity in entities) {
        if (entity is! File) continue;
        final filename = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : entity.path.split(Platform.pathSeparator).last;

        if (!filename.endsWith('.jpg')) continue;

        final match = datePattern.firstMatch(filename);
        if (match != null) {
          final dateStr = match.group(2);
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
          'Veyho Gallery Auto-Cleanup: Freed $deletedCount prior-year artifacts (Threshold: $activeAcademicYearStartDate)',
        );
      }
    } catch (e) {
      debugPrint('Veyho Gallery Auto-Cleanup notice: $e');
    }
    return deletedCount;
  }
}

/// A performant widget that renders an image from Veyho's local flash store.
/// If not yet cached, streams from Azure SAS URL, writes to local disk, and renders.
class VeyhoCachedImage extends StatefulWidget {
  final String mediaId;
  final String url;
  final String? eventDate;
  final bool isThumbnail;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VeyhoCachedImage({
    super.key,
    required this.mediaId,
    required this.url,
    this.eventDate,
    this.isThumbnail = true,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<VeyhoCachedImage> createState() => _VeyhoCachedImageState();
}

class _VeyhoCachedImageState extends State<VeyhoCachedImage> {
  File? _localFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant VeyhoCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.url != widget.url ||
        oldWidget.eventDate != widget.eventDate) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    // Quick check if already on local flash disk
    final cached = await GalleryLocalStore.getLocalImageFile(
      widget.mediaId,
      eventDate: widget.eventDate,
      isThumbnail: widget.isThumbnail,
    );
    if (cached != null) {
      if (mounted) {
        setState(() {
          _localFile = cached;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Download once and write to flash disk
    final downloaded = await GalleryLocalStore.getOrDownloadImage(
      widget.mediaId,
      widget.url,
      eventDate: widget.eventDate,
      isThumbnail: widget.isThumbnail,
    );

    if (mounted) {
      setState(() {
        _localFile = downloaded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localFile != null) {
      return Image.file(
        _localFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.broken_image_rounded, size: 28, color: Color(0xFF94A3B8)),
              );
        },
      );
    }

    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFFF1F5F9),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
          );
    }

    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_rounded, size: 26, color: Color(0xFF94A3B8)),
        );
  }
}

