import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:webinar/app/models/register_config_model.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/common/utils/constants.dart';
import 'package:webinar/common/utils/error_handler.dart';
import 'package:webinar/common/utils/http_handler.dart';

class AuthenticationService {
  static Future google(String email, String token, String name) async {
    try {
      String url = '${Constants.baseUrl}google/callback';

      Response res = await httpPost(url, {
        'email': email,
        'name': name,
        'id': token,
      });

      if (res.statusCode == 200) {
        await AppData.saveAccessToken(jsonDecode(res.body)['data']['token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future facebook(String email, String token, String name) async {
    try {
      String url = '${Constants.baseUrl}facebook/callback';

      Response res = await httpPost(url, {
        'id': token,
        'name': name,
        'email': email,
      });

      var jsonResponse = jsonDecode(res.body);
      if (jsonResponse['success']) {
        await AppData.saveAccessToken(jsonDecode(res.body)['data']['token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future login(String username, String password) async {
    try {
      String url = '${Constants.baseUrl}login';

      Response res = await httpPost(url, {
        'username': username,
        'password': password,
      });

      log(res.body.toString());

      var jsonResponse = jsonDecode(res.body);
      if (jsonResponse['success']) {
        await AppData.saveAccessToken(jsonResponse['data']['token']);
        await AppData.saveName('');
        return true;
      } else {
        ErrorHandler().showError(ErrorEnum.error, jsonResponse, readMessage: true);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// ✅ register step 1 (email)
  /// Supports:
  /// - account_type
  /// - extraData (ex: full_name, guardian_name, guardian_country_code, guardian_mobile, ...)
  /// - dynamic fields as JSON string
  static Future<Map?> registerWithEmail(
    String registerMethod,
    String email,
    String password,
    String repeatPassword,
    String? accountType,
    List<Fields>? fields, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      String url = '${Constants.baseUrl}register/step/1';

      final Map<String, dynamic> body = {
        "register_method": registerMethod,
        "country_code": null,
        "email": email,
        "password": password,
        "password_confirmation": repeatPassword,
        if (accountType != null) "account_type": accountType,
      };

      // ✅ attach extra fields (IMPORTANT: include full_name here)
      if (extraData != null && extraData.isNotEmpty) {
        body.addAll(extraData);
      }

      // ✅ dynamic form fields
      if (fields != null) {
        final Map<String, dynamic> bodyFields = {};

        for (final f in fields) {
          if (f.type == 'upload') continue;

          final String key = (f.id).toString();

          final dynamic value = (f.type == 'toggle')
              ? (f.userSelectedData == null ? 0 : 1)
              : f.userSelectedData;

          if (value != null) {
            bodyFields[key] = value;
          }
        }

        // ✅ MUST be JSON string (not Map.toString)
        body["fields"] = jsonEncode(bodyFields);
      }

      Response res = await httpPost(url, body);
      final jsonResponse = jsonDecode(res.body);

      if (jsonResponse['success'] ||
          jsonResponse['status'] == 'go_step_2' ||
          jsonResponse['status'] == 'go_step_3' ||
          jsonResponse['status'] == 'stored') {
        return {
          'user_id': jsonResponse['data']['user_id'],
          'step': jsonResponse['status'],
        };
      } else {
        ErrorHandler().showError(ErrorEnum.error, jsonResponse);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// ✅ register step 1 (phone)
  /// Supports:
  /// - account_type
  /// - extraData (ex: full_name, guardian_name, guardian_country_code, guardian_mobile, ...)
  /// - dynamic fields as JSON string
  static Future<Map?> registerWithPhone(
    String registerMethod,
    String countryCode,
    String mobile,
    String password,
    String repeatPassword,
    String? accountType,
    List<Fields>? fields, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      String url = '${Constants.baseUrl}register/step/1';

      final Map<String, dynamic> body = {
        "register_method": registerMethod,
        "country_code": countryCode,
        "mobile": mobile,
        "password": password,
        "password_confirmation": repeatPassword,
        if (accountType != null) "account_type": accountType,
      };

      // ✅ attach extra fields (IMPORTANT: include full_name here)
      if (extraData != null && extraData.isNotEmpty) {
        body.addAll(extraData);
      }

      // ✅ dynamic form fields
      if (fields != null) {
        final Map<String, dynamic> bodyFields = {};

        for (final f in fields) {
          if (f.type == 'upload') continue;

          final String key = (f.id).toString();

          final dynamic value = (f.type == 'toggle')
              ? (f.userSelectedData == null ? 0 : 1)
              : f.userSelectedData;

          if (value != null) {
            bodyFields[key] = value;
          }
        }

        body["fields"] = jsonEncode(bodyFields);
      }

      Response res = await httpPost(url, body);
      final jsonResponse = jsonDecode(res.body);

      if (jsonResponse['success'] ||
          jsonResponse['status'] == 'go_step_2' ||
          jsonResponse['status'] == 'go_step_3' ||
          jsonResponse['status'] == 'stored') {
        return {
          'user_id': jsonResponse['data']['user_id'],
          'step': jsonResponse['status'],
        };
      } else {
        ErrorHandler().showError(ErrorEnum.error, jsonResponse);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<bool> forgetPassword(String? countryCode, String data) async {
    try {
      String url = '${Constants.baseUrl}forget-password';

      Response res = await httpPost(url, {
        'type': countryCode == null ? 'email' : 'mobile',
        if (countryCode == null) ...{
          "email": data,
        } else ...{
          "country_code": countryCode,
          "mobile": data,
        }
      });

      log(res.body.toString());

      var jsonResponse = jsonDecode(res.body);
      if (jsonResponse['success']) {
        ErrorHandler().showError(ErrorEnum.success, jsonResponse, readMessage: true);
        return true;
      } else {
        ErrorHandler().showError(ErrorEnum.error, jsonResponse);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// ✅ verify otp (step 2)
  /// NOTE: backend currently returns success only (token comes from step 3)
  static Future<bool> verifyCode(int userId, String code) async {
    try {
      String url = '${Constants.baseUrl}register/step/2';

      Response res = await httpPost(url, {
        "user_id": userId.toString(),
        "code": code,
      });

      log(res.body.toString());

      var jsonResponse = jsonDecode(res.body);
      if (jsonResponse['success']) {
        return true;
      } else {
        ErrorHandler().showError(ErrorEnum.error, jsonResponse);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// ✅ finalize (step 3) - we now call it hidden after OTP to get token
  static Future<bool> registerStep3(int userId, String name, String referralCode) async {
    try {
      String url = '${Constants.baseUrl}register/step/3';

      Response res = await httpPost(url, {
        "user_id": userId.toString(),
        "full_name": name,
        "referral_code": referralCode,
      });

      var jsonResponse = jsonDecode(res.body);
      if (jsonResponse['success']) {
        await AppData.saveAccessToken(jsonResponse['data']['token']);
        await AppData.saveName(name);
        return true;
      } else {
        ErrorHandler().showError(ErrorEnum.error, jsonResponse);
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
