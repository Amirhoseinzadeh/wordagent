# معماری واژه‌یار

## نگاه کلی

پروژه بر پایه‌ی **معماری تمیز (Clean Architecture)** با سه لایه‌ی مشخص و یک
لایه‌ی ارائه‌ی صفحه‌محور چیده شده است. قاعده‌ی طلایی: **لایه‌ی دامنه هیچ
وابستگی‌ای به Flutter، فایل، شبکه یا پایگاه داده ندارد** — همه‌ی تصمیم‌های
آموزشی (زمان‌بندی مرور، امتیاز، سطح، ضعف، دستاورد) تابع‌های خالص و قابل‌تست‌اند.

```
        ┌──────────────────────────── UI ────────────────────────────┐
        │ features/*  +  widgets/*   (Material، RTL، انیمیشن‌ها)     │
        └───────────────▲───────────────────────┬───────────────────┘
                        │ ValueStore/Listenable │  رویداد کاربر
        ┌───────────────┴───────────────────────▼───────────────────┐
        │ AppController  — هم‌آهنگی جریان‌های کاری (application)    │
        └───────────────▲───────────────────────┬───────────────────┘
                        │                       │
        ┌───────────────┴──── Domain (خالص) ────▼───────────────────┐
        │ entities/*  +  engines/*  +  repositories/* (قراردادها)    │
        └───────────────▲───────────────────────┬───────────────────┘
                        │                       │
        ┌───────────────┴───────── Data ────────▼───────────────────┐
        │ sources/* (assets + نسخه‌ی محلی)  repositories/*  mappers/*│
        └───────────────────────────▲───────────────────────────────┘
                                    │
                     core/storage (LocalStore)  +  core/services
```

## نقش پوشه‌ها

| مسیر | مسئولیت |
| --- | --- |
| `lib/domain/entities` | موجودیت‌های تغییرناپذیر: `Word`, `ReviewState`, `StudySession`, `XpState`, `StreakState`, `Achievement`, `SubscriptionState`, `Settings`, `UserProfile`, … |
| `lib/domain/engines` | مغز آموزشی: `SpacedRepetitionEngine`, `SessionBuilder`, `WeaknessEngine`, `StatsEngine`, `XpEngine`, `StreakEngine`, `AchievementEngine` + `achievement_catalog`, `PlacementEngine`, `QuizFactory`, `AiTutorEngine` |
| `lib/domain/repositories` | قراردادهای مخزن (`WordRepository`, `ProgressRepository`, `SubscriptionRepository`, `AiRepository`) |
| `lib/data/sources` | `ContentSource` — خواندن محتوای بسته‌ی اپ + نسخه‌ی به‌روزشده‌ی محلی |
| `lib/data/repositories` | پیاده‌سازی مخزن‌ها روی `LocalStore` و `ContentSource` |
| `lib/data/mappers` | `WordMapper`, `ProgressMapper`, `JsonUtils` — خواندن ایمن JSON (هیچ‌وقت استثنا پرتاب نمی‌کند) |
| `lib/core/storage` | قرارداد `LocalStore` + پیاده‌سازی فایل (`local_store_io`) و حافظه (`local_store_memory`) |
| `lib/core/state` | `ValueStore` (مینی‌اِستور سبک روی `ChangeNotifier`)، `DerivedStore`، `AppStores` |
| `lib/core/di` | `AppContainer` (ترکیب وابستگی‌ها و راه‌اندازی) و `AppController` (جریان‌های کاری) |
| `lib/core/services` | `AppClock` (زمان قابل جعل)، `AudioService` (TTS سیستم)، `Haptics` |
| `lib/core/utils` | ابزارهای فارسی: `FaFormat` (اعداد/درصد/فاصله)، `JalaliDate` (تقویم شمسی)، `TextNormalizer` (نرمال‌سازی و بخشش خطای تایپی) |
| `lib/core/theme` | پالت، تایپوگرافی، فاصله‌ها و تم روشن/تیره |
| `lib/features/*` | صفحه‌های محصول: `splash`, `onboarding`, `shell`, `home`, `review`, `quiz`, `challenge`, `placement`, `explore`, `pack`, `word_list`, `word_detail`, `progress`, `achievements`, `chat`, `profile`, `settings`, `paywall` |
| `lib/widgets/*` | ویجت‌های مشترک: دکمه، کارت، نشان‌ها، کارت چرخان، نمودارها، قالب‌های سؤال، وضعیت‌های مرگ/خالی/بارگذاری، تبلیغ |
| `lib/l10n` | `strings.dart` (تمام متن‌های رابط) و `labels.dart` (برچسب‌های وابسته به داده) |

## مدیریت وضعیت

- `ValueStore<T>` یک نگه‌دارنده‌ی مقدار بر پایه‌ی `ChangeNotifier` است؛ ویجت‌ها با
  `StoreBuilder<T>` یا `ValueListenableBuilder` به آن وصل می‌شوند.
- `DerivedStore<T>` مقادیر مشتق‌شده را کش می‌کند (مثلاً نمایه‌ی «شناسه ⟶ واژه»
  از فهرست واژه‌ها) و با تغییر منبع دوباره ساخته می‌شود.
- `AppStores` همه‌ی استورها را در یک جا می‌سازد تا سطح بازسازی (rebuild) هر
  صفحه دقیقاً همان چیزی باشد که لازم است — بدون وابستگی به پکیج سنگین state
  management و بدون boilerplate.

## کانتینر و جریان‌ها

`AppContainer.boot()` مسیر راه‌اندازی اپ است:

1. `LocalStore` را آماده می‌کند (فایل روی موبایل/دسکتاپ، حافظه در وب و تست).
2. پیشرفت کاربر را از `ProgressRepositoryImpl` می‌خواند.
3. محتوا را از `ContentSource` (assets + نسخه‌ی محلی) بار می‌کند.
4. `AppStores` و `AppController` را می‌سازد و `AppScope` آن را در اختیار
   تمام صفحه‌ها می‌گذارد.

`AppController` تنها جایی است که چند موتور را با هم ترکیب می‌کند. مثلاً پایان
یک تمرین:

```
answer → QuizFactory.isAnswerCorrect → XpEngine.forAnswer/XpEngine.apply
       → SpacedRepetitionEngine.apply → ProgressRepository.save*
       → AchievementEngine.evaluate → StatsEngine/WeaknessEngine (نمودارها)
```

بنابراین صفحه‌ها هیچ منطق آموزشی‌ای ندارند؛ فقط ورودی می‌گیرند و نتیجه را
نمایش می‌دهند. همین قاعده باعث می‌شود موتورها مستقل و قابل‌تست بمانند.

## قابلیت گسترش

- **بک‌اند/Supabase:** پیاده‌سازی تازه‌ای از `ProgressRepository`,
  `WordRepository` (با `remoteFetcher` فعلاً غیرفعال), `SubscriptionRepository`
  و `AiRepository` جایگزین نسخه‌ی محلی می‌شود؛ هیچ صفحه‌ای تغییر نمی‌کند.
- **به‌روزرسانی محتوا:** `WordRepositoryImpl.checkForUpdates()` نسخه‌ی تازه را
  ذیل کلید `content_override_v1` می‌نویسد؛ اجرای بعدی همان را ترجیح می‌دهد.
- **پرداخت واقعی:** `MockBillingGateway` با Poolakey (کافه‌بازار/مایکت) یا
  `in_app_purchase` (StoreKit) عوض می‌شود؛ منطق محدودیت‌ها دست‌نخورده می‌ماند.
- **AI واقعی:** `LocalAiRepository` (موتور محلی و قطعی) با فراخوانی مدل زبانی
  عوض می‌شود؛ قرارداد `AiRepository` ثابت است.
- **پلتفرم‌ها:** همه‌ی پلتفرم‌ها پیکربندی شده‌اند؛ ذخیره‌سازی وب از
  `MemoryLocalStore` استفاده می‌کند و برای ماندگاری، پیاده‌سازی `localStorage`
  کافی است (همان قرارداد).

## کنوانسیون‌های کد

- همه‌ی نام‌ها و توضیح‌ها فارسی؛ متن‌های رابط فقط در `S.*` و `labels.dart`.
- موجودیت‌ها `@immutable`؛ موتورها `const` و بدون اثر جانبی.
- هیچ متن انگلیسی داخل ویجت‌ها نمی‌ماند (به‌جز خودِ محتوای آموزشی انگلیسی).
- خطاهای داده هرگز به کاربر پرتاب نمی‌شوند: `JsonUtils` و مخزن‌ها مقادیر
  پیش‌فرض سالم می‌دهند تا اپ همیشه بالا بیاید.
