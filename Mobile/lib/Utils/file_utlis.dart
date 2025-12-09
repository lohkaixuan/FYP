// lib/Utils/file_utils.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class _Platform {
  static bool get isWeb => kIsWeb;
  static bool get isNotWeb => !kIsWeb;
}


class AppPickedFile {
  final String name;
  final File? file; // mobile/desktop
  final Uint8List? bytes; // web
  final int? size;

  const AppPickedFile({
    required this.name,
    this.file,
    this.bytes,
    this.size,
  });
}

class FileUtils {
  
  static const String kApiBaseUrl = 'https://fyp-1-izlh.onrender.com';

  
  static String buildFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '$kApiBaseUrl$url';
    }
    return '$kApiBaseUrl/$url';
  }

  
  static Future<AppPickedFile?> pickSingle({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    String dialogTitle = 'Select a document',
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: _Platform.isWeb, 
      dialogTitle: dialogTitle,
    );
    if (result == null || result.files.isEmpty) return null;

    final f = result.files.single;
    if (_Platform.isWeb) {
      return AppPickedFile(name: f.name, bytes: f.bytes, size: f.size);
    } else {
      final path = f.path;
      if (path == null) return null;
      return AppPickedFile(name: f.name, file: File(path), size: f.size);
    }
  }

  
  static Future<Directory> _resolveDownloadDir() async {
    Directory? dir;

    try {
      dir = await getDownloadsDirectory(); 
    } catch (_) {
      
    }

    dir ??= await getApplicationDocumentsDirectory();
    return dir;
  }

  
  static Future<String> downloadFromUrlToDevice({
    required Dio dio,
    required String url,
    String? saveAsFileName,
  }) async {
    if (_Platform.isWeb) {
      throw UnsupportedError('downloadFromUrlToDevice is not supported on Web');
    }

    final dir = await _resolveDownloadDir();
    final savePath = '${dir.path}/${saveAsFileName ?? _inferFileName(url)}';
    await dio.download(url, savePath);
    return savePath;
  }

  
  static Future<String> saveBytesToDevice({
    required List<int> bytes,
    required String fileName,
    String? subFolder,
  }) async {
    if (_Platform.isWeb) {
      throw UnsupportedError('saveBytesToDevice is not supported on Web');
    }

    final baseDir = await _resolveDownloadDir();
    final Directory dir = subFolder == null
        ? baseDir
        : await Directory('${baseDir.path}/$subFolder').create(recursive: true);

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  
  static Future<void> downloadInWeb({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    if (!_Platform.isWeb) return;
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  static String _inferFileName(String url) {
    final u = Uri.parse(url);
    final name = u.pathSegments.isNotEmpty ? u.pathSegments.last : 'file.bin';
    return name.isEmpty ? 'file.bin' : name;
  }
}
