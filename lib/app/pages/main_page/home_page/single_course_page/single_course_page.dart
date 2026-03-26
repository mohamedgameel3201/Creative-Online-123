import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webinar/app/models/course_model.dart';
import 'package:webinar/app/models/single_course_model.dart';
import 'package:webinar/app/pages/authentication_page/login_page.dart';
import 'package:webinar/app/pages/main_page/home_page/single_course_page/learning_page.dart';
import 'package:webinar/app/providers/user_provider.dart';
import 'package:webinar/app/services/guest_service/course_service.dart';
import 'package:webinar/app/services/user_service/cart_service.dart';
import 'package:webinar/app/services/user_service/purchase_service.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/pod_video_player.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/course_video_player.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/single_course_widget.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/special_offer_widget.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/data/api_public_data.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/common/utils/constants.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';
import 'package:webinar/locator.dart';

import '../../../../../common/utils/currency_utils.dart';
import '../../../../models/content_model.dart';
import '../../../../widgets/main_widget/blog_widget/blog_widget.dart';

// ✅ صفحة إدخال كود الكورس
import 'course_code_page.dart';

class SingleCoursePage extends StatefulWidget {
  static const String pageName = '/single-course';
  const SingleCoursePage({super.key});

  @override
  State<SingleCoursePage> createState() => _SingleCoursePageState();
}

class _SingleCoursePageState extends State<SingleCoursePage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isPrivate = false;

  bool isEnrollLoading = false;
  bool isSubscribeLoading = false;
  bool viewMore = false;

  SingleCourseModel? courseData;

  late TabController tabController;
  int currentTab = 0;

  bool showInformationButton = false;
  bool showContentButton = false;
  bool canSubmitComment = false;
  bool canSubmitReview = false;

  String token = '';

  final ScrollController scrollController = ScrollController();
  bool isBundleCourse = false;

  List<CourseModel> bundleCourses = [];
  List<ContentModel> contentData = [];

  int? commentId;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 4, vsync: this);
    getData();

    scrollController.addListener(() {
      if (scrollController.position.pixels > 250) {
        if (currentTab == 0) {
          if (!showInformationButton) {
            offAllTabs();
            setState(() {
              showInformationButton = true;
            });
          }
        }
      }
    });

    tabController.addListener(() {
      if (tabController.index == 0) {
        if (!showInformationButton) {
          offAllTabs();
          setState(() => showInformationButton = true);
        }
      }

      if (tabController.index == 1) {
        if (!showContentButton) {
          offAllTabs();
          setState(() => showContentButton = true);
        }
      }

      if (tabController.index == 2) {
        if (!canSubmitReview) {
          offAllTabs();
          setState(() => canSubmitReview = true);
        }
      }

      if (tabController.index == 3) {
        if (!canSubmitComment) {
          offAllTabs();
          setState(() => canSubmitComment = true);
        }
      }
    });
  }

  void offAllTabs() {
    showContentButton = false;
    showInformationButton = false;
    canSubmitReview = false;
    canSubmitComment = false;
  }

  void onChangeTab(int i) {
    setState(() => currentTab = i);
  }

  Future<void> getData() async {
    token = await AppData.getAccessToken();

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // ignore_for_file: use_build_context_synchronously
    final args = (ModalRoute.of(context)!.settings.arguments as List);

    int id = courseData?.id ?? args[0];
    isBundleCourse = courseData != null ? courseData?.type == 'bundle' : args[1];

    try {
      commentId = commentId ?? args[2];
    } catch (_) {}

    try {
      isPrivate = args[3];
    } catch (_) {}

    log('is Bundle: $isBundleCourse - id: $id');

    courseData = await CourseService.getSingleCourseData(
      id,
      isBundleCourse,
      isPrivate: isPrivate,
    );

    if (courseData != null && isBundleCourse) {
      await getBundleCourses();
    }

    if (!isBundleCourse) {
      await getContent();
    }

    if (commentId != null) {
      await showComment();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getContent() async {
    contentData = await CourseService.getContent(courseData!.id!);
    setState(() {});
  }

  Future<void> getBundleCourses() async {
    bundleCourses = await CourseService.bundleCourses(courseData!.id!);
    setState(() {});
  }

  Future<void> showComment() async {
    currentTab = 3;
    tabController.animateTo(3);

    Timer(const Duration(seconds: 2), () {
      for (var i = 0; i < (courseData?.comments.length ?? 0); i++) {
        if (commentId == courseData?.comments[i].id) {
          scrollController.animateTo(
            (courseData!.comments[i].globalKey.findWidget ?? 0.0) > 230
                ? (courseData!.comments[i].globalKey.findWidget ?? 0.0) - 230
                : 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.linearToEaseOut,
          );
        }
      }
      commentId = null;
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ✅ لازم يكون هنا (داخل build) مش جوّا الـ children
    final bool isFree = (courseData?.price ?? 0) == 0;

    return directionality(
      child: Scaffold(
        appBar: appbar(
          title: appText.courseDetails,
          isBasket: true,
        ),
        body: isLoading
            ? loading()
            : courseData == null
                ? const SizedBox()
                : Stack(
                    children: [
                      Positioned.fill(
                        child: (token.isEmpty &&
                                (PublicData.apiConfigData?[
                                            'webinar_private_content_status'] ??
                                        '0') ==
                                    '1')
                            ? SingleCourseWidget.privateContent()
                            : (token.isNotEmpty &&
                                    (PublicData.apiConfigData?[
                                                'sequence_content_status'] ??
                                            '0') ==
                                        '1' &&
                                    locator<UserProvider>()
                                            .profile
                                            ?.accessContent ==
                                        0)
                                ? SingleCourseWidget.pendingVerification()
                                : NestedScrollView(
                                    controller: scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    floatHeaderSlivers: false,
                                    headerSliverBuilder:
                                        (context, innerBoxIsScrolled) {
                                      return [
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: padding(),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (courseData
                                                        ?.activeSpecialOffer !=
                                                    null) ...{
                                                  SpecialOfferWidget(
                                                    courseData?.activeSpecialOffer
                                                            ?.toDate ??
                                                        0,
                                                    courseData?.activeSpecialOffer
                                                            ?.percent
                                                            ?.toString() ??
                                                        '0',
                                                  ),
                                                },
                                                space(14),
                                                Text(courseData?.title ?? '',
                                                    style: style16Bold()),
                                                space(8),
                                                Row(
                                                  children: [
                                                    ratingBar(courseData?.rate
                                                            ?.toString() ??
                                                        '0'),
                                                    space(0, width: 4),
                                                    Container(
                                                      padding: padding(
                                                          horizontal: 6,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: greyE7,
                                                        borderRadius:
                                                            borderRadius(),
                                                      ),
                                                      child: Text(
                                                        courseData?.reviewsCount
                                                                ?.toString() ??
                                                            '',
                                                        style: style10Regular()
                                                            .copyWith(
                                                                color: greyB2),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                space(18),
                                                if (courseData?.videoDemo !=
                                                    null) ...{
                                                  if (courseData
                                                          ?.videoDemoSource ==
                                                      'vimeo') ...{
                                                    ClipRRect(
                                                      borderRadius:
                                                          borderRadius(),
                                                      child: fadeInImage(
                                                        courseData?.image ?? '',
                                                        getSize().width,
                                                        210,
                                                      ),
                                                    )
                                                  } else if (courseData
                                                          ?.videoDemoSource ==
                                                      'youtube') ...{
                                                    PodVideoPlayerDev(
                                                      courseData?.videoDemo ??
                                                          '',
                                                      courseData
                                                              ?.videoDemoSource ??
                                                          '',
                                                      Constants
                                                          .singleCourseRouteObserver,
                                                      ValueKey(courseData?.id),
                                                    ),
                                                  } else ...{
                                                    CourseVideoPlayer(
                                                      courseData?.videoDemo ??
                                                          '',
                                                      courseData?.imageCover ??
                                                          '',
                                                      Constants
                                                          .singleCourseRouteObserver,
                                                    )
                                                  }
                                                } else ...{
                                                  ClipRRect(
                                                    borderRadius:
                                                        borderRadius(),
                                                    child: fadeInImage(
                                                      courseData?.image ?? '',
                                                      getSize().width,
                                                      210,
                                                    ),
                                                  )
                                                },
                                                space(24),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    userProfile(
                                                        courseData!.teacher!,
                                                        showRate: true),
                                                    closeButton(
                                                      AppAssets.menuCircleSvg,
                                                      icColor: greyB2,
                                                      onTap: () {
                                                        SingleCourseWidget
                                                            .showOptionsDialog(
                                                          courseData!,
                                                          token,
                                                          isBundle:
                                                              isBundleCourse,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                if ((courseData?.authHasBought ==
                                                        false) &&
                                                    (courseData?.cashbackRules
                                                            .isNotEmpty ??
                                                        false)) ...{
                                                  space(16),
                                                  helperBox(
                                                    AppAssets.walletSvg,
                                                    appText.getCashback,
                                                    '${isBundleCourse ? appText.purchaseThisProductAndGet : appText.purchaseThisCourseAndGet}'
                                                    '${courseData?.cashbackRules.first.amountType == 'percent' ? '%${courseData!.cashbackRules.first.amount ?? 0}' : CurrencyUtils.calculator(courseData!.cashbackRules.first.amount ?? 0)} '
                                                    '${appText.cashback}',
                                                    horizontalPadding: 0,
                                                  ),
                                                },
                                              ],
                                            ),
                                          ),
                                        ),
                                        SliverAppBar(
                                          pinned: true,
                                          centerTitle: true,
                                          automaticallyImplyLeading: false,
                                          backgroundColor:
                                              Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                          shadowColor: Theme.of(context)
                                              .scaffoldBackgroundColor
                                              .withOpacity(.2),
                                          elevation: 10,
                                          titleSpacing: 0,
                                          title: tabBar(onChangeTab,
                                              tabController, [
                                            Tab(
                                                text: appText.information,
                                                height: 32),
                                            Tab(
                                                text: appText.content,
                                                height: 32),
                                            Tab(
                                                text: appText.reviews,
                                                height: 32),
                                            Tab(
                                                text: appText.comments,
                                                height: 32),
                                          ]),
                                        ),
                                      ];
                                    },
                                    body: TabBarView(
                                      physics: const BouncingScrollPhysics(),
                                      controller: tabController,
                                      children: [
                                        SingleCourseWidget.informationPage(
                                          courseData!,
                                          viewMore,
                                          () => setState(
                                              () => viewMore = !viewMore),
                                          () => setState(() {}),
                                          bundleCourses: bundleCourses,
                                        ),
                                        SingleCourseWidget.contentPage(
                                          courseData!,
                                          contentData,
                                          bundleCourses: bundleCourses,
                                        ),
                                        SingleCourseWidget.reviewsPage(
                                            courseData!),
                                        SingleCourseWidget.commentsPage(
                                            courseData!),
                                      ],
                                    ),
                                  ),
                      ),

                      // ✅ لو محتوى خاص ومحتاج تسجيل دخول
                      if ((token.isEmpty &&
                          (PublicData.apiConfigData?[
                                      'webinar_private_content_status'] ??
                                  '0') ==
                              '1')) ...{
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          bottom: 0,
                          child: Container(
                            width: getSize().width,
                            padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 20,
                                bottom: 30),
                            decoration: BoxDecoration(
                              color: whiteFF_26,
                              boxShadow: [
                                boxShadow(Colors.black.withOpacity(.1),
                                    blur: 15, y: -3)
                              ],
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30)),
                            ),
                            child: button(
                              onTap: () async {
                                nextRoute(LoginPage.pageName,
                                    isClearBackRoutes: true);
                              },
                              width: getSize().width,
                              height: 52,
                              text: appText.login,
                              bgColor: green77(),
                              textColor: Colors.white,
                            ),
                          ),
                        ),
                      } else ...{
                        // ✅ Bottom Actions
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          bottom: showInformationButton ? 0 : -150,
                          child: Container(
                            width: getSize().width,
                            padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 20,
                                bottom: 30),
                            decoration: BoxDecoration(
                              color: whiteFF_26,
                              boxShadow: [
                                boxShadow(Colors.black.withOpacity(.1),
                                    blur: 15, y: -3)
                              ],
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30)),
                            ),
                            child: Column(
                              children: [
                                if ((courseData?.authHasBought == false)) ...{
                                  if (token.isNotEmpty) ...{
                                    // السعر
                                    Row(
                                      children: [
                                        Text(appText.price,
                                            style: style14Regular()),
                                        const Spacer(),
                                        Text(
                                          ((courseData?.price ?? 0) == 0)
                                              ? appText.free
                                              : CurrencyUtils.calculator(
                                                  courseData!.price ?? 0),
                                          style: style12Regular().copyWith(
                                            color: (courseData!
                                                            .discountPercent ??
                                                        0) >
                                                    0
                                                ? greyCF
                                                : green77(),
                                            decoration:
                                                (courseData!.discountPercent ??
                                                            0) >
                                                        0
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : TextDecoration.none,
                                            decorationColor: (courseData!
                                                            .discountPercent ??
                                                        0) >
                                                    0
                                                ? greyCF
                                                : green77(),
                                          ),
                                        ),
                                        if ((courseData!.discountPercent ??
                                                0) >
                                            0) ...{
                                          space(0, width: 8),
                                          Text(
                                            CurrencyUtils.calculator(
                                              (courseData!.price ?? 0) -
                                                  ((courseData!.price ?? 0) *
                                                          (courseData!
                                                                  .discountPercent ??
                                                              0) ~/
                                                      100),
                                            ),
                                            style: style14Regular()
                                                .copyWith(color: green77()),
                                          ),
                                        },
                                      ],
                                    ),
                                    space(16),

                                    // ✅ منطق الأزرار:
                                    // - مجاني: Enroll
                                    // - مدفوع: Redeem With Code
                                    if (isFree) ...{
                                      button(
                                        onTap: () async {
                                          setState(
                                              () => isEnrollLoading = true);

                                          final bool res = isBundleCourse
                                              ? await PurchaseService
                                                  .bundlesFree(courseData!.id!)
                                              : await PurchaseService
                                                  .courseFree(courseData!.id!);

                                          if (res) {
                                            await getData();
                                          }

                                          if (mounted) {
                                            setState(() =>
                                                isEnrollLoading = false);
                                          }
                                        },
                                        width: getSize().width,
                                        height: 52,
                                        text: appText.enrollOnClass,
                                        bgColor: green77(),
                                        textColor: Colors.white,
                                        isLoading: isEnrollLoading,
                                      ),
                                    } else ...{
                                      button(
                                        onTap: () async {
                                          final result =
                                              await Navigator.pushNamed(
                                            context,
                                            CourseCodePage.pageName,
                                            arguments: [courseData!.id],
                                          );

                                          if (result == true) {
                                            await getData();
                                          }
                                        },
                                        width: getSize().width,
                                        height: 52,
                                        text: appText.redeemWithCode,
                                        bgColor: green77(),
                                        textColor: Colors.white,
                                      ),
                                    },
                                  } else ...{
                                    button(
                                      onTap: () {
                                        nextRoute(LoginPage.pageName,
                                            isClearBackRoutes: true);
                                      },
                                      width: getSize().width,
                                      height: 53,
                                      text: appText.login,
                                      bgColor: green77(),
                                      textColor: Colors.white,
                                    ),
                                  }
                                } else ...{
                                  // ✅ مشتري -> Go To Learning
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${courseData?.progressPercent ?? 0}% ${appText.completed}',
                                        style: style10Regular()
                                            .copyWith(color: greyA5),
                                      ),
                                      space(6),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Container(
                                            width: constraints.maxWidth,
                                            height: 4,
                                            alignment:
                                                AlignmentDirectional
                                                    .centerStart,
                                            child: Container(
                                              width: ((courseData?.progressPercent ??
                                                          0) >
                                                      0)
                                                  ? constraints.maxWidth *
                                                      ((courseData?.progressPercent ??
                                                              0) /
                                                          100)
                                                  : 5,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: green77(),
                                                borderRadius: borderRadius(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      space(12),
                                      button(
                                        onTap: () {
                                          if (courseData?.type == 'bundle') {
                                            tabController.animateTo(1);
                                          } else {
                                            nextRoute(LearningPage.pageName,
                                                arguments: courseData);
                                          }
                                        },
                                        width: getSize().width,
                                        height: 52,
                                        text: appText.goToLearningPage,
                                        bgColor: green77(),
                                        textColor: Colors.white,
                                        raduis: 15,
                                      ),
                                    ],
                                  ),
                                },
                              ],
                            ),
                          ),
                        ),

                        if ((courseData?.authHasBought ?? false)) ...{
                          // write a review
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 350),
                            bottom: canSubmitReview ? 0 : -150,
                            child: Container(
                              width: getSize().width,
                              padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                  bottom: 30),
                              decoration: BoxDecoration(
                                color: whiteFF_26,
                                boxShadow: [
                                  boxShadow(Colors.black.withOpacity(.1),
                                      blur: 15, y: -3)
                                ],
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(30)),
                              ),
                              child: button(
                                onTap: () async {
                                  final bool? res =
                                      await SingleCourseWidget
                                          .showSetReviewDialog(courseData!);
                                  if (res != null && res) {
                                    getData();
                                  }
                                },
                                width: getSize().width,
                                height: 52,
                                text: appText.writeReview,
                                bgColor: green77(),
                                textColor: Colors.white,
                              ),
                            ),
                          ),
                        },

                        // leave a comment
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          bottom: canSubmitComment ? 0 : -150,
                          child: Container(
                            width: getSize().width,
                            padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 20,
                                bottom: 30),
                            decoration: BoxDecoration(
                              color: whiteFF_26,
                              boxShadow: [
                                boxShadow(Colors.black.withOpacity(.1),
                                    blur: 15, y: -3)
                              ],
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30)),
                            ),
                            child: button(
                              onTap: () async {
                                final bool? res =
                                    await BlogWidget.showReplayDialog(
                                  courseData!.id!,
                                  null,
                                  itemName:
                                      isBundleCourse ? 'bundle' : 'webinar',
                                );

                                if (res != null && res) {
                                  getData();
                                }
                              },
                              width: getSize().width,
                              height: 52,
                              text: appText.leaveAComment,
                              bgColor: green77(),
                              textColor: Colors.white,
                            ),
                          ),
                        ),
                      }
                    ],
                  ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    tabController.dispose();
    super.dispose();
  }
}

extension GlobalKeyExtension on GlobalKey {
  double? get findWidget {
    final box = currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final position = box.localToGlobal(Offset.zero);
    return position.dy;
  }
}
