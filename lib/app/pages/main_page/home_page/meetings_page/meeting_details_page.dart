import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webinar/app/pages/main_page/home_page/single_course_page/single_content_page/web_view_page.dart';
import 'package:webinar/app/services/user_service/meeting_service.dart';
import 'package:webinar/app/widgets/main_widget/meetings_widget/meetings_widget.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/common/utils/currency_utils.dart';
import 'package:webinar/common/utils/date_formater.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../config/assets.dart';
import '../../../../models/meeting_details_model.dart';
import '../../../../models/meeting_model.dart';
import '../../../../widgets/main_widget/home_widget/single_course_widget/single_course_widget.dart';

class MeetingDetailsPage extends StatefulWidget {
  static const String pageName = '/meeting-details';
  const MeetingDetailsPage({super.key});

  @override
  State<MeetingDetailsPage> createState() => _MeetingDetailsPageState();
}

class _MeetingDetailsPageState extends State<MeetingDetailsPage> {
  Meetings? meeting;
  MeetingDetailsModel? details;
  bool isConsultant = true;
  bool canCreateAgoraLink = false;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      meeting = (ModalRoute.of(context)!.settings.arguments as List)[0];
      isConsultant = (ModalRoute.of(context)!.settings.arguments as List)[1];
      canCreateAgoraLink = (ModalRoute.of(context)!.settings.arguments as List)[2];

      getData();
    });
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });

    details = await MeetingService.getMeetingDetails(meeting!.id!);

    setState(() {
      isLoading = false;
    });
  }

  bool _isZoomLink(String link) {
    final lower = link.toLowerCase();
    return lower.contains('zoom.us') ||
        lower.contains('zoom.com') ||
        lower.contains('zoomgov.com') ||
        lower.startsWith('zoomus://');
  }

  Future<void> _openMeeting() async {
    if (!(details?.meeting?.status == 'pending' ||
        details?.meeting?.status == 'open')) {
      return;
    }

    if (isConsultant &&
        (details?.meeting?.link == null && details?.meeting?.agoraLink == null)) {
      if (canCreateAgoraLink) {
        bool? res =
            await MeetingWidget.showCreateLinkSheet(details!.meeting!.id!, details!);

        if (res != null && res) {
          getData();
        }
      } else {
        bool? res = await MeetingWidget.setMeetingInfo(details!.meeting!.id!);

        if (res != null && res) {
          getData();
        }
      }
      return;
    }

    final bool isAgora = details?.meeting?.isAgora ?? false;
    String meetingLink = '';

    if (isAgora && (details?.meeting?.agoraLink ?? '').trim().isNotEmpty) {
      meetingLink = (details?.meeting?.agoraLink ?? '').trim();
    } else {
      meetingLink = (details?.meeting?.link ?? '').trim();
    }

    if (meetingLink.isEmpty) {
      showSnackBar(ErrorEnum.error, 'Meeting link is empty');
      return;
    }

    if (!meetingLink.startsWith('http://') &&
        !meetingLink.startsWith('https://') &&
        !meetingLink.startsWith('zoomus://')) {
      meetingLink = 'https://$meetingLink';
    }

    debugPrint('Meeting link => $meetingLink');
    debugPrint('isAgora => $isAgora');

    // افتح Zoom خارج التطبيق فقط
    if (_isZoomLink(meetingLink)) {
      final Uri? zoomUri = Uri.tryParse(meetingLink);

      if (zoomUri == null) {
        showSnackBar(ErrorEnum.error, 'Invalid Zoom meeting link');
        return;
      }

      final bool opened = await launchUrl(
        zoomUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        showSnackBar(ErrorEnum.error, 'Could not open Zoom meeting');
      }

      return;
    }

    // لو لينك Agora أو لينك داخلي محتاج WebView
    if (isAgora) {
      await nextRoute(
        WebViewPage.pageName,
        arguments: [
          meetingLink,
          appText.meeting,
          true,
          LoadRequestMethod.get,
        ],
      );
      return;
    }

    // باقي الروابط افتحها خارج التطبيق
    final Uri? uri = Uri.tryParse(meetingLink);

    if (uri == null) {
      showSnackBar(ErrorEnum.error, 'Invalid meeting link');
      return;
    }

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      showSnackBar(ErrorEnum.error, 'Could not open meeting link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return directionality(
      child: Scaffold(
        appBar: appbar(title: appText.meetingDetails),
        body: isLoading
            ? loading()
            : Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: padding(),
                      child: meeting == null
                          ? const SizedBox()
                          : Column(
                              children: [
                                space(20),

                                Container(
                                  width: 142,
                                  height: 142,
                                  decoration: BoxDecoration(
                                    color: whiteFF_26,
                                    border: Border.all(
                                      color: details?.meeting?.status == 'pending' ||
                                              details?.meeting?.status == 'open'
                                          ? yellow29
                                          : details?.meeting?.status == 'finished'
                                              ? green77()
                                              : red49,
                                      width: 15,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      boxShadow(
                                        details?.meeting?.status == 'pending' ||
                                                details?.meeting?.status == 'open'
                                            ? yellow29.withOpacity(.25)
                                            : details?.meeting?.status == 'finished'
                                                ? green77().withOpacity(.25)
                                                : red49.withOpacity(.25),
                                        blur: 30,
                                        y: 2,
                                      )
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: borderRadius(radius: 120),
                                      child: fadeInImage(
                                        meeting?.user?.avatar ?? '',
                                        125,
                                        125,
                                      ),
                                    ),
                                  ),
                                ),

                                space(14),

                                Text(
                                  meeting?.user?.fullName ?? '',
                                  style: style20Bold(),
                                ),

                                space(4),

                                Text(
                                  isConsultant
                                      ? appText.consultant
                                      : appText.reservatore,
                                  style: style12Regular().copyWith(color: greyA5),
                                ),

                                space(30),

                                Container(
                                  padding: padding(),
                                  width: getSize().width,
                                  child: Wrap(
                                    runSpacing: 21,
                                    children: [
                                      SingleCourseWidget.courseStatus(
                                        appText.startDate,
                                        timeStampToDate((meeting?.date ?? 0) * 1000),
                                        AppAssets.calendarSvg,
                                        width: (getSize().width * .5) - 42,
                                      ),
                                      SingleCourseWidget.courseStatus(
                                        appText.startTime,
                                        meeting?.time?.start ?? '-',
                                        AppAssets.tickSquareSvg,
                                        width: (getSize().width * .5) - 42,
                                      ),
                                      SingleCourseWidget.courseStatus(
                                        appText.endTime,
                                        meeting?.time?.start ?? '-',
                                        AppAssets.tickSquareSvg,
                                        width: (getSize().width * .5) - 42,
                                      ),
                                      SingleCourseWidget.courseStatus(
                                        appText.amount,
                                        CurrencyUtils.calculator(
                                          double.tryParse(meeting?.amount ?? '0') ?? 0,
                                        ),
                                        AppAssets.walletSvg,
                                        width: (getSize().width * .5) - 42,
                                      ),
                                      SingleCourseWidget.courseStatus(
                                        appText.conductionType,
                                        (details?.meeting?.meetingType ?? '') ==
                                                'in_person'
                                            ? appText.inPerson
                                            : appText.online,
                                        AppAssets.videoSvg,
                                        width: (getSize().width * .5) - 42,
                                      ),
                                      SingleCourseWidget.courseStatus(
                                        appText.status,
                                        details?.meeting?.status ?? '',
                                        AppAssets.walletSvg,
                                        width: (getSize().width * .5) - 42,
                                      ),
                                    ],
                                  ),
                                ),

                                if (details?.meeting?.description != null) ...{
                                  space(20),
                                  Container(
                                    width: getSize().width,
                                    padding:
                                        padding(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: greyE7),
                                      borderRadius: borderRadius(),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appText.description,
                                          style: style14Bold(),
                                        ),
                                        space(6),
                                        Text(
                                          details?.meeting?.description ?? '',
                                          style: style14Regular()
                                              .copyWith(color: greyB2),
                                        ),
                                        if (!(details?.meeting?.isAgora ?? true) &&
                                            (details?.meeting?.password ?? '')
                                                .isNotEmpty) ...{
                                          space(6),
                                          Text(
                                            '${appText.password}: ${details?.meeting?.password ?? ''}',
                                            style: style14Regular()
                                                .copyWith(color: greyB2),
                                          ),
                                        },
                                      ],
                                    ),
                                  )
                                },

                                if (isConsultant) ...{
                                  space(20),
                                  Container(
                                    width: getSize().width,
                                    padding:
                                        padding(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: greyE7),
                                      borderRadius: borderRadius(),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appText.address,
                                          style: style14Bold(),
                                        ),
                                        space(6),
                                        Text(
                                          meeting?.user?.address ?? '',
                                          style: style14Regular()
                                              .copyWith(color: greyB2),
                                        )
                                      ],
                                    ),
                                  )
                                },

                                space(140),
                              ],
                            ),
                    ),
                  ),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    bottom: 0,
                    child: Container(
                      width: getSize().width,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 30,
                      ),
                      decoration: BoxDecoration(
                        color: whiteFF_26,
                        boxShadow: [
                          boxShadow(
                            Colors.black.withOpacity(.1),
                            blur: 15,
                            y: -3,
                          )
                        ],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if ((details?.meeting?.meetingType ?? '') !=
                              'in_person') ...{
                            Expanded(
                              child: button(
                                onTap: _openMeeting,
                                width: getSize().width,
                                height: 51,
                                text: details?.meeting?.status == 'finished'
                                    ? appText.finished
                                    : details?.meeting?.status == 'canceled'
                                        ? appText.canceled
                                        : isConsultant &&
                                                (details?.meeting?.link == null &&
                                                    details?.meeting?.agoraLink ==
                                                        null)
                                            ? appText.createJoinInfo
                                            : appText.joinMeeting,
                                bgColor:
                                    (details?.meeting?.status == 'pending' &&
                                                isConsultant) ||
                                            details?.meeting?.status == 'open'
                                        ? green77()
                                        : greyCF,
                                textColor: Colors.white,
                              ),
                            ),
                          },

                          if (details?.meeting?.status == 'pending' ||
                              details?.meeting?.status == 'open') ...{
                            space(0, width: 16),
                            button(
                              onTap: () async {
                                bool? res = await MeetingWidget.showOptionSheet(
                                  isConsultant,
                                  details!,
                                );

                                if (res != null && res) {
                                  getData();
                                }
                              },
                              width: 52,
                              height: 52,
                              text: '',
                              bgColor: whiteFF_26,
                              textColor: Colors.white,
                              iconPath: AppAssets.menuCircleSvg,
                              iconColor: green77(),
                              borderColor: green77(),
                            ),
                          }
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}