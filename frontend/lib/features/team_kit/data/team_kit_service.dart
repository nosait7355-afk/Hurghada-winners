import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:hurghada_winners/features/team_kit/data/kit_booking.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit.dart';
import 'package:dio/dio.dart';

/// صفحة حجوزات + عدد الحجوزات بانتظار المراجعة (لعرض الشارة).
class KitBookingPage {
  final List<KitBooking> items;
  final bool hasNext;
  final int pendingCount;

  /// عدد الحجوزات لكل مقاس ضمن الحالة المختارة (قبل فلتر المقاس).
  final Map<String, int> sizeCounts;
  const KitBookingPage(this.items, this.hasNext, this.pendingCount,
      [this.sizeCounts = const {}]);
}

/// خدمة طقم الفريق — تعيد استخدام ApiClient نفسه. جهة المدير (الطقم + مراجعة
/// الحجوزات) وجهة اللاعب (قراءة الطقم + إنشاء حجز). لا خدمة شبكة جديدة.
class TeamKitService {
  final ApiClient _api;
  TeamKitService(this._api);

  TeamKit? _parseKit(Response<Map<String, dynamic>> res) {
    final data = (res.data as Map<String, dynamic>)['data'];
    if (data == null) return null;
    return TeamKit.fromJson(data as Map<String, dynamic>);
  }

  // ══════════ جهة المدير — الطقم ══════════
  // ملاحظة: academyId مطلوب من الـ backend لدور super_admin فقط — نفس نمط
  // خدمة المتجر (StoreService).
  Future<TeamKit?> getKit({String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/team-kit',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
    );
    return _parseKit(res);
  }

  Future<TeamKit> saveKit({
    String? imagePath,
    required String name,
    required double price,
    required List<String> availableSizes,
    String? academyId,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'price': price.toString(),
      'availableSizes': availableSizes,
      if (imagePath != null)
        'image': await buildImageMultipart(imagePath, filename: 'kit.jpg'),
    });
    final res = await _api.putMultipart<Map<String, dynamic>>(
      '/team-kit',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
      data: form,
    );
    return TeamKit.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteKit({String? academyId}) async {
    await _api.delete(
      '/team-kit',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
    );
  }

  // ══════════ جهة المدير — الحجوزات ══════════
  Future<KitBookingPage> getBookings({
    int page = 1,
    int limit = 20,
    String? status,
    String? size,
    String? academyId,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/team-kit/bookings',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (size != null && size.isNotEmpty) 'size': size,
        if (academyId != null) 'academyId': academyId,
      },
    );
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => KitBooking.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    return KitBookingPage(
      list,
      meta?['hasNext'] as bool? ?? false,
      (meta?['pendingCount'] as num?)?.toInt() ?? 0,
      ((meta?['sizeCounts'] as Map<String, dynamic>?) ?? const {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Future<KitBooking> reviewBooking({
    required String id,
    String? size,
    String? paymentStatus,
    double? paidAmount,
    String? status, // approved | rejected
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/team-kit/bookings/$id/review',
      data: {
        if (size != null) 'size': size,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (status != null) 'status': status,
      },
    );
    return KitBooking.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<KitBooking> createManagerBooking({
    required String playerId,
    required String size,
    String paymentStatus = 'unpaid',
    double paidAmount = 0,
    String? academyId,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/team-kit/bookings',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
      data: {
        'playerId': playerId,
        'size': size,
        'paymentStatus': paymentStatus,
        'paidAmount': paidAmount,
      },
    );
    return KitBooking.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  /// حذف نهائي لحجز (مع صورة الإيصال).
  Future<void> deleteBooking(String id) async {
    await _api.delete('/team-kit/bookings/$id');
  }

  // ══════════ جهة اللاعب ══════════
  Future<TeamKit?> getPlayerKit() async {
    final res = await _api.get<Map<String, dynamic>>('/player/team-kit');
    return _parseKit(res);
  }

  /// [receiptPath]: صورة إيصال الدفع — مطلوبة، يراجعها المدير قبل الموافقة.
  Future<void> createPlayerBooking({
    required String size,
    required String receiptPath,
  }) async {
    final form = FormData.fromMap({
      'size': size,
      'receipt': await buildImageMultipart(receiptPath, filename: 'receipt.jpg'),
    });
    await _api.postMultipart('/player/team-kit/bookings', data: form);
  }
}
