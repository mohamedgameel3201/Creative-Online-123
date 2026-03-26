import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webinar/app/services/authentication_service/authentication_service.dart';
import 'package:webinar/app/widgets/authentication_widget/register_widget/register_widget.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/data/app_data.dart';

import '../../../common/data/api_public_data.dart';
import '../../../common/enums/page_name_enum.dart';
import '../../../common/utils/app_text.dart';
import '../../../config/assets.dart';
import '../../../config/colors.dart';
import '../../../config/styles.dart';
import '../../../common/components.dart';
import '../../../locator.dart';
import '../../providers/page_provider.dart';
import '../main_page/main_page.dart';

class VerifyCodePage extends StatefulWidget {
  static const String pageName = '/verify-code';
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  TextEditingController controller3 = TextEditingController();
  TextEditingController controller4 = TextEditingController();
  TextEditingController controller5 = TextEditingController();

  FocusNode codeNode1 = FocusNode();
  FocusNode codeNode2 = FocusNode();
  FocusNode codeNode3 = FocusNode();
  FocusNode codeNode4 = FocusNode();
  FocusNode codeNode5 = FocusNode();

  bool isEmptyInputs = true;
  bool isSendingData = false;
  bool isCodeAgain = false;

  late Map data;

  @override
  void initState() {
    super.initState();

    void refresh() {
      final len = getCode().length;
      final newEmpty = len != 5;
      if (newEmpty != isEmptyInputs) {
        setState(() => isEmptyInputs = newEmpty);
      }
    }

    controller1.addListener(refresh);
    controller2.addListener(refresh);
    controller3.addListener(refresh);
    controller4.addListener(refresh);
    controller5.addListener(refresh);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      data = ModalRoute.of(context)!.settings.arguments as Map;
    });
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
    controller5.dispose();

    codeNode1.dispose();
    codeNode2.dispose();
    codeNode3.dispose();
    codeNode4.dispose();
    codeNode5.dispose();

    super.dispose();
  }

  String getCode() {
    return controller1.text.trim() +
        controller2.text.trim() +
        controller3.text.trim() +
        controller4.text.trim() +
        controller5.text.trim();
  }

  void onPastedCode(String code) {
    List<String> items = code.split('');
    if (items.length >= 5) {
      controller1.text = items[0];
      controller2.text = items[1];
      controller3.text = items[2];
      controller4.text = items[3];
      controller5.text = items[4];
      FocusScope.of(navigatorKey.currentContext!).unfocus();
    }
  }

  // ✅ helper: clear code inputs
  void _clearCodeInputs() {
    controller1.clear();
    controller2.clear();
    controller3.clear();
    controller4.clear();
    controller5.clear();
  }

  // ✅ helper: build full name from args
  String _getFullNameFromArgs() {
    final v = (data['full_name'] ?? '').toString().trim();
    return v;
  }

  // ✅ After OTP success, we call step3 hidden to get token (and store full_name if needed)
  Future<void> _finalizeHiddenAndGoHome() async {
    final fullName = _getFullNameFromArgs();

    // لو full_name مش متبعت لأي سبب، نخش هوم وخلاص (لكن الأفضل يكون موجود)
    if (fullName.isEmpty) {
      locator<PageProvider>().setPage(PageNames.home);
      nextRoute(MainPage.pageName, isClearBackRoutes: true, arguments: data['user_id']);
      return;
    }

    // Step 3 hidden (it returns token and saves name in AppData in your AuthenticationService.registerStep3)
    final ok = await AuthenticationService.registerStep3(
      data['user_id'],
      fullName,
      '', // referral code (مش مستخدم هنا)
    );

    if (ok) {
      locator<PageProvider>().setPage(PageNames.home);
      nextRoute(MainPage.pageName, isClearBackRoutes: true, arguments: data['user_id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return directionality(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.introBgPng,
                width: getSize().width,
                height: getSize().height,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.clear,
                color: isLightMode() ? null : greyFA,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: padding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    space(getSize().height * .11),

                    // title
                    Row(
                      children: [
                        Text(
                          appText.accountVerification,
                          style: style24Bold(),
                        ),
                        space(0, width: 4),
                        SvgPicture.asset(AppAssets.emoji2Svg)
                      ],
                    ),

                    // desc
                    Text(
                      appText.accountVerificationDesc,
                      style: style14Regular().copyWith(color: greyA5),
                    ),

                    const Spacer(),

                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RegisterWidget.codeInput(controller1, codeNode1, codeNode2, null, onPastedCode),
                          space(0, width: 10),
                          RegisterWidget.codeInput(controller2, codeNode2, codeNode3, codeNode1, onPastedCode),
                          space(0, width: 10),
                          RegisterWidget.codeInput(controller3, codeNode3, codeNode4, codeNode2, onPastedCode),
                          space(0, width: 10),
                          RegisterWidget.codeInput(controller4, codeNode4, codeNode5, codeNode3, onPastedCode),
                          space(0, width: 10),
                          RegisterWidget.codeInput(controller5, codeNode5, null, codeNode4, onPastedCode),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: button(
                        onTap: () async {
                          if (isEmptyInputs) return;

                          final code = getCode();
                          if (code.length != 5) return;

                          setState(() => isSendingData = true);

                          final res = await AuthenticationService.verifyCode(data['user_id'], code);

                          if (res) {
                            if (Platform.isAndroid) {
                              await FirebaseMessaging.instance.deleteToken();
                            }

                            // ✅ IMPORTANT: Step 3 UI is removed.
                            // We'll finalize silently by calling step3 hidden to get token.
                            AppData.canShowFinalizeSheet = false;

                            await _finalizeHiddenAndGoHome();
                          }

                          setState(() => isSendingData = false);
                        },
                        width: getSize().width,
                        height: 52,
                        text: appText.verifyMyAccount,
                        bgColor: isEmptyInputs ? greyCF : green77(),
                        textColor: Colors.white,
                        borderColor: Colors.transparent,
                        isLoading: isSendingData,
                      ),
                    ),

                    space(16),

                    Center(
                      child: Text(
                        appText.haventReceiveTheCode,
                        style: style14Regular().copyWith(color: greyB2),
                      ),
                    ),

                    Center(
                      child: isCodeAgain
                          ? loading()
                          : GestureDetector(
                              onTap: () async {
                                setState(() => isCodeAgain = true);

                                // ✅ resend by re-calling step 1
                                // keep same args + include full_name if available
                                final fullName = _getFullNameFromArgs();

                                Map? res;

                                if (PublicData.apiConfigData['register_method'] == 'email') {
                                  res = await AuthenticationService.registerWithEmail(
                                    PublicData.apiConfigData?['register_method'],
                                    data['email'],
                                    data['password'],
                                    data['retypePassword'],
                                    data['accountType'] ?? 'user',
                                    [],
                                    // ✅ If your service supports extraData, pass it:
                                    extraData: {
                                      if (fullName.isNotEmpty) 'full_name': fullName,
                                      // لو عندك guardian info في data وتحب تبعته هنا، ضيفه
                                      if (data['guardian_name'] != null) 'guardian_name': data['guardian_name'],
                                      if (data['guardian_country_code'] != null)
                                        'guardian_country_code': data['guardian_country_code'],
                                      if (data['guardian_mobile'] != null) 'guardian_mobile': data['guardian_mobile'],
                                    },
                                  );
                                } else {
                                  res = await AuthenticationService.registerWithPhone(
                                    PublicData.apiConfigData?['register_method'],
                                    data['countryCode'],
                                    data['phone'],
                                    data['password'],
                                    data['retypePassword'],
                                    data['accountType'] ?? 'user',
                                    [],
                                    extraData: {
                                      if (fullName.isNotEmpty) 'full_name': fullName,
                                      if (data['guardian_name'] != null) 'guardian_name': data['guardian_name'],
                                      if (data['guardian_country_code'] != null)
                                        'guardian_country_code': data['guardian_country_code'],
                                      if (data['guardian_mobile'] != null) 'guardian_mobile': data['guardian_mobile'],
                                    },
                                  );
                                }

                                if (res != null) {
                                  _clearCodeInputs();
                                }

                                setState(() => isCodeAgain = false);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                appText.resendCode,
                                style: style16Regular(),
                              ),
                            ),
                    ),

                    const Spacer(),
                    const Spacer(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
