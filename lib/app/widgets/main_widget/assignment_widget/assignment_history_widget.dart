import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webinar/app/services/user_service/assignment_service.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/common/utils/date_formater.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';

import '../../../models/chat_model.dart';

class AssignmentHistoryWidget {
  static Widget message(ChatModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: getSize().width,
      child: Column(
        crossAxisAlignment: data.sender == null
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // icon and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (data.sender != null) ...{
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      boxShadow(Colors.black.withOpacity(.11),
                          blur: 15, y: 10)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius(radius: 48),
                    child: fadeInImage(data.sender?.avatar ?? '', 48, 48),
                  ),
                ),
              },

              // message
              Expanded(
                child: Container(
                  width: getSize().width,
                  alignment: data.sender == null
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Container(
                    padding: padding(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: data.sender == null ? green77() : greyE7,
                      borderRadius: BorderRadiusDirectional.only(
                        topEnd: const Radius.circular(20),
                        topStart: const Radius.circular(20),
                        bottomEnd: Radius.circular(data.sender == null ? 0 : 20),
                        bottomStart: Radius.circular(data.sender == null ? 20 : 0),
                      ),
                    ),
                    child: Text(
                      (data.message ?? ''),
                      style: style14Regular().copyWith(
                        color: data.sender != null ? null : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // date
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: data.sender == null ? 0 : 60,
              top: 8,
            ),
            child: Text(
              timeStampToDate((data.createdAt ?? 0) * 1000),
              style: style12Regular().copyWith(color: greyA5),
            ),
          ),

          // file
          if (data.filePath != null && (data.filePath ?? '').isNotEmpty) ...{
            Container(
              margin: EdgeInsetsDirectional.only(
                top: 12,
                start: data.sender == null ? 0 : 60,
              ),
              width: getSize().width,
              alignment: data.sender == null
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () {
                  downloadSheet(data.filePath!, data.filePath!.split('/').last);
                },
                child: Container(
                  padding: padding(horizontal: 14, vertical: 12),
                  constraints: BoxConstraints(
                    minWidth: getSize().width * .1,
                    maxWidth: getSize().width * .7,
                  ),
                  decoration: BoxDecoration(
                    color: greyF8,
                    borderRadius: borderRadius(),
                    border: Border.all(color: greyE7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppAssets.attachmentSvg,
                        colorFilter: ColorFilter.mode(greyA5, BlendMode.srcIn),
                        width: 15,
                      ),
                      space(0, width: 6),
                      Flexible(
                        child: Text(
                          (data.fileTitle ?? data.filePath!.split('/').last),
                          style: style12Regular().copyWith(color: greyA5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          }
        ],
      ),
    );
  }

  static Future newReplaySheet(int assignmentId, int studentId) async {
    TextEditingController descController = TextEditingController();
    FocusNode descNode = FocusNode();

    File? attachment;
    bool isLoading = false;

    return await baseBottomSheet(
      child: Builder(
        builder: (context) {
          return Padding(
            padding: padding(),
            child: StatefulBuilder(
              builder: (context, state) {
                Future<void> pickAttachment() async {
                  try {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                      withData: false,
                    );

                    if (result != null && result.files.single.path != null) {
                      final picked = File(result.files.single.path!);

                      // حماية اختيارية للحجم (10MB)
                      final sizeBytes = picked.lengthSync();
                      const maxBytes = 10 * 1024 * 1024;
                      if (sizeBytes > maxBytes) {
                        showSnackBar(
                          ErrorEnum.error,
                          appText.error,
                          desc: 'حجم الملف كبير (أقصى شيء 10MB)',
                        );
                        return;
                      }

                      attachment = picked;
                      state(() {});
                    }
                  } catch (_) {
                    showSnackBar(
                      ErrorEnum.error,
                      appText.error,
                      desc: 'فشل اختيار الملف، جرّب مرة أخرى',
                    );
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    space(20),
                    Text(
                      appText.assignmentSubmission,
                      style: style16Bold(),
                    ),

                    space(16),

                    descriptionInput(
                      descController,
                      descNode,
                      appText.description,
                      isBorder: true,
                    ),

                    space(12),

                    // عرض اسم الملف المختار + زر إزالته
                    if (attachment != null) ...{
                      Container(
                        width: getSize().width,
                        padding: padding(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: greyE7),
                          borderRadius: borderRadius(),
                          color: greyF8,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.attachmentSvg,
                              colorFilter:
                                  ColorFilter.mode(greyA5, BlendMode.srcIn),
                              width: 16,
                            ),
                            space(0, width: 8),
                            Expanded(
                              child: Text(
                                attachment!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style12Regular().copyWith(color: greyA5),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                attachment = null;
                                state(() {});
                              },
                              child: Icon(Icons.close, size: 18, color: greyA5),
                            )
                          ],
                        ),
                      ),
                      space(12),
                    },

                    Row(
                      children: [
                        // زر المرفق
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: button(
                            onTap: () async {
                              if (isLoading) return;
                              await pickAttachment();
                            },
                            width: 52,
                            height: 52,
                            text: '',
                            bgColor: Colors.white,
                            textColor: green77(),
                            iconPath: AppAssets.attachmentSvg,
                            borderColor: green77(),
                            raduis: 15,
                          ),
                        ),

                        space(0, width: 16),

                        // زر الإرسال
                        Expanded(
                          child: button(
                            onTap: () async {
                              if (isLoading) return;

                              final hasText =
                                  descController.text.trim().isNotEmpty;
                              final hasFile = attachment != null;

                              // يسمح إرسال ملف فقط أو رسالة فقط أو الاتنين
                              if (!hasText && !hasFile) {
                                showSnackBar(
                                  ErrorEnum.error,
                                  appText.error,
                                  desc: 'اكتب رسالة أو ارفع ملف',
                                );
                                return;
                              }

                              state(() {
                                isLoading = true;
                              });

                              final fileTitle = attachment != null
                                  ? attachment!.path.split('/').last
                                  : '';

                              bool res = await AssignmentService.newQuestion(
                                assignmentId,
                                fileTitle,
                                descController.text.trim(),
                                attachment,
                                studentId,
                              );

                              if (res) {
                                backRoute(arguments: true);
                              }

                              state(() {
                                isLoading = false;
                              });
                            },
                            width: getSize().width,
                            height: 52,
                            text: appText.send,
                            bgColor: green77(),
                            textColor: Colors.white,
                            isLoading: isLoading,
                          ),
                        )
                      ],
                    ),

                    space(28),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Future setGradeSheet(int historyId, String grade) async {
    TextEditingController titleController = TextEditingController();
    FocusNode titleNode = FocusNode();

    bool isLoading = false;

    return await baseBottomSheet(
      child: Builder(
        builder: (context) {
          return Padding(
            padding: padding(),
            child: StatefulBuilder(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    space(20),
                    Text(
                      appText.assignmentSubmission,
                      style: style16Bold(),
                    ),
                    space(10),
                    Text(
                      '${appText.passGradeIis} $grade',
                      style: style12Regular().copyWith(color: greyA5),
                    ),
                    space(20),
                    input(
                      titleController,
                      titleNode,
                      appText.grade,
                      isBorder: true,
                      iconPathLeft: AppAssets.starSvg,
                      isNumber: true,
                    ),
                    space(12),
                    Center(
                      child: button(
                        onTap: () async {
                          if (titleController.text.trim().isNotEmpty) {
                            state(() {
                              isLoading = true;
                            });

                            bool res = await AssignmentService.setGrade(
                              historyId,
                              int.parse(titleController.text.trim()),
                            );

                            if (res) {
                              backRoute(arguments: true);
                            }

                            state(() {
                              isLoading = false;
                            });
                          }
                        },
                        width: getSize().width,
                        height: 52,
                        text: appText.submit,
                        bgColor: green77(),
                        textColor: Colors.white,
                        isLoading: isLoading,
                      ),
                    ),
                    space(28),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}