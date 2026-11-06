import 'package:flutter/material.dart';

/// مفتاح Navigator الجذري — يُمرَّر إلى GoRouter ويُتيح عرض الحوارات من طبقة
/// الشبكة (interceptor) عند انتهاء الاشتراك أو تجاوز الحد، دون سياق مباشر.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
