/// رشته‌های ثابت متنی اپلیکیشن (فارسی).
///
/// تمام متن‌های رابط کاربری فقط از این فایل می‌آیند تا:
/// * یکدستی لحن و املای فارسی تضمین شود،
/// * امکان افزودن زبان دوم در آینده بدون جست‌وجوی رشته‌ها فراهم باشد.
class S {
  const S._();

  // ---------------------------------------------------------------- عمومی
  static const appName = 'واژه‌یار';
  static const appTagline = 'هوشمندانه لغت یاد بگیر';
  static const appDescription =
      'واژه‌یار با الگوریتم تکرار فاصله‌دار، هوش مصنوعی آموزشی و تمرین‌های تعاملی '
      'کمک می‌کند لغات انگلیسی را برای همیشه به خاطر بسپاری.';
  static const ok = 'باشه';
  static const cancel = 'انصراف';
  static const save = 'ذخیره';
  static const delete = 'حذف';
  static const close = 'بستن';
  static const next = 'بعدی';
  static const back = 'قبلی';
  static const done = 'تمام';
  static const skip = 'رد کردن';
  static const retry = 'تلاش دوباره';
  static const loading = 'در حال آماده‌سازی…';
  static const somethingWentWrong = 'مشکلی پیش آمد. لطفاً دوباره تلاش کن.';
  static const comingSoon = 'به‌زودی';
  static const premium = 'ویژه';
  static const free = 'رایگان';
  static const seeAll = 'مشاهده همه';
  static const search = 'جست‌وجو';
  static const continueLabel = 'ادامه';

  // -------------------------------------------------------------- ناوبری
  static const navHome = 'خانه';
  static const navLearn = 'یادگیری';
  static const navExplore = 'کاوش';
  static const navProgress = 'پیشرفت';
  static const navProfile = 'پروفایل';

  // ------------------------------------------------------------ آنبوردینگ
  static const onboardingTitle1 = 'لغت‌ها را برای همیشه یاد بگیر';
  static const onboardingBody1 =
      'الگوریتم تکرار فاصله‌دار واژه‌یار دقیقاً در همان لحظه‌ای که در آستانه‌ی فراموشی هستی، '
      'لغت را به تو نشان می‌دهد. نتیجه؟ یادگیری ماندگار با کمترین زمان.';
  static const onboardingTitle2 = 'فارسی‌زبان‌پسند، از پایه';
  static const onboardingBody2 =
      'معنی دقیق فارسی، تلفظ، مثال‌های مکالمه واقعی، کالوکیشن، مترادف و متضاد — '
      'همراه با نکته‌های کاربردی مخصوص فارسی‌زبانان.';
  static const onboardingTitle3 = 'هوش مصنوعی همراه تو';
  static const onboardingBody3 =
      'جمله‌سازی متناسب با سطح تو، توضیح ساده‌تر هر لغت، گفت‌وگوی آموزشی و '
      'شناسایی اشتباه‌های پرتکرار — همه در یک اپلیکیشن.';
  static const onboardingGetStarted = 'شروع کنیم';
  static const onboardingHaveAccount = 'قبلاً استفاده کرده‌ام';
  static const onboardingNameQuestion = 'چطور صدایت کنیم؟';
  static const onboardingNameHint = 'نام یا نام مستعار';
  static const onboardingGoalQuestion = 'هدفت از یادگیری انگلیسی چیست؟';
  static const onboardingGoalTravel = 'سفر و مکالمه';
  static const onboardingGoalWork = 'کار و مکاتبه';
  static const onboardingGoalExam = 'آزمون‌های بین‌المللی';
  static const onboardingGoalMedia = 'فیلم، سریال و کتاب';
  static const onboardingGoalAcademic = 'ادامه‌ی تحصیل';
  static const onboardingLevelQuestion = 'سطح فعلی‌ات را می‌دانی؟';
  static const onboardingLevelKnow = 'بله، می‌دانم';
  static const onboardingLevelTest = 'نه، تعیین سطح کن';
  static const onboardingDailyGoalQuestion = 'روزانه چقدر وقت می‌گذاری؟';
  static const onboardingDailyGoalHint = 'می‌توانی هر وقت خواستی تغییرش دهی.';
  static const onboardingFinish = 'آماده‌ام!';

  // ---------------------------------------------------------- تعیین سطح
  static const placementTitle = 'آزمون تعیین سطح';
  static const placementIntro =
      'یک آزمون کوتاه و هوشمند. هر سؤال سختی‌اش بر اساس پاسخ قبلی تو تنظیم می‌شود؛ '
      'پس نگران نباش اگر سؤالی سخت یا آسان بود.';
  static const placementStart = 'شروع آزمون';
  static const placementProgress = 'سؤال';
  static const placementChooseMeaning = 'معنی درست کدام است؟';
  static const placementChooseWord = 'کدام کلمه با این معنی هم‌خوان است؟';
  static const placementAnalyzing = 'در حال تحلیل پاسخ‌های تو…';
  static const placementResultTitle = 'سطح تو';
  static const placementResultBody =
      'بر اساس پاسخ‌هایت، برنامه‌ی یادگیری شخصی‌سازی شد. لغت‌های پیشنهادی، دشواری تمرین‌ها '
      'و زمان‌بندی مرور بر همین اساس تنظیم می‌شود.';
  static const placementResultStart = 'بریم سراغ لغت‌ها';
  static const placementResultRetest = 'آزمون دوباره';

  // ------------------------------------------------------------- خانه
  static String greetingMorning(String name) => 'صبح بخیر، $name';
  static String greetingNoon(String name) => 'روز بخیر، $name';
  static String greetingEvening(String name) => 'شب بخیر، $name';
  static const todayPlan = 'برنامه‌ی امروز';
  static const dueReviews = 'مرورهای امروز';
  static const newWords = 'لغت‌های تازه';
  static const startReview = 'شروع مرور';
  static const startLearn = 'یادگیری لغت جدید';
  static const dailyChallenge = 'چالش روزانه';
  static const wordOfTheDay = 'لغت امروز';
  static const dailyGoal = 'هدف امروز';
  static const streakLabel = 'زنجیره‌ی روزانه';
  static const xpLabel = 'امتیاز تجربه';
  static const levelLabel = 'سطح';
  static const keepGoing = 'همین‌طور ادامه بده!';
  static const allCaughtUp = 'همه‌ی مرورهای امروز انجام شد 🎉';
  static const weeklyActivity = 'فعالیت هفته';
  static const quickActions = 'دسترسی سریع';

  // --------------------------------------------------------- یادگیری
  static const learnTitle = 'یادگیری';
  static const flashcardHint = 'برای دیدن معنی، کارت را بزن';
  static const tapToFlip = 'برای دیدن پاسخ ضربه بزن';
  static const howWellDidYouKnow = 'چقدر یادت بود؟';
  static const gradeForgot = 'فراموش کردم';
  static const gradeHard = 'سخت بود';
  static const gradeGood = 'خوب بود';
  static const gradeEasy = 'آسان بود';
  static const sessionComplete = 'این جلسه تمام شد!';
  static const sessionSummary = 'خلاصه‌ی جلسه';
  static const reviewedCount = 'مرور شده';
  static const correctCount = 'پاسخ درست';
  static const wrongCount = 'پاسخ نادرست';
  static const earnedXp = 'امتیاز کسب‌شده';
  static const accuracyLabel = 'دقت';
  static const nextDueIn = 'مرور بعدی';

  // ------------------------------------------------------------ کوییز
  static const quizTitle = 'تمرین';
  static const quizCheck = 'بررسی';
  static const quizNextQuestion = 'سؤال بعدی';
  static const quizCorrect = 'درست بود!';
  static const quizWrong = 'اشتباه بود';
  static const quizTypeMeaning = 'معنی فارسی این لغت را بنویس';
  static const quizFillBlank = 'جای خالی را پر کن';
  static const quizListen = 'چه کلمه‌ای شنیدی؟';
  static const quizBuildSentence = 'جمله را مرتب کن';
  static const quizChooseTranslation = 'ترجمه‌ی درست کدام است؟';
  static const quizChooseWord = 'کدام کلمه با این معنی هم‌خوان است؟';
  static const quizPickCollocation = 'کدام ترکیب درست است؟';
  static const quizPickSynonym = 'مترادف این کلمه کدام است؟';
  static const quizPickAntonym = 'متضاد این کلمه کدام است؟';
  static const quizSubmit = 'ثبت پاسخ';
  static const quizHint = 'راهنما';
  static const quizShowAnswer = 'نمایش پاسخ';
  static const quizResult = 'نتیجه‌ی تمرین';
  static const quizAgain = 'تمرین دوباره';
  static const quizReviewMistakes = 'مرور اشتباه‌ها';
  static const answerLabel = 'پاسخ';

  // ------------------------------------------------------ چالش روزانه
  static const challengeTitle = 'چالش روزانه';
  static const challengeSubtitle = '۱۰ سؤال ترکیبی، هر روز نوسازی می‌شود';
  static const challengeStart = 'شروع چالش';
  static const challengeCompleted = 'چالش امروز را کامل کردی!';
  static const challengeComeBack = 'فردا چالش تازه‌ای منتظرت است';
  static const challengeReward = 'جایزه';
  static const challengeStreakGuard = 'با تکمیل چالش، زنجیره‌ات حفظ می‌شود';

  // ------------------------------------------------------------- کاوش
  static const exploreTitle = 'کاوش';
  static const searchHint = 'لغت انگلیسی یا معنی فارسی…';
  static const wordPacks = 'بسته‌های موضوعی';
  static const byLevel = 'بر اساس سطح';
  static const allWords = 'همه‌ی لغت‌ها';
  static const noResult = 'چیزی پیدا نشد';
  static const noResultHint = 'املای دیگری را امتحان کن یا از فیلترها استفاده کن.';
  static const filterStatus = 'وضعیت';
  static const filterLevel = 'سطح';
  static const filterTopic = 'موضوع';
  static const statusAll = 'همه';
  static const statusNew = 'جدید';
  static const statusLearning = 'در حال یادگیری';
  static const statusReviewing = 'در حال مرور';
  static const statusMastered = 'مسلط';
  static const statusLeech = 'سخت‌آموز';
  static const statusBookmarked = 'نشان‌شده';
  static const sortByFrequency = 'پرتکرارترین';
  static const sortByDifficulty = 'دشوارترین';
  static const sortByRecent = 'تازه‌ترین';

  // ----------------------------------------------------------- جزئیات لغت
  static const meaningSection = 'معنی';
  static const definitionSection = 'توضیح';
  static const pronunciationSection = 'تلفظ';
  static const imageSection = 'تصویر واژه';
  static const wordImageSoon = 'تصویر این واژه به‌زودی';
  static const examplesSection = 'مثال‌ها';
  static const conversationSection = 'در مکالمه';
  static const mediaSection = 'در فیلم و سریال';
  static const collocationsSection = 'کالوکیشن‌ها';
  static const synonymsSection = 'مترادف‌ها';
  static const antonymsSection = 'متضادها';
  static const formsSection = 'شکل‌های کلمه';
  static const topicsSection = 'موضوع‌ها';
  static const persianNoteSection = 'نکته برای فارسی‌زبانان';
  static const mnemonicSection = 'ترفند حفظ';
  static const relatedWords = 'لغت‌های مرتبط';
  static const addToReview = 'افزودن به مرور';
  static const addedToReview = 'به لیست مرور اضافه شد';
  static const bookmark = 'نشان‌گذاری';
  static const unbookmark = 'حذف نشان';
  static const playAudio = 'پخش تلفظ';
  static const audioUnavailable = 'تلفظ صوتی روی این دستگاه در دسترس نیست';
  static const askAi = 'پرسیدن از دستیار هوشمند';
  static const difficultyLabel = 'دشواری';
  static const frequencyLabel = 'رتبه‌ی کاربرد';
  static const myNote = 'یادداشت من';
  static const myNoteHint = 'مثال یا ترفند شخصی‌ات را بنویس…';
  static const mistakeCount = 'تعداد خطا';
  static const neverReviewed = 'هنوز مرور نشده';

  // ------------------------------------------------------------ پیشرفت
  static const progressTitle = 'پیشرفت';
  static const overviewSection = 'نمای کلی';
  static const wordsLearned = 'لغت‌های یادگرفته';
  static const wordsMastered = 'لغت‌های مسلط';
  static const totalReviews = 'کل مرورها';
  static const studyTime = 'زمان مطالعه';
  static const masteryDistribution = 'توزیع تسلط';
  static const accuracyTrend = 'روند دقت';
  static const activityHeatmap = 'نقشه‌ی فعالیت';
  static const weakWordsTitle = 'نقاط ضعف';
  static const weakWordsBody = 'این لغت‌ها بیشترین خطا را داشته‌اند؛ پیشنهاد می‌کنیم امروز مرورشان کنی.';
  static const weakAreas = 'زمینه‌های ضعیف';
  static const noWeakWords = 'هنوز داده‌ی کافی برای تحلیل نداریم. چند تمرین انجام بده!';
  static const startWeakReview = 'مرور لغت‌های ضعیف';
  static const last7Days = '۷ روز';
  static const last30Days = '۳۰ روز';
  static const allTime = 'کل';

  // --------------------------------------------------------- دستاوردها
  static const achievementsTitle = 'دستاوردها';
  static const achievementsUnlocked = 'باز شده';
  static const achievementsLocked = 'قفل';
  static const achievementsAll = 'همه';
  static const achievementUnlockedToast = 'دستاورد جدید باز شد!';

  // -------------------------------------------------------------- پروفایل
  static const profileTitle = 'پروفایل';
  static const editProfile = 'ویرایش پروفایل';
  static const settingsTitle = 'تنظیمات';
  static const appearanceSection = 'ظاهر';
  static const themeSystem = 'سیستم';
  static const themeLight = 'روشن';
  static const themeDark = 'تیره';
  static const learningSection = 'یادگیری';
  static const dailyGoalLabel = 'هدف روزانه';
  static const wordsPerDayLabel = 'لغت جدید در روز';
  static const reminderLabel = 'یادآور روزانه';
  static const reminderTimeLabel = 'ساعت یادآور';
  static const audioSection = 'صدا و تلفظ';
  static const speechRateLabel = 'سرعت تلفظ';
  static const autoPlayLabel = 'پخش خودکار تلفظ';
  static const accountSection = 'حساب کاربری';
  static const subscriptionLabel = 'اشتراک';
  static const subscriptionFree = 'نسخه‌ی رایگان';
  static const subscriptionPremium = 'نسخه‌ی ویژه';
  static const subscriptionManage = 'مدیریت اشتراک';
  static const upgradeCta = 'ارتقا به نسخه‌ی ویژه';
  static const dataSection = 'داده‌ها';
  static const exportData = 'برون‌بری پیشرفت';
  static const resetProgress = 'پاک‌کردن پیشرفت';
  static const resetProgressConfirm =
      'تمام پیشرفت، زنجیره و دستاوردهای تو پاک می‌شود. مطمئنی؟';
  static const aboutSection = 'درباره';
  static const versionLabel = 'نسخه';
  static const contactUs = 'ارتباط با ما';
  static const termsLabel = 'قواعد و شرایط';
  static const privacyLabel = 'حریم خصوصی';
  static const logoutLabel = 'خروج از حساب';
  static const savedToast = 'ذخیره شد';

  // ------------------------------------------------------------- اشتراک
  static const paywallTitle = 'واژه‌یار ویژه';
  static const paywallHeadline = 'یادگیری بی‌مرز، بدون تبلیغ';
  static const paywallFeature1 = 'دسترسی به تمام لغت‌ها و بسته‌های موضوعی';
  static const paywallFeature2 = 'تمرین‌های نامحدود و مرور هوشمند بی‌سقف';
  static const paywallFeature3 = 'دستیار هوش مصنوعی بدون محدودیت';
  static const paywallFeature4 = 'تحلیل عمیق نقاط ضعف و برنامه‌ی شخصی';
  static const paywallFeature5 = 'بدون هیچ تبلیغی';
  static const paywallMonthly = 'اشتراک ماهانه';
  static const paywallYearly = 'اشتراک سالانه';
  static const paywallLifetime = 'خرید دائمی';
  static const paywallBestValue = 'به‌صرفه‌ترین';
  static const paywallMonthlySave = 'انصراف هر زمان';
  static const paywallYearlySave = '٪۴۰ ارزان‌تر از ماهانه';
  static const paywallTrial = '۷ روز آزمایش رایگان';
  static const paywallCta = 'فعال‌سازی آزمایش رایگان';
  static const paywallRestore = 'بازیابی خرید';
  static const paywallTerms =
      'پرداخت پس از پایان دوره‌ی آزمایش از حساب کاربری‌ات کسر می‌شود. '
      'اشتراک به‌صورت خودکار تمدید می‌شود و می‌توانی هر زمان لغو کنی.';
  static const paywallActivated = 'اشتراک ویژه فعال شد 🎉';
  static const paywallRestored = 'خرید شما بازیابی شد';
  static const paywallNothingToRestore = 'خرید فعالی برای بازیابی پیدا نشد';
  static const premiumWordLocked = 'این لغت ویژه‌ی اعضای اشتراک است';
  static const premiumLimitReached = 'سهمیه‌ی امروز نسخه‌ی رایگان تمام شد';
  static const premiumLimitBody = 'برای ادامه‌ی یادگیری بی‌محدود، نسخه‌ی ویژه را فعال کن.';

  // ------------------------------------------------------ دستیار هوشمند
  static const chatTitle = 'دستیار هوشمند';
  static const chatHint = 'درباره‌ی هر لغت بپرس…';
  static const chatWelcome =
      'سلام! درباره‌ی لغت‌ها هر سؤالی داری بپرس؛ مثلاً «معنی resilient چیست؟»، '
      '«برای adapt مثال بساز» یا «فرق affect و effect».';
  static const chatSuggestion1 = 'برای این لغت یک مثال ساده بساز';
  static const chatSuggestion2 = 'فرق این دو لغت چیست؟';
  static const chatSuggestion3 = 'این لغت را ساده‌تر توضیح بده';
  static const chatSuggestion4 = 'از لغت‌های امروزم کوییز بگیر';
  static const chatThinking = 'در حال نوشتن…';
  static const chatClear = 'پاک‌کردن گفت‌وگو';
  static const chatOfflineNote =
      'دستیار فعلی روی دستگاه کار می‌کند و به اینترنت نیاز ندارد.';
  static const chatFallbackNote = 'پاسخ راهنما';

  // --------------------------------------------------------- یادآورها/خطا
  static const noInternet = 'اتصال اینترنت برقرار نیست';
  static const contentUpdateAvailable = 'محتوای تازه در دسترس است';
  static const contentUpdated = 'محتوای لغت‌ها به‌روز شد';
  static const emptyBookmarks = 'هنوز لغتی را نشان نکرده‌ای';
  static const emptyHistory = 'هنوز جلسه‌ای ثبت نشده';
  static const studyReminderTitle = 'وقت مرور است!';
  static const studyReminderBody = 'چند دقیقه وقت بگذار و لغت‌های امروز را مرور کن.';
}
