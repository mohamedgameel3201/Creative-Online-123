import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/locator.dart';

import '../data/app_data.dart';
import '../data/app_language.dart';
import 'constants.dart';

class DownloadManager {
  static List<FileSystemEntity> files = [];

  static void _log(String msg) {
    // ignore: avoid_print
    print('📥 [DownloadManager] $msg');
  }

  static Future<void> download(
    String url,
    Function(int progress) onDownlaod, {
    CancelToken? cancelToken,
    String? name,
    Function? onLoadAtLocal,
    bool isOpen = true,
  }) async {
    _log('===== DOWNLOAD START =====');
    _log('url=$url');
    _log('name=${name ?? "(null)"}');
    _log('isOpen=$isOpen');

    // ✅ لا تطلب أي Permissions نهائيًا
    // لأننا بنحفظ داخل مساحة التطبيق (App Sandbox) وده لا يحتاج صلاحيات Storage/Photos

    final Directory dir = Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();

    final directory = dir.path;

    final fileName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : url.split('/').last;

    final savePath = '$directory/$fileName';

    _log('directory=$directory');
    _log('fileName=$fileName');
    _log('savePath=$savePath');

    // لو الملف موجود بالفعل
    final exists = await findFile(
      directory,
      fileName,
      onLoadAtLocal: onLoadAtLocal,
      isOpen: isOpen,
    );
    _log('findFile.exists=$exists');

    if (exists) {
      _log('✅ File already exists locally. DONE.');
      _log('===== DOWNLOAD END =====');
      return;
    }

    // headers
    String token = await AppData.getAccessToken();
    _log('token_len=${token.length}');

    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "x-api-key": Constants.apiKey,
      "x-locale": locator<AppLanguage>().currentLanguage.toLowerCase(),
    };

    _log('headers.x-locale=${headers["x-locale"]}');
    _log('headers.x-api-key_len=${(headers["x-api-key"] ?? "").length}');
    _log('headers.Authorization_present=${headers["Authorization"]?.isNotEmpty == true}');

    final dioClient = locator<Dio>();

    // ✅ HEAD request عشان نعرف السيرفر بيرجع Content-Length ولا لأ (مهم لحكاية 0%)
    int? contentLength;
    try {
      _log('Sending HEAD request...');
      final headRes = await dioClient.head(
        url,
        options: Options(
          followRedirects: true,
          headers: headers,
          validateStatus: (_) => true,
        ),
      );

      _log('HEAD status=${headRes.statusCode}');
      _log('HEAD content-type=${headRes.headers.value("content-type")}');
      _log('HEAD content-length=${headRes.headers.value("content-length")}');
      _log('HEAD accept-ranges=${headRes.headers.value("accept-ranges")}');

      final cl = headRes.headers.value('content-length');
      if (cl != null) {
        contentLength = int.tryParse(cl);
      }
      _log('HEAD parsed contentLength=$contentLength');
    } catch (e) {
      _log('⚠️ HEAD failed: $e');
    }

    // ✅ للتقدم التقديري لو total=0
    int lastFakeProgress = 0;

    try {
      _log('Start dio.download ...');

      final response = await dioClient.download(
        url,
        savePath,
        onReceiveProgress: (count, total) {
          // total أحيانًا بيكون 0 أو -1 لو السيرفر مش بيرجع Content-Length
          if (total <= 0) {
            // لو عرفنا content-length من HEAD نستخدمه
            if (contentLength != null && contentLength! > 0) {
              final percent = ((count / contentLength!) * 100).clamp(0, 100).toInt();
              _log('onReceiveProgress (HEAD length): $count/${contentLength!} => $percent%');
              onDownlaod(percent);
              return;
            }

            // وإلا نعمل progress تقديري بدل ما يفضل ثابت 0%
            // هنزود لحد 95% طول ما الداتا بتوصل
            if (count > 0) {
              lastFakeProgress = (lastFakeProgress + 1).clamp(0, 95);
              _log('onReceiveProgress (fake): count=$count total=$total => $lastFakeProgress%');
              onDownlaod(lastFakeProgress);
            } else {
              _log('onReceiveProgress: count=$count total=$total (unknown total)');
              onDownlaod(0);
            }
            return;
          }

          final percent = ((count / total) * 100).clamp(0, 100).toInt();
          _log('onReceiveProgress: $count/$total => $percent%');
          onDownlaod(percent);
        },
        cancelToken: cancelToken,
        options: Options(
          followRedirects: true,
          headers: headers,
          validateStatus: (_) => true, // عشان نسجل أي status
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      _log('download response status=${response.statusCode}');
      _log('download response content-type=${response.headers.value("content-type")}');
      _log('download response content-length=${response.headers.value("content-length")}');

      if (response.statusCode == 200) {
        final f = File(savePath);
        final fileExists = await f.exists();
        final fileSize = fileExists ? await f.length() : 0;

        // لو كنا بنستخدم progress تقديري، خلّيه 100% عند النهاية
        onDownlaod(100);

        _log('✅ Saved file exists=$fileExists size=$fileSize bytes');

        if (navigatorKey.currentContext?.mounted == true) {
          backRoute(arguments: savePath);
        }

        if (isOpen) {
          _log('Opening file...');
          await OpenFile.open(savePath);
        }

        _log('===== DOWNLOAD END (SUCCESS) =====');
      } else {
        _log('❌ Download failed status=${response.statusCode}');
        showSnackBar(ErrorEnum.error, 'Download failed: ${response.statusCode}');
        _log('===== DOWNLOAD END (FAILED) =====');
      }
    } on DioException catch (e) {
      _log('❌ DioException: ${e.message}');
      _log('type=${e.type}');
      _log('error=${e.error}');

      if (e.response != null) {
        _log('response.status=${e.response?.statusCode}');
        _log('response.headers=${e.response?.headers.map}');
        final dataStr = (e.response?.data is String)
            ? e.response?.data
            : e.response?.data?.toString();
        if (dataStr != null) {
          _log('response.data=${dataStr.substring(0, dataStr.length > 500 ? 500 : dataStr.length)}');
        }
      }

      showSnackBar(ErrorEnum.error, e.message);
      _log('===== DOWNLOAD END (EXCEPTION) =====');
    } catch (e) {
      _log('❌ Unknown error: $e');
      showSnackBar(ErrorEnum.error, 'Unknown download error');
      _log('===== DOWNLOAD END (UNKNOWN EXCEPTION) =====');
    }
  }

  static Future<bool> findFile(
    String directory,
    String name, {
    Function? onLoadAtLocal,
    bool isOpen = true,
  }) async {
    files = Directory(directory).listSync().toList();

    for (var i = 0; i < files.length; i++) {
      if (files[i].path.contains(name)) {
        _log('findFile: found local file path=${files[i].path}');

        if (onLoadAtLocal != null) {
          onLoadAtLocal();
        }

        if (isOpen) {
          await OpenFile.open(files[i].path);
        }
        return true;
      }
    }

    _log('findFile: not found');
    return false;
  }
}