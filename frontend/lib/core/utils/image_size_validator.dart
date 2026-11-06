/// حد أقصى موحّد لحجم أي صورة تُرفع — مطابق لـ MAX_IMAGE_BYTES في الخادم
/// (backend/src/config/cloudinary.js). الصور الأكبر لا تُرفض في التطبيق: تُصغَّر
/// تلقائياً قبل الرفع (راجع image_compress.dart).
const int kMaxImageBytes = 2 * 1024 * 1024;
