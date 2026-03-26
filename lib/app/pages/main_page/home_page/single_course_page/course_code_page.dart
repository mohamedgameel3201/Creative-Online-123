import 'dart:convert';

import 'package:flutter/material.dart';
// ✅ نفس util اللى باقى الخدمات بتستخدمه
import 'package:webinar/common/utils/constants.dart';
import 'package:webinar/common/utils/http_handler.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';

class CourseCodePage extends StatefulWidget {
  static const String pageName = '/course-code';

  const CourseCodePage({super.key});

  @override
  State<CourseCodePage> createState() => _CourseCodePageState();
}

class _CourseCodePageState extends State<CourseCodePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  int courseId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // استلام الـ courseId من Route arguments
    final args =
        (ModalRoute.of(context)!.settings.arguments ?? <dynamic>[null]) as List;
    if (args.isNotEmpty && args[0] != null) {
      courseId = args[0] as int;
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (courseId == 0) {
      showSnackBar(
        ErrorEnum.error,
        'حدث خطأ: رقم الكورس غير معروف.',
      );
      return;
    }

    final code = _codeController.text.trim();

    if (code.isEmpty) {
      showSnackBar(ErrorEnum.error, 'من فضلك أدخل الكود أولاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔗 نفس الـ baseUrl المستخدم فى كل الخدمات
      final String url =
          '${Constants.baseUrl}courses/$courseId/access-code';

      // ✅ استخدام httpPostWithToken عشان يضيف الـ API Key + التوكن تلقائياً
      final response = await httpPostWithToken(
        url,
        {
          'code': code,
        },
        isRedirectingStatusCode: false,
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        showSnackBar(
          ErrorEnum.error,
          'حدث خطأ أثناء التفعيل، حاول مرة أخرى.',
        );
        return;
      }

      // الشكل اللى إحنا معرفينه من الـ backend:
      // { success: true/false, statusa: 200/..., message: '...' }
      final bool success = (data['success'] == true) ||
          (data['status'] == 200 || data['status'] == '200');

      if (success) {
        final message = data['message']?.toString() ??
            'تم تفعيل الكورس بنجاح باستخدام الكود.';

        showSnackBar(
          ErrorEnum.success,
          message,
        );

        // نرجّع true عشان الصفحة اللى قبل تقدر تعمل refresh للكورس
        Navigator.pop(context, true);
      } else {
        final message = data['message']?.toString() ??
            'الكود غير صحيح أو لا يخص هذا الكورس.';
        showSnackBar(
          ErrorEnum.error,
          message,
        );
      }
    } catch (e) {
      showSnackBar(
        ErrorEnum.error,
        'حدث خطأ أثناء الاتصال بالسيرفر، حاول مرة أخرى.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return directionality(
      child: Scaffold(
        appBar: appbar(
          title: 'تفعيل الكورس باستخدام كود',
        ),
        body: Padding(
          padding: padding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اكتب كود الكورس الخاص بهذا الكورس ثم اضغط على تفعيل.',
                style: style14Regular().copyWith(color: greyA5),
              ),
              space(16),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: 'أدخل كود الكورس هنا',
                  hintStyle: style14Regular().copyWith(color: greyA5),
                  border: OutlineInputBorder(
                    borderRadius: borderRadius(),
                    borderSide: const BorderSide(),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius(),
                    borderSide: const BorderSide(),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius(),
                    borderSide: BorderSide(color: green77()),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              space(24),
              button(
                onTap: () {
                  if (!_isLoading) {
                    _submit();
                  }
                },
                width: getSize().width,
                height: 52,
                text: 'تفعيل الكود',
                bgColor: green77(),
                textColor: Colors.white,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
