import 'local_store.dart';
// انتخاب پیاده‌سازی در زمان کامپایل بر اساس پلتفرم هدف:
// در وب/تست نسخه‌ی حافظه‌ای و روی موبایل و دسکتاپ نسخه‌ی فایلی استفاده می‌شود.
import 'local_store_memory.dart' if (dart.library.io) 'local_store_io.dart' as impl;

/// ساخت ذخیره‌ساز مناسب پلتفرم جاری.
LocalStore createLocalStore() => impl.createLocalStore();
