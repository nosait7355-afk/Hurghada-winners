import 'package:hurghada_winners/core/network/api_client.dart';

/// نتيجة مسح QR مدرب: حضور (check_in) أو انصراف (check_out).
class StaffScanResult {
  final bool isCheckIn;
  final String staffName;
  final String position;
  final String? photoUrl;
  final String? checkIn;
  final String? checkOut;
  final String message;

  const StaffScanResult({
    required this.isCheckIn,
    required this.staffName,
    required this.position,
    required this.photoUrl,
    required this.checkIn,
    required this.checkOut,
    required this.message,
  });
}

/// محتوى QR المدرب — يقرؤه الأدمن بالمسح.
String staffQrData(String staffId) => 'STAFF:$staffId';

class StaffScanService {
  final ApiClient _api;
  const StaffScanService(this._api);

  String _two(int n) => n.toString().padLeft(2, '0');

  /// [code]: محتوى الـ QR ("STAFF:<id>") أو معرّف المدرب مباشرة.
  Future<StaffScanResult> scan(String code) async {
    final now = DateTime.now();
    final res = await _api.post<Map<String, dynamic>>(
      '/staff-attendance/scan',
      data: {
        'code': code.trim(),
        'localDate': '${now.year}-${_two(now.month)}-${_two(now.day)}',
        'localTime': '${_two(now.hour)}:${_two(now.minute)}',
      },
    );
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final staff = data['staff'] as Map<String, dynamic>? ?? const {};
    final record = data['record'] as Map<String, dynamic>? ?? const {};
    return StaffScanResult(
      isCheckIn: data['action'] == 'check_in',
      staffName: staff['fullName'] as String? ?? '',
      position: staff['position'] as String? ?? '',
      photoUrl: staff['photo_url'] as String?,
      checkIn: record['checkIn'] as String?,
      checkOut: record['checkOut'] as String?,
      message: body['message'] as String? ?? '',
    );
  }
}
