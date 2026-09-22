import '../entities/subscription.dart';

/// نتیجه‌ی یک عملیات خرید/بازیابی.
class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.state,
    this.message,
  });

  final bool success;
  final SubscriptionState state;
  final String? message;
}

/// قرارداد اشتراک و پرداخت درون‌برنامه‌ای.
///
/// پیاده‌سازی فعلی محلی است (MockBillingGateway) و برای بازار ایران آماده‌ی
/// اتصال به کافه‌بازار/مایکت و برای iOS به App Store است؛ فقط همین قرارداد
/// باید پیاده‌سازی شود.
abstract class SubscriptionRepository {
  Future<SubscriptionState> load();

  /// فعال‌سازی دوره‌ی آزمایشی.
  Future<PurchaseResult> startTrial();

  /// خرید یک پلن.
  Future<PurchaseResult> purchase(SubscriptionPlan plan);

  /// بازیابی خریدهای پیشین (بعد از نصب دوباره).
  Future<PurchaseResult> restore();

  /// لغو تمدید خودکار (دسترسی تا پایان دوره باقی می‌ماند).
  Future<SubscriptionState> cancelAutoRenew();
}
