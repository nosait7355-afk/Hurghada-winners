import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:hurghada_winners/features/store/data/store_order.dart';
import 'package:hurghada_winners/features/store/data/store_product.dart';
import 'package:dio/dio.dart';

/// صفحة منتجات (عناصر + هل توجد صفحة تالية) لدعم Pagination/Lazy Loading.
class ProductPage {
  final List<StoreProduct> items;
  final bool hasNext;
  const ProductPage(this.items, this.hasNext);
}

/// صفحة طلبات المدير + عدد الطلبات الجديدة (pending) لعرض الشارة.
class OrderPage {
  final List<StoreOrder> items;
  final bool hasNext;
  final int pendingCount;
  const OrderPage(this.items, this.hasNext, this.pendingCount);
}

/// صفحة متجر اللاعب: منتجات + سياق الأكاديمية (اسمها ورقم واتساب المتجر وعملتها).
class PlayerStorePage {
  final List<StoreProduct> items;
  final bool hasNext;
  final String academyName;
  final String whatsApp;
  final String currency;
  const PlayerStorePage(
    this.items,
    this.hasNext,
    this.academyName,
    this.whatsApp,
    this.currency,
  );
}

/// إعدادات المتجر (جهة المدير).
class StoreSettings {
  final String academyName;
  final String phone;
  final String storeWhatsApp;
  final String currency;
  const StoreSettings({
    required this.academyName,
    required this.phone,
    required this.storeWhatsApp,
    required this.currency,
  });
}

/// خدمة متجر الأكاديمية — تعيد استخدام ApiClient نفسه. جهة المدير (CRUD المنتجات
/// + الطلبات + الإعدادات) وجهة اللاعب (قراءة + إنشاء طلب). لا خدمة شبكة جديدة.
class StoreService {
  final ApiClient _api;
  StoreService(this._api);

  ProductPage _parseProducts(Response<Map<String, dynamic>> res) {
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    return ProductPage(list, meta?['hasNext'] as bool? ?? false);
  }

  // ══════════ جهة المدير — المنتجات ══════════
  // ملاحظة: academyId مطلوب من الـ backend لدور super_admin فقط (resolveAcademyFilter)
  // — يُمرَّر عند "التصرف كأكاديمية"؛ يُتجاهل تلقائياً لباقي الأدوار (تُستخدم
  // أكاديمية التوكن).
  Future<ProductPage> getProducts({int page = 1, int limit = 20, String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/store/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (academyId != null) 'academyId': academyId,
      },
    );
    return _parseProducts(res);
  }

  Future<StoreProduct> createProduct({
    required String imagePath,
    required String name,
    required double price,
    String? description,
    bool isAvailable = true,
    String? academyId,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'price': price.toString(),
      'isAvailable': isAvailable.toString(),
      if (description != null && description.isNotEmpty) 'description': description,
      'image': await buildImageMultipart(imagePath, filename: 'product.jpg'),
    });
    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/store/products',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
      data: form,
    );
    return StoreProduct.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<StoreProduct> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/store/products/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (isAvailable != null) 'isAvailable': isAvailable,
      },
    );
    return StoreProduct.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/store/products/$id');
  }

  Future<void> reorderProducts(List<String> ids, {String? academyId}) async {
    await _api.patch(
      '/store/products/reorder',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
      data: {'ids': ids},
    );
  }

  // ══════════ جهة المدير — الإعدادات ══════════
  Future<StoreSettings> getSettings({String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/store/settings',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
    );
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return StoreSettings(
      academyName: data['academyName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      storeWhatsApp: data['storeWhatsApp'] as String? ?? '',
      currency: data['currency'] as String? ?? 'EGP',
    );
  }

  Future<void> updateStoreWhatsApp(String number, {String? academyId}) async {
    await _api.patch(
      '/store/settings',
      queryParameters: academyId != null ? {'academyId': academyId} : null,
      data: {'storeWhatsApp': number},
    );
  }

  // ══════════ جهة المدير — الطلبات ══════════
  Future<OrderPage> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? academyId,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/store/orders',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (academyId != null) 'academyId': academyId,
      },
    );
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => StoreOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    return OrderPage(
      list,
      meta?['hasNext'] as bool? ?? false,
      (meta?['pendingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> deleteOrder(String id) async {
    await _api.delete('/store/orders/$id');
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _api.patch('/store/orders/$id/status', data: {'status': status});
  }

  // ══════════ جهة اللاعب ══════════
  Future<PlayerStorePage> getPlayerStore({int page = 1, int limit = 20}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/player/store',
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    final academy = body['academy'] as Map<String, dynamic>? ?? {};
    return PlayerStorePage(
      list,
      meta?['hasNext'] as bool? ?? false,
      academy['name'] as String? ?? '',
      academy['whatsApp'] as String? ?? '',
      academy['currency'] as String? ?? 'EGP',
    );
  }

  Future<void> createOrder(String productId) async {
    await _api.post('/player/store/orders', data: {'productId': productId});
  }
}
