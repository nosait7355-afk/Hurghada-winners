import 'dart:convert';

import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:hurghada_winners/features/offers/data/offer.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// بيانات نموذج العرض (إضافة/تعديل).
class OfferInput {
  final String title;
  final String details;
  final String? discountType; // percent | amount | null
  final double? discountValue;
  final DateTime startDate;
  final DateTime endDate;

  /// للحساب الرئيسي فقط: فارغة = كل الفروع. يتجاهلها الخادم لمدير الفرع.
  final List<String> academyIds;
  final String? imagePath;
  final bool removeImage;

  const OfferInput({
    required this.title,
    required this.details,
    this.discountType,
    this.discountValue,
    required this.startDate,
    required this.endDate,
    this.academyIds = const [],
    this.imagePath,
    this.removeImage = false,
  });
}

class OffersService {
  final ApiClient _api;
  OffersService(this._api);

  static final _ymd = DateFormat('yyyy-MM-dd');

  static List<Offer> _list(Response res) =>
      (((res.data as Map<String, dynamic>)['data'] as List<dynamic>?) ?? const [])
          .map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<FormData> _form(OfferInput i) async => FormData.fromMap({
        'title': i.title,
        'details': i.details,
        // نوع فارغ = بلا خصم.
        'discountType': i.discountType ?? '',
        if (i.discountType != null && i.discountValue != null)
          'discountValue': i.discountValue,
        'startDate': _ymd.format(i.startDate),
        'endDate': _ymd.format(i.endDate),
        'academyIds': jsonEncode(i.academyIds),
        if (i.removeImage) 'removeImage': 'true',
        if (i.imagePath != null)
          'image': await buildImageMultipart(i.imagePath!, filename: 'offer.jpg'),
      });

  /// عروض الإدارة (السوبر أدمن: كلها؛ مدير الفرع: فرعه + العامة).
  Future<List<Offer>> list() async =>
      _list(await _api.get<Map<String, dynamic>>('/offers'));

  Future<void> create(OfferInput input) async {
    await _api.postMultipart<Map<String, dynamic>>('/offers', data: await _form(input));
  }

  Future<void> update(String id, OfferInput input) async {
    await _api.patch<Map<String, dynamic>>('/offers/$id', data: await _form(input));
  }

  Future<void> delete(String id) async {
    await _api.delete<Map<String, dynamic>>('/offers/$id');
  }

  /// العروض السارية لفرع اللاعب.
  Future<List<Offer>> playerOffers() async {
    final d = DateTime.now();
    return _list(await _api.get<Map<String, dynamic>>(
      '/player/offers',
      queryParameters: {'localDate': _ymd.format(d)},
    ));
  }
}
