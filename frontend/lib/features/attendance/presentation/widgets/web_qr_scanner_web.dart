// Web-only QR scanner over getUserMedia, with two decoders:
//
//   1. window.BarcodeDetector (Shape Detection API) — native and cheap, but
//      Chrome/Edge only.
//   2. zxing2 — pure Dart, so it costs nothing in the Android build and works
//      everywhere else. Safari has no BarcodeDetector at all, which is why
//      iPhone users need this path.
//
// The zxing2 path decodes on the main isolate, so it samples a downscaled
// frame and polls slower than the native one.
//
// يستخدم dart:js_interop و package:web لا dart:js_util و dart:html: الأولى
// أُزيلت من Dart 3.12 والثانية مهجورة، وكلاهما غير متاح على WebAssembly.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:zxing2/qrcode.dart';

Future<String?> showWebQrScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const _WebQrScannerPage()),
  );
}

class _WebQrScannerPage extends StatefulWidget {
  const _WebQrScannerPage();

  @override
  State<_WebQrScannerPage> createState() => _WebQrScannerPageState();
}

class _WebQrScannerPageState extends State<_WebQrScannerPage> {
  static int _viewCounter = 0;
  late final String _viewType =
      'web-qr-video-${_viewCounter++}-${DateTime.now().microsecondsSinceEpoch}';

  /// أطول ضلع للإطار الذي نحلّله بـ zxing2. الترميز يعمل على الـ isolate
  /// الرئيسي، فتصغير الإطار يمنع تهنيج الواجهة، و640 تكفي لقراءة QR بطاقة.
  static const int _maxSampleSide = 640;

  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  web.HTMLCanvasElement? _canvas;
  Timer? _pollTimer;

  /// null على المتصفحات بلا Shape Detection API — عندها نستخدم zxing2.
  JSObject? _detector;
  final _reader = QRCodeReader();

  /// يمنع تداخل عمليتي ترميز إذا تأخّرت واحدة عن دورة المؤقّت.
  bool _decoding = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // BarcodeDetector غير موجود على Safari وFirefox — نسقط إلى zxing2 بدل
    // إظهار رسالة "غير مدعوم" كما كان سابقاً.
    final ctor = web.window.getProperty<JSFunction?>('BarcodeDetector'.toJS);
    if (ctor != null) {
      try {
        _detector = ctor.callAsConstructor<JSObject>(
          {
            'formats': ['qr_code'],
          }.jsify(),
        );
      } catch (_) {
        _detector = null; // موجود لكنه لا يدعم qr_code — zxing2 يتولّى الأمر
      }
    }

    try {
      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        // مطلوبة على iOS Safari وإلا فُتح الفيديو في مشغّل ملء الشاشة.
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => video,
      );

      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              video: {'facingMode': 'environment'}.jsify()!,
            ),
          )
          .toDart;

      video.srcObject = stream;
      _video = video;
      _stream = stream;

      _pollTimer = Timer.periodic(
        Duration(milliseconds: _detector != null ? 350 : 500),
        (_) => _detect(),
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر فتح الكاميرا — تأكد من السماح بالوصول للكاميرا';
        });
      }
    }
  }

  Future<void> _detect() async {
    final video = _video;
    if (video == null || _decoding) return;
    // videoWidth تبقى صفراً حتى يصل أول إطار فعلي من الكاميرا.
    if (video.videoWidth == 0) return;

    _decoding = true;
    try {
      final raw = _detector != null
          ? await _detectNative(video)
          : _detectWithZxing(video);
      if (raw != null && raw.trim().isNotEmpty && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pop(raw);
      }
    } catch (_) {
      // أخطاء عابرة (إطار غير جاهز، أو لا رمز في المشهد) — نتجاهلها.
    } finally {
      _decoding = false;
    }
  }

  Future<String?> _detectNative(web.HTMLVideoElement video) async {
    final result = await _detector!
        .callMethod<JSPromise<JSArray<JSObject>>>('detect'.toJS, video)
        .toDart;
    final list = result.toDart;
    if (list.isEmpty) return null;
    return list.first.getProperty<JSString?>('rawValue'.toJS)?.toDart;
  }

  String? _detectWithZxing(web.HTMLVideoElement video) {
    final srcW = video.videoWidth;
    final srcH = video.videoHeight;
    if (srcW == 0 || srcH == 0) return null;

    // نصغّر مع الحفاظ على النسبة؛ لا نكبّر إطاراً أصغر من الحد أصلاً.
    final scale = _maxSampleSide / (srcW > srcH ? srcW : srcH);
    final w = scale < 1 ? (srcW * scale).round() : srcW;
    final h = scale < 1 ? (srcH * scale).round() : srcH;

    final canvas = _canvas ??= web.HTMLCanvasElement();
    if (canvas.width != w || canvas.height != h) {
      canvas.width = w;
      canvas.height = h;
    }

    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (ctx == null) return null;
    ctx.drawImage(video, 0, 0, w, h);

    final bytes = ctx.getImageData(0, 0, w, h).data.toDart;

    // zxing2 ينتظر ARGB معبّأة في int واحد لكل بكسل؛ الكانفاس يعطي RGBA
    // كأربع بايتات. القناة الرابعة (alpha) دائماً 255 هنا فنتجاهلها.
    final pixels = Int32List(w * h);
    for (var i = 0; i < pixels.length; i++) {
      final o = i * 4;
      pixels[i] =
          (0xFF << 24) | (bytes[o] << 16) | (bytes[o + 1] << 8) | bytes[o + 2];
    }

    final bitmap = BinaryBitmap(
      HybridBinarizer(RGBLuminanceSource(w, h, pixels)),
    );
    // يرمي NotFoundException عندما لا يوجد رمز في الإطار — وهو الوضع الطبيعي
    // في معظم الدورات، ويلتقطه catch في _detect.
    return _reader.decode(bitmap).text;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    final tracks = _stream?.getTracks().toDart;
    if (tracks != null) {
      for (final track in tracks) {
        track.stop();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مسح QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : (_video == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    HtmlElementView(viewType: _viewType),
                    // مربع التصويب — للعرض فقط؛ القراءة من الإطار كاملاً كما هي.
                    const IgnorePointer(
                      child: CustomPaint(painter: _ScanFramePainter()),
                    ),
                    const Positioned(
                      left: 16,
                      right: 16,
                      bottom: 32,
                      child: IgnorePointer(
                        child: Text(
                          'ضع كود البطاقة داخل المربع',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
    );
  }
}

/// تعتيم خارج مربع في المنتصف + زوايا بارزة له.
class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.shortestSide * 0.68).clamp(160.0, 340.0);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    // تعتيم كل ما حول المربع.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(frame),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // إطار رفيع + زوايا سميكة.
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE85D04);
    const len = 30.0;
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    for (final path in [
      Path()..moveTo(l, t + len)..lineTo(l, t)..lineTo(l + len, t),
      Path()..moveTo(r - len, t)..lineTo(r, t)..lineTo(r, t + len),
      Path()..moveTo(l, b - len)..lineTo(l, b)..lineTo(l + len, b),
      Path()..moveTo(r - len, b)..lineTo(r, b)..lineTo(r, b - len),
    ]) {
      canvas.drawPath(path, corner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
