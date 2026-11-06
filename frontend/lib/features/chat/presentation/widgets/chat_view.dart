import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// عرض محادثة نصية مشترك بين جهة اللاعب وجهة الأكاديمية.
/// [mySide] = 'player' أو 'academy' لتحديد جهة الفقاعة (يمين/يسار ولون).
class ChatView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final String mySide;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const ChatView({
    super.key,
    required this.messages,
    required this.mySide,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text('لا توجد رسائل بعد',
                      style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
                )
              : ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(12.r),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // reverse: نعرض من الأحدث؛ الرسائل مرتبة تصاعدياً.
                    final m = messages[messages.length - 1 - index];
                    final mine = (m['senderType'] as String?) == mySide;
                    return _bubble(m['text'] as String? ?? '', mine);
                  },
                ),
        ),
        _inputBar(context),
      ],
    );
  }

  Widget _bubble(String text, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.grey200,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? AppColors.white : AppColors.grey900,
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.grey200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  counterText: '',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Gap(8.w),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
