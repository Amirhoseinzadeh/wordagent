import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// ---------------------------------------------------------------------------
/// لایه‌ی مدیریت وضعیت (State Management)
/// ---------------------------------------------------------------------------
/// انتخاب معماری: به‌جای وابستگی به پکیج‌های شخص‌ثالث، یک لایه‌ی نازک و
/// کاملاً نوع‌دار روی `ValueListenable` خود Flutter ساخته شده است.
///
/// دلایل:
///  * صفر وابستگی و صفر کد تولیدشده (codegen)؛ بیلد سریع و پایدار؛
///  * تست‌پذیری کامل: هر Store یک `Listenable` است و بدون ویجت هم تست می‌شود؛
///  * بازسازی هدفمند: با `StoreBuilder` فقط همان بخشی از UI که به داده وابسته
///    است دوباره ساخته می‌شود (هم‌سبک با Riverpod/Provider در مصرف، سبک‌تر در
///    پیاده‌سازی)؛
///  * سازگاری با هر نسخه‌ی Flutter 3.x بدون ریسک شکستن API پکیج‌ها.
/// ---------------------------------------------------------------------------

/// یک نگهدارنده‌ی مقدار واکنشی.
class ValueStore<T> extends ChangeNotifier implements ValueListenable<T> {
  ValueStore(T initialValue, {this.debugLabel}) : _value = initialValue;

  final String? debugLabel;
  T _value;

  @override
  T get value => _value;

  /// مقدار جدید را جایگزین می‌کند (در صورت تغییر، شنونده‌ها باخبر می‌شوند).
  set value(T next) {
    if (_value == next) return;
    _value = next;
    notifyListeners();
  }

  /// مقدار را با یک تابع تغییر می‌دهد.
  void update(T Function(T current) updater) => value = updater(_value);

  /// حتی بدون تغییر مقدار، شنونده‌ها را باخبر می‌کند.
  void emit() => notifyListeners();

  @override
  String toString() => 'ValueStore<$T>($debugLabel)';
}

/// مقداری که از چند Store دیگر مشتق می‌شود.
///
/// مثال: nbsp;`DerivedStore([profileStore, progressStore], () => profileStore.value.xp + ...)`.
/// نتیجه فقط زمانی منتشر می‌شود که مقدار مشتق‌شده واقعاً تغییر کند.
class DerivedStore<R> extends ValueStore<R> {
  DerivedStore(
    this._sources,
    R Function() compute, {
    super.debugLabel,
  })  : _compute = compute,
        super(compute()) {
    for (final source in _sources) {
      source.addListener(_recompute);
    }
  }

  final List<Listenable> _sources;
  final R Function() _compute;

  void _recompute() => value = _compute();

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(_recompute);
    }
    super.dispose();
  }
}

/// وضعیت یک عملیات ناهمگام (بارگذاری / داده / خطا).
@immutable
class AsyncValue<T> {
  const AsyncValue._({this.data, this.error, this.isLoading = false});

  const AsyncValue.loading() : this._(isLoading: true);
  const AsyncValue.data(T value) : this._(data: value);
  const AsyncValue.error(Object error) : this._(error: error);

  final T? data;
  final Object? error;
  final bool isLoading;

  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isIdle => !isLoading && !hasData && !hasError;

  R when<R>({
    required R Function() loading,
    required R Function(T data) onData,
    required R Function(Object error) onError,
    R Function()? idle,
  }) {
    if (isLoading) return loading();
    if (hasError) return onError(error!);
    if (hasData) return onData(data as T);
    return idle != null ? idle() : loading();
  }

  /// داده‌ی فعلی را نگه می‌دارد و وضعیت بارگذاری جدید می‌سازد
  /// (برای نمایش «رفرش» روی داده‌ی موجود).
  AsyncValue<T> toLoading() => AsyncValue<T>._(data: data, isLoading: true);

  @override
  String toString() => 'AsyncValue(loading: $isLoading, hasData: $hasData, error: $error)';
}

/// Store اختصاص‌یافته به عملیات‌های ناهمگام.
class AsyncStore<T> extends ValueStore<AsyncValue<T>> {
  AsyncStore({super.debugLabel}) : super(AsyncValue<T>.loading());

  Future<T?> run(Future<T> Function() task, {bool keepPreviousData = true}) async {
    value = keepPreviousData && value.hasData ? value.toLoading() : AsyncValue<T>.loading();
    try {
      final result = await task();
      value = AsyncValue<T>.data(result);
      return result;
    } catch (error) {
      value = AsyncValue<T>.error(error);
      return null;
    }
  }
}

/// سازنده‌ی بخشی از رابط کاربری که به یک Store وابسته است.
class StoreBuilder<T> extends StatelessWidget {
  const StoreBuilder({
    super.key,
    required this.store,
    required this.builder,
  });

  final ValueListenable<T> store;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: store,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

/// سازنده‌ای که به چند Listenable هم‌زمان گوش می‌دهد.
class Watch extends StatelessWidget {
  const Watch({
    super.key,
    required this.listenables,
    required this.builder,
  });

  final List<Listenable> listenables;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) => builder(context),
    );
  }
}
