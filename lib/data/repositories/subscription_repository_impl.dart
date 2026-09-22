import '../../core/services/app_services.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/subscription_repository.dart';

/// دروازه‌ی پرداخت محلی (Mock Billing Gateway).
///
/// در فاز نهایی، این کلاس با پیاده‌سازی‌های واقعی جایگزین می‌شود:
///  * اندروید: کافه‌بازار / مایکت (Poolakey یا Bazaar IAB)
///  * iOS: StoreKit 2 (in_app_purchase)
///  * وب: درگاه پرداخت بانکی
///
/// منطق اپ (محدودیت‌ها، نمایش پلن‌ها، مدیریت انقضا) به این دروازه وابسته
/// نیست، پس جای‌گزینی آن هیچ تغییری در رابط کاربری نمی‌خواهد.
class MockBillingGateway {
  const MockBillingGateway({this.artificialDelay = const Duration(milliseconds: 900)});

  final Duration artificialDelay;

  Future<bool> charge(SubscriptionPlan plan) async {
    await Future<void>.delayed(artificialDelay);
    // پرداخت همیشه موفق است؛ در فاز واقعی نتیجه‌ی درگاه برگردانده می‌شود.
    return plan != SubscriptionPlan.none;
  }
}

/// پیاده‌سازی مخزن اشتراک.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(
    this._progress,
    this._clock, {
    MockBillingGateway gateway = const MockBillingGateway(),
  }) : _gateway = gateway;

  final ProgressRepository _progress;
  final AppClock _clock;
  final MockBillingGateway _gateway;

  /// طول دوره‌ی آزمایشی.
  static const int trialDays = 7;

  static const int yearlyDays = 365;
  static const int monthlyDays = 30;

  @override
  Future<SubscriptionState> load() async {
    final data = await _progress.load();
    return data.subscription;
  }

  @override
  Future<PurchaseResult> startTrial() async {
    final current = await load();
    if (current.trialUsed) {
      return PurchaseResult(
        success: false,
        state: current,
        message: 'دوره‌ی آزمایشی قبلاً استفاده شده است',
      );
    }
    final now = _clock.now();
    final next = current.copyWith(
      tier: SubscriptionTier.trial,
      plan: SubscriptionPlan.monthly,
      startedAt: now,
      expiresAt: now.add(const Duration(days: trialDays)),
      trialUsed: true,
      storeId: 'trial_local',
    );
    await _progress.saveSubscription(next);
    return PurchaseResult(success: true, state: next);
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    if (plan == SubscriptionPlan.none) {
      return PurchaseResult(success: false, state: await load());
    }
    final paid = await _gateway.charge(plan);
    if (!paid) {
      return PurchaseResult(
        success: false,
        state: await load(),
        message: 'پرداخت انجام نشد',
      );
    }
    final now = _clock.now();
    final current = await load();
    final days = switch (plan) {
      SubscriptionPlan.monthly => monthlyDays,
      SubscriptionPlan.yearly => yearlyDays,
      SubscriptionPlan.lifetime => 36500,
      SubscriptionPlan.none => 0,
    };
    final next = current.copyWith(
      tier: SubscriptionTier.premium,
      plan: plan,
      startedAt: now,
      expiresAt: plan == SubscriptionPlan.lifetime
          ? null
          : now.add(Duration(days: days)),
      storeId: 'mock_${plan.name}_${now.millisecondsSinceEpoch}',
      autoRenew: plan != SubscriptionPlan.lifetime,
    );
    await _progress.saveSubscription(next);
    return PurchaseResult(success: true, state: next);
  }

  @override
  Future<PurchaseResult> restore() async {
    final current = await load();
    if (current.tier == SubscriptionTier.free) {
      return PurchaseResult(
        success: false,
        state: current,
        message: 'خرید فعالی پیدا نشد',
      );
    }
    return PurchaseResult(success: true, state: current);
  }

  @override
  Future<SubscriptionState> cancelAutoRenew() async {
    final current = await load();
    final next = current.copyWith(autoRenew: false);
    await _progress.saveSubscription(next);
    return next;
  }
}
