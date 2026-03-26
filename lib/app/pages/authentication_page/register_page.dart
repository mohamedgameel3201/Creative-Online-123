import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webinar/app/models/register_config_model.dart';
import 'package:webinar/app/pages/authentication_page/login_page.dart';
import 'package:webinar/app/pages/authentication_page/verify_code_page.dart';
import 'package:webinar/app/pages/main_page/home_page/single_course_page/single_content_page/web_view_page.dart';
import 'package:webinar/app/pages/main_page/main_page.dart';
import 'package:webinar/app/services/authentication_service/authentication_service.dart';
import 'package:webinar/app/services/guest_service/guest_service.dart';
import 'package:webinar/app/widgets/authentication_widget/auth_widget.dart';
import 'package:webinar/app/widgets/authentication_widget/country_code_widget/code_country.dart';
import 'package:webinar/app/widgets/authentication_widget/register_widget/register_widget.dart';
import 'package:webinar/app/widgets/main_widget/main_widget.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/data/api_public_data.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/common/utils/constants.dart';
import 'package:webinar/config/styles.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../common/enums/page_name_enum.dart';
import '../../../config/assets.dart';
import '../../../config/colors.dart';
import '../../../common/components.dart';
import '../../../locator.dart';
import '../../providers/page_provider.dart';

class RegisterPage extends StatefulWidget {
  static const String pageName = '/register';
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController mailController = TextEditingController();
  FocusNode mailNode = FocusNode();

  // (this is used ONLY when register method is phone)
  TextEditingController phoneController = TextEditingController();
  FocusNode phoneNode = FocusNode();

  // ✅ Additional user phone (NOW REQUIRED)
  TextEditingController userPhoneController = TextEditingController();
  FocusNode userPhoneNode = FocusNode();

  // ✅ Additional user phone country code (DEFAULT = EGYPT)
  CountryCode userPhoneCountryCode = CountryCode(
    code: "EG",
    dialCode: "+20",
    flagUri: "${AppAssets.flags}eg.png",
    name: "Egypt",
  );

  // ✅ Name fields (Step 1)
  TextEditingController firstNameController = TextEditingController();
  FocusNode firstNameNode = FocusNode();

  TextEditingController middleNameController = TextEditingController();
  FocusNode middleNameNode = FocusNode();

  TextEditingController lastNameController = TextEditingController();
  FocusNode lastNameNode = FocusNode();

  TextEditingController passwordController = TextEditingController();
  FocusNode passwordNode = FocusNode();

  TextEditingController retypePasswordController = TextEditingController();
  FocusNode retypePasswordNode = FocusNode();

  // ✅ Guardian fields (Student only)
  TextEditingController guardianNameController = TextEditingController();
  FocusNode guardianNameNode = FocusNode();

  TextEditingController guardianPhoneController = TextEditingController();
  FocusNode guardianPhoneNode = FocusNode();

  bool isEmptyInputs = true;
  bool isPhoneNumber = true;
  bool isSendingData = false;

  // ✅ DEFAULT = EGYPT
  CountryCode countryCode = CountryCode(
    code: "EG",
    dialCode: "+20",
    flagUri: "${AppAssets.flags}eg.png",
    name: "Egypt",
  );

  // ✅ Guardian country code (DEFAULT = EGYPT)
  CountryCode guardianCountryCode = CountryCode(
    code: "EG",
    dialCode: "+20",
    flagUri: "${AppAssets.flags}eg.png",
    name: "Egypt",
  );

  // user / teacher / organization
  String accountType = 'user';
  bool isLoadingAccountType = false;

  String? otherRegisterMethod;
  RegisterConfigModel? registerConfig;

  List<dynamic> selectRolesDuringRegistration = [];

  @override
  void initState() {
    super.initState();

    if (PublicData.apiConfigData['selectRolesDuringRegistration'] != null) {
      selectRolesDuringRegistration =
          ((PublicData.apiConfigData['selectRolesDuringRegistration']) as List<dynamic>).toList();
    }

    if ((PublicData.apiConfigData?['register_method'] ?? '') == 'email') {
      isPhoneNumber = false;
      otherRegisterMethod = 'email';
    } else {
      isPhoneNumber = true;
      otherRegisterMethod = 'phone';
    }

    // ✅ Recalculate button state on any input change
    mailController.addListener(_recalcEmptyInputs);
    phoneController.addListener(_recalcEmptyInputs);
    passwordController.addListener(_recalcEmptyInputs);
    retypePasswordController.addListener(_recalcEmptyInputs);

    // ✅ name listeners
    firstNameController.addListener(_recalcEmptyInputs);
    middleNameController.addListener(_recalcEmptyInputs);
    lastNameController.addListener(_recalcEmptyInputs);

    // ✅ guardian listeners
    guardianNameController.addListener(_recalcEmptyInputs);
    guardianPhoneController.addListener(_recalcEmptyInputs);

    // ✅ user phone listener (NOW REQUIRED)
    userPhoneController.addListener(_recalcEmptyInputs);

    getAccountTypeFileds();
    _recalcEmptyInputs();
  }

  @override
  void dispose() {
    mailController.dispose();
    phoneController.dispose();
    userPhoneController.dispose();

    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();

    passwordController.dispose();
    retypePasswordController.dispose();

    guardianNameController.dispose();
    guardianPhoneController.dispose();

    mailNode.dispose();
    phoneNode.dispose();
    userPhoneNode.dispose();

    firstNameNode.dispose();
    middleNameNode.dispose();
    lastNameNode.dispose();

    passwordNode.dispose();
    retypePasswordNode.dispose();

    guardianNameNode.dispose();
    guardianPhoneNode.dispose();

    super.dispose();
  }

  bool get _isStudent => accountType == PublicData.userRole;

  // ✅ safe getter with fallback
  String _t(String? value, String fallback) => (value != null && value.isNotEmpty) ? value : fallback;

  // ✅ build full name from 3 fields
  String _buildFullName() {
    final parts = <String>[
      firstNameController.text.trim(),
      middleNameController.text.trim(),
      lastNameController.text.trim(),
    ].where((e) => e.isNotEmpty).toList();

    return parts.join(' ');
  }

  void _recalcEmptyInputs() {
    final hasUserNameOrPhone =
        mailController.text.trim().isNotEmpty || phoneController.text.trim().isNotEmpty;

    final hasPasswords =
        passwordController.text.trim().isNotEmpty && retypePasswordController.text.trim().isNotEmpty;

    final hasName = firstNameController.text.trim().isNotEmpty &&
        middleNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty;

    // ✅ NOW REQUIRED: user phone
    final hasUserPhone = userPhoneController.text.trim().isNotEmpty;

    bool ok = hasUserNameOrPhone && hasPasswords && hasName && hasUserPhone;

    // ✅ if student -> guardian required too
    if (_isStudent) {
      ok = ok &&
          guardianNameController.text.trim().isNotEmpty &&
          guardianPhoneController.text.trim().isNotEmpty;
    }

    final newIsEmpty = !ok;

    if (newIsEmpty != isEmptyInputs) {
      setState(() {
        isEmptyInputs = newIsEmpty;
      });
    }
  }

  void _resetGuardianFields() {
    guardianNameController.clear();
    guardianPhoneController.clear();

    // ✅ DEFAULT = EGYPT
    guardianCountryCode = CountryCode(
      code: "EG",
      dialCode: "+20",
      flagUri: "${AppAssets.flags}eg.png",
      name: "Egypt",
    );
  }

  getAccountTypeFileds() async {
    setState(() {
      isLoadingAccountType = true;
    });

    registerConfig = await GuestService.registerConfig(accountType);

    setState(() {
      isLoadingAccountType = false;
    });
  }

  Future<void> _submit() async {
    if (isEmptyInputs) return;

    final fullName = _buildFullName();
    if (fullName.length < 3) {
      showSnackBar(ErrorEnum.alert, 'Please enter your full name');
      return;
    }

    // ✅ user phone REQUIRED validation
    if (userPhoneController.text.trim().isEmpty) {
      showSnackBar(ErrorEnum.alert, 'Please enter your phone number');
      return;
    }

    // validate dynamic fields
    if (registerConfig?.formFields?.fields != null) {
      for (var i = 0; i < (registerConfig?.formFields?.fields?.length ?? 0); i++) {
        if (registerConfig?.formFields?.fields?[i].isRequired == 1 &&
            registerConfig?.formFields?.fields?[i].userSelectedData == null) {
          if (registerConfig?.formFields?.fields?[i].type != 'toggle') {
            showSnackBar(
              ErrorEnum.alert,
              '${appText.pleaseReview} ${registerConfig?.formFields?.fields?[i].getTitle()}',
            );
            return;
          }
        }
      }
    }

    // ✅ guardian validation (student only)
    if (_isStudent) {
      if (guardianNameController.text.trim().isEmpty) {
        showSnackBar(
          ErrorEnum.alert,
          _t(appText.pleaseEnterGuardianName, 'Please enter guardian name'),
        );
        return;
      }
      if (guardianPhoneController.text.trim().isEmpty) {
        showSnackBar(
          ErrorEnum.alert,
          _t(appText.pleaseEnterGuardianMobile, 'Please enter guardian mobile'),
        );
        return;
      }
    }

    if (passwordController.text.trim() != retypePasswordController.text.trim()) {
      showSnackBar(
        ErrorEnum.alert,
        _t(appText.passwordNotMatch, 'Password does not match'),
      );
      return;
    }

    setState(() {
      isSendingData = true;
    });

    // ✅ extraData sent to API (guardian + full_name + REQUIRED user phone)
    Map<String, dynamic> extraData = {
      'full_name': fullName,

      // ✅ REQUIRED user phone saved in user_meta
      'user_country_code': userPhoneCountryCode.dialCode.toString(),
      'user_mobile': userPhoneController.text.trim(),
    };

    if (_isStudent) {
      extraData.addAll({
        'guardian_name': guardianNameController.text.trim(),
        'guardian_country_code': guardianCountryCode.dialCode.toString(),
        'guardian_mobile': guardianPhoneController.text.trim(),
      });
    }

    if (otherRegisterMethod == 'email') {
      Map? res = await AuthenticationService.registerWithEmail(
        otherRegisterMethod!,
        mailController.text.trim(),
        passwordController.text.trim(),
        retypePasswordController.text.trim(),
        accountType,
        registerConfig?.formFields?.fields,
        extraData: extraData,
      );

      if (res != null) {
        if (registerConfig?.disableRegistrationVerification ?? false) {
          locator<PageProvider>().setPage(PageNames.home);
          nextRoute(MainPage.pageName, arguments: res['user_id']);
        } else {
          if (res['step'] == 'stored' || res['step'] == 'go_step_2') {
            nextRoute(VerifyCodePage.pageName, arguments: {
              'user_id': res['user_id'],
              'email': mailController.text.trim(),
              'password': passwordController.text.trim(),
              'retypePassword': retypePasswordController.text.trim(),
              'full_name': fullName,
              'accountType': accountType,
              if (_isStudent) ...{
                'guardian_name': guardianNameController.text.trim(),
                'guardian_country_code': guardianCountryCode.dialCode.toString(),
                'guardian_mobile': guardianPhoneController.text.trim(),
              },
            });
          } else if (res['step'] == 'go_step_3') {
            AppData.canShowFinalizeSheet = true;
            locator<PageProvider>().setPage(PageNames.home);
            nextRoute(MainPage.pageName, arguments: res['user_id']);
          }
        }
      }
    } else {
      Map? res = await AuthenticationService.registerWithPhone(
        otherRegisterMethod!,
        countryCode.dialCode.toString(),
        phoneController.text.trim(),
        passwordController.text.trim(),
        retypePasswordController.text.trim(),
        accountType,
        registerConfig?.formFields?.fields,
        extraData: extraData,
      );

      if (res != null) {
        if (registerConfig?.disableRegistrationVerification ?? false) {
          locator<PageProvider>().setPage(PageNames.home);
          nextRoute(MainPage.pageName, arguments: res['user_id']);
        } else {
          if (res['step'] == 'stored' || res['step'] == 'go_step_2') {
            nextRoute(VerifyCodePage.pageName, arguments: {
              'user_id': res['user_id'],
              'countryCode': countryCode.dialCode.toString(),
              'phone': phoneController.text.trim(),
              'password': passwordController.text.trim(),
              'retypePassword': retypePasswordController.text.trim(),
              'full_name': fullName,
              'accountType': accountType,
              if (_isStudent) ...{
                'guardian_name': guardianNameController.text.trim(),
                'guardian_country_code': guardianCountryCode.dialCode.toString(),
                'guardian_mobile': guardianPhoneController.text.trim(),
              },
            });
          } else if (res['step'] == 'go_step_3') {
            AppData.canShowFinalizeSheet = true;
            locator<PageProvider>().setPage(PageNames.home);
            nextRoute(MainPage.pageName, arguments: res['user_id']);
          }
        }
      }
    }

    setState(() {
      isSendingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (re) {
        MainWidget.showExitDialog();
      },
      child: directionality(
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: padding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      space(getSize().height * .11),
                      Row(
                        children: [
                          Text(appText.createAccount, style: style24Bold()),
                          space(0, width: 4),
                          SvgPicture.asset(AppAssets.emoji2Svg),
                        ],
                      ),
                      Text(
                        appText.createAccountDesc,
                        style: style14Regular().copyWith(color: greyA5),
                      ),
                      space(50),

                      if (selectRolesDuringRegistration.contains(PublicData.teacherRole) &&
                          selectRolesDuringRegistration.contains(PublicData.organizationRole)) ...{
                        Text(
                          appText.accountType,
                          style: style14Regular().copyWith(color: greyB2),
                        ),
                        space(8),
                        Container(
                          decoration: BoxDecoration(
                            color: whiteFF_26,
                            borderRadius: borderRadius(),
                          ),
                          width: getSize().width,
                          height: 52,
                          child: Row(
                            children: [
                              AuthWidget.accountTypeWidget(
                                appText.student,
                                accountType,
                                PublicData.userRole,
                                () {
                                  setState(() {
                                    accountType = PublicData.userRole;
                                  });
                                  _recalcEmptyInputs();
                                  getAccountTypeFileds();
                                },
                              ),
                              if (selectRolesDuringRegistration.contains(PublicData.teacherRole)) ...{
                                AuthWidget.accountTypeWidget(
                                  appText.instrcutor,
                                  accountType,
                                  PublicData.teacherRole,
                                  () {
                                    setState(() {
                                      accountType = PublicData.teacherRole;
                                    });
                                    _resetGuardianFields();
                                    _recalcEmptyInputs();
                                    getAccountTypeFileds();
                                  },
                                ),
                              },
                              if (selectRolesDuringRegistration.contains(PublicData.organizationRole)) ...{
                                AuthWidget.accountTypeWidget(
                                  appText.organization,
                                  accountType,
                                  PublicData.organizationRole,
                                  () {
                                    setState(() {
                                      accountType = PublicData.organizationRole;
                                    });
                                    _resetGuardianFields();
                                    _recalcEmptyInputs();
                                    getAccountTypeFileds();
                                  },
                                ),
                              },
                            ],
                          ),
                        ),
                      },

                      if (registerConfig?.showOtherRegisterMethod != null) ...{
                        space(15),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: borderRadius(),
                          ),
                          width: getSize().width,
                          height: 52,
                          child: Row(
                            children: [
                              AuthWidget.accountTypeWidget(
                                appText.email,
                                otherRegisterMethod ?? '',
                                'email',
                                () {
                                  setState(() {
                                    otherRegisterMethod = 'email';
                                    isPhoneNumber = false;
                                  });
                                  _recalcEmptyInputs();
                                },
                              ),
                              AuthWidget.accountTypeWidget(
                                appText.phone,
                                otherRegisterMethod ?? '',
                                'phone',
                                () {
                                  setState(() {
                                    otherRegisterMethod = 'phone';
                                    isPhoneNumber = true;
                                  });
                                  _recalcEmptyInputs();
                                },
                              ),
                            ],
                          ),
                        ),
                      },

                      space(13),

                      if (isPhoneNumber) ...{
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                CountryCode? newData = await RegisterWidget.showCountryDialog();
                                if (newData != null) {
                                  setState(() {
                                    countryCode = newData;
                                  });
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: whiteFF_26,
                                  borderRadius: borderRadius(),
                                ),
                                alignment: Alignment.center,
                                child: ClipRRect(
                                  borderRadius: borderRadius(radius: 50),
                                  child: Image.asset(
                                    countryCode.flagUri ?? '',
                                    width: 21,
                                    height: 19,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            space(0, width: 15),
                            Expanded(
                              child: input(phoneController, phoneNode, appText.phoneNumber),
                            )
                          ],
                        )
                      } else ...{
                        input(
                          mailController,
                          mailNode,
                          appText.yourEmail,
                          iconPathLeft: AppAssets.mailSvg,
                          leftIconSize: 14,
                        ),
                      },

                      // ✅ Additional user phone (NOW REQUIRED)
                      space(16),
                      Text(
                        appText.phoneNumber, // ✅ localized (no fixed string)
                        style: style14Regular().copyWith(color: greyB2),
                      ),
                      space(8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              CountryCode? newData = await RegisterWidget.showCountryDialog();
                              if (newData != null) {
                                setState(() {
                                  userPhoneCountryCode = newData;
                                });
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: whiteFF_26,
                                borderRadius: borderRadius(),
                              ),
                              alignment: Alignment.center,
                              child: ClipRRect(
                                borderRadius: borderRadius(radius: 50),
                                child: Image.asset(
                                  userPhoneCountryCode.flagUri ?? '',
                                  width: 21,
                                  height: 19,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          space(0, width: 15),
                          Expanded(
                            child: input(
                              userPhoneController,
                              userPhoneNode,
                              appText.phoneNumber, // ✅ localized (no fixed string)
                            ),
                          )
                        ],
                      ),

                      // ✅ Name fields in Step 1
                      space(16),
                      input(firstNameController, firstNameNode, 'First name'),
                      space(16),
                      input(middleNameController, middleNameNode, 'Middle name'),
                      space(16),
                      input(lastNameController, lastNameNode, 'Last name'),

                      space(16),
                      input(
                        passwordController,
                        passwordNode,
                        appText.password,
                        iconPathLeft: AppAssets.passwordSvg,
                        leftIconSize: 14,
                        isPassword: true,
                      ),

                      space(16),
                      input(
                        retypePasswordController,
                        retypePasswordNode,
                        appText.retypePassword,
                        iconPathLeft: AppAssets.passwordSvg,
                        leftIconSize: 14,
                        isPassword: true,
                      ),

                      // ✅ Guardian Fields (Student only)
                      if (_isStudent) ...[
                        space(16),
                        Text(
                          _t(appText.guardianInfoTitle, 'Guardian Info'),
                          style: style14Regular().copyWith(color: greyB2),
                        ),
                        space(8),
                        input(
                          guardianNameController,
                          guardianNameNode,
                          _t(appText.guardianName, 'Guardian Name'),
                        ),
                        space(16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                CountryCode? newData = await RegisterWidget.showCountryDialog();
                                if (newData != null) {
                                  setState(() {
                                    guardianCountryCode = newData;
                                  });
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: whiteFF_26,
                                  borderRadius: borderRadius(),
                                ),
                                alignment: Alignment.center,
                                child: ClipRRect(
                                  borderRadius: borderRadius(radius: 50),
                                  child: Image.asset(
                                    guardianCountryCode.flagUri ?? '',
                                    width: 21,
                                    height: 19,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            space(0, width: 15),
                            Expanded(
                              child: input(
                                guardianPhoneController,
                                guardianPhoneNode,
                                _t(appText.guardianMobile, 'Guardian Mobile'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      isLoadingAccountType
                          ? loading()
                          : Column(
                              children: [
                                ...List.generate(
                                  registerConfig?.formFields?.fields?.length ?? 0,
                                  (index) =>
                                      registerConfig?.formFields?.fields?[index].getWidget() ??
                                      const SizedBox(),
                                )
                              ],
                            ),

                      space(32),

                      Center(
                        child: button(
                          onTap: _submit,
                          width: getSize().width,
                          height: 52,
                          text: appText.createAnAccount,
                          bgColor: isEmptyInputs ? greyCF : green77(),
                          textColor: Colors.white,
                          borderColor: Colors.transparent,
                          isLoading: isSendingData,
                        ),
                      ),

                      space(16),

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            nextRoute(WebViewPage.pageName, arguments: [
                              '${Constants.dommain}/pages/app-terms',
                              appText.webinar,
                              false,
                              LoadRequestMethod.get
                            ]);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            appText.termsPoliciesDesc,
                            style: style14Regular().copyWith(color: greyA5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      space(80),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(appText.haveAnAccount, style: style16Regular()),
                          space(0, width: 2),
                          GestureDetector(
                            onTap: () {
                              nextRoute(LoginPage.pageName, isClearBackRoutes: true);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Text(appText.login, style: style16Regular()),
                          )
                        ],
                      ),

                      space(25),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget socialWidget(String icon, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 98,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: whiteFF_26,
          borderRadius: borderRadius(radius: 16),
        ),
        child: SvgPicture.asset(icon, width: 30),
      ),
    );
  }
}
