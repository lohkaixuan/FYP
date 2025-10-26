// lib/Utils/file_utils.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

import 'package:universal_html/html.dart' as html;


// 只有非 Web 平台才导入这些库（避免 Web 构建错误）
/* cspell:disable */
import 'package:dio/dio.dart' ;
import 'package:path_provider/path_provider.dart';
import 'dart:io' ;

class _Platform {
  static bool get isWeb => kIsWeb;
  static bool get isNotWeb => !kIsWeb;
}
/// 统一封装：一次文件选择的结果
class AppPickedFile {
  final String name;
  final File? file;         // mobile/desktop
  final Uint8List? bytes;   // web
  final int? size;

  const AppPickedFile({
    required this.name,
    this.file,
    this.bytes,
    this.size,
  });
}

/// 文件工具：挑文件 / 下载文件
class FileUtils {
  /// 选择单个文件（支持 mobile/desktop + web）
  static Future<AppPickedFile?> pickSingle({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    String dialogTitle = 'Select a document',
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: _Platform.isWeb, // web 需要 bytes
      dialogTitle: dialogTitle,
    );
    if (result == null || result.files.isEmpty) return null;

    final f = result.files.single;
    if (_Platform.isWeb) {
      // Web：无本地路径，返回 bytes
      return AppPickedFile(name: f.name, bytes: f.bytes, size: f.size);
    } else {
      // 移动端/桌面：有真实路径，返回 File
      final path = f.path;
      if (path == null) return null;
      return AppPickedFile(name: f.name, file: File(path), size: f.size);
    }
  }

  /// 用 Dio 从 URL 下载到本地（mobile/desktop），返回保存路径
  static Future<String> downloadFromUrlToDevice({
    required Dio dio,
    required String url,
    String? saveAsFileName,
  }) async {
    if (_Platform.isWeb) {
      throw UnsupportedError('downloadFromUrlToDevice is not supported on Web');
    }
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${saveAsFileName ?? _inferFileName(url)}';
    await dio.download(url, savePath);
    return savePath;
  }

  /// 直接保存 bytes 到本地（mobile/desktop），返回保存路径
  static Future<String> saveBytesToDevice({
    required List<int> bytes,
    required String fileName,
    String? subFolder,
  }) async {
    if (_Platform.isWeb) {
      throw UnsupportedError('saveBytesToDevice is not supported on Web');
    }
    final Directory baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final Directory dir = subFolder == null
        ? baseDir
        : await Directory('${baseDir.path}/$subFolder').create(recursive: true);

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Web 下载：触发浏览器保存
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
