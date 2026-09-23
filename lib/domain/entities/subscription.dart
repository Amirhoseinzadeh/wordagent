import 'package:flutter/foundation.dart';

/// سطح دسترسی کاربر.
enum SubscriptionTier {
  free,

  /// دوره‌ی آزمایشی هفت‌روزه.
  trial,

  premium;

  bool get isPaid => this != SubscriptionTier.free;
}

/// پلن‌های خرید.
enum SubscriptionPlan {
  none,
  monthly,
  yearly,
  lifetime;

  /// مبلغ به تومان (قابل به‌روزرسانی از سمت سرور در فاز بک‌اند).
  int get priceToman {
    switch (this) {
      case SubscriptionPlan.monthly:
        return 149000;
      case SubscriptionPlan.yearly:
        return 990000;
      case SubscriptionPlan.lifetime:
        return 2490000;
      case SubscriptionPlan.none:
        return 0;
    }
  }

  String get priceLabel {
    switch (this) {
      case SubscriptionPlan.monthly:
        return '۱۴۹٬۰۰۰ تومان / ماه';
      case SubscriptionPlan.yearly:
        return '۹۹۰٬۰۰۰ تومان / سال';
      case SubscriptionPlan.lifetime:
        return '۲٬۴۹۰٬۰۰۰ تومان / دائمی';
      case SubscriptionPlan.none:
        return '—';
    }
  }

  /// معادل ماهانه برای نشان‌دادن صرفه‌جویی.
  String get perMonthLabel {
    switch (this) {
      case SubscriptionPlan.monthly:
        return '۱۴۹٬۰۰۰ تومان در ماه';
      case SubscriptionPlan.yearly:
        return 'حدود ۸۲٬۵۰۰ تومان در ماه';
      case SubscriptionPlan.lifetime:
        return 'یک‌بار برای همیشه';
      case SubscriptionPlan.none:
        return '';
    }
  }

  static SubscriptionPlan fromName(String? name, {SubscriptionPlan fallback = SubscriptionPlan.none}) {
    if (name == null) return fallback;
    for (final plan in SubscriptionPlan.values) {
      if (plan.name == name) return plan;
    }
    return fallback;
  }
}

/// وضعیت اشتراک کاربر.
///
/// نکته‌ی معماری: خرید واقعی در فاز نهایی به کافه‌بازار/مایکت/App Store وصل
/// می‌شود؛ فعلاً `MockBillingGateway` همان قرارداد را پیاده می‌کند تا هیچ
/// بخشی از رابط کاربری نیازمند تغییر نباشد.
@immutable
class SubscriptionState {
  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.plan = SubscriptionPlan.none,
    this.startedAt,
    this.expiresAt,
    this.storeId,
    this.autoRenew = true,
    this.trialUsed = false,
  });

  final SubscriptionTier tier;
  final SubscriptionPlan plan;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  /// شناسه‌ی خرید در فروشگاه (کافه‌بازار، مایکت، App Store).
  final String? storeId;

  final bool autoRenew;

  /// آیا کاربر قبلاً دوره‌ی آزمایشی را مصرف کرده است؟
  final bool trialUsed;

  /// آیا کاربر در این لحظه دسترسی ویژه دارد؟
  bool hasPremiumAccess(DateTime now) {
    if (tier == SubscriptionTier.free) return false;
    final expiry = expiresAt;
    if (plan == SubscriptionPlan.lifetime || expiry == null) return true;
    return expiry.isAfter(now);
  }

  int daysRemaining(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return 0;
    final days = expiry.difference(now).inDays;
    return days < 0 ? 0 : days;
  }

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    SubscriptionPlan? plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? storeId,
    bool? autoRenew,
    bool? trialUsed,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      plan: plan ?? this.plan,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      storeId: storeId ?? this.storeId,
      autoRenew: autoRenew ?? this.autoRenew,
      trialUsed: trialUsed ?? this.trialUsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubscriptionState &&
      other.tier == tier &&
      other.plan == plan &&
      other.startedAt == startedAt &&
      other.expiresAt == expiresAt &&
      other.storeId == storeId &&
      other.autoRenew == autoRenew &&
      other.trialUsed == trialUsed;

  @override
  int get hashCode =>
      Object.hash(tier, plan, startedAt, expiresAt, storeId, autoRenew, trialUsed);
}
