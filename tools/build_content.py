#!/usr/bin/env python3
"""سازنده‌ی بسته‌ی محتوای واژه‌یار.

ورودی‌ها (پوشه‌ی tools/content):
  * words_<level>.txt   داده‌ی واژه‌ها، یک واژه در هر خط (فیلدها با «||»)
  * media_lines.txt     دیالوگ‌های فیلم/سریال برای واژه‌ها (اختیاری)
  * packs.txt           بسته‌های موضوعی و واژه‌های هر بسته

خروجی‌ها (پوشه‌ی assets/content):
  * words_a1.json … words_c2.json
  * packs.json
  * manifest.json
  * ارجاع تصویر هر واژه، اگر فایلی با نام شناسه‌ی آن در assets/images باشد

کارهایی که خودکار انجام می‌شود:
  * تبدیل تلفظ ARPAbet فرهنگ لغت cmudict به الفبای آوانگاری IPA
  * محاسبه‌ی رتبه‌ی کاربرد واژه از پیکره‌ی wordfreq (۵۰٬۰۰۰ واژه‌ی اول)
  * محاسبه‌ی درجه‌ی دشواری (۱..۵) از سطح CEFR، رتبه‌ی کاربرد و املای واژه
  * اعتبارسنجی: یکتا بودن شناسه، کد نقش دستوری/سطح، وجود واژه در مثال‌ها

اجرا:
    /tmp/tools/bin/python tools/build_content.py
"""

from __future__ import annotations

import json
import os
import re
import sys
from collections import Counter, OrderedDict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT_DIR = os.path.join(ROOT, "tools", "content")
OUT_DIR = os.path.join(ROOT, "assets", "content")
IMAGE_DIR = os.path.join(ROOT, "assets", "images")
IMAGE_EXTS = (".webp", ".png", ".jpg", ".jpeg")
MEBIBYTE = 1024 * 1024


LEVELS = ["a1", "a2", "b1", "b2", "c1", "c2"]
POS_CODES = {
    "n", "v", "adj", "adv", "prep", "pron", "conj", "det", "intj", "num",
    "phr", "phrv", "idiom",
}

# --------------------------------------------------------- شکل‌های واژه

#: شکل‌های بی‌قاعده‌ی فعل: term → (گذشته، اسم مفعولی)
IRREGULAR_VERBS: dict[str, tuple[str, str]] = {
    "arise": ("arose", "arisen"),
    "buy": ("bought", "bought"),
    "choose": ("chose", "chosen"),
    "come": ("came", "come"),
    "drink": ("drank", "drunk"),
    "drive": ("drove", "driven"),
    "eat": ("ate", "eaten"),
    "find": ("found", "found"),
    "forbid": ("forbade", "forbidden"),
    "forget": ("forgot", "forgotten"),
    "forgive": ("forgave", "forgiven"),
    "get": ("got", "got"),
    "give": ("gave", "given"),
    "go": ("went", "gone"),
    "know": ("knew", "known"),
    "lend": ("lent", "lent"),
    "lose": ("lost", "lost"),
    "make": ("made", "made"),
    "meet": ("met", "met"),
    "pay": ("paid", "paid"),
    "read": ("read", "read"),
    "ride": ("rode", "ridden"),
    "run": ("ran", "run"),
    "say": ("said", "said"),
    "see": ("saw", "seen"),
    "send": ("sent", "sent"),
    "sleep": ("slept", "slept"),
    "speak": ("spoke", "spoken"),
    "spend": ("spent", "spent"),
    "swim": ("swam", "swum"),
    "take": ("took", "taken"),
    "tell": ("told", "told"),
    "think": ("thought", "thought"),
    "understand": ("understood", "understood"),
    "win": ("won", "won"),
    "withstand": ("withstood", "withstood"),
    "write": ("wrote", "written"),
}

#: فعل‌هایی که در انگلیسی آمریکایی حرف آخرشان دو برابر می‌شود.
#: فعل‌های چندسیلابی که تکیه روی هجای آخر است و حرف آخرشان دو برابر می‌شود.
DOUBLE_FINAL_VERBS = {
    "commit", "control", "deter", "fit", "forbid", "forget", "occur", "permit",
    "prefer", "stop", "transmit",
}

#: صفت‌هایی که شکل برتر/برترینشان دو برابر می‌شود.
DOUBLE_FINAL_ADJS = {"big", "hot", "sad"}

#: فقط همین صفت‌ها شکل برتر/برترین می‌گیرند (کوتاه و پرکاربرد).
DEGREE_ADJS = {
    "big", "busy", "cheap", "cold", "easy", "fast", "free", "friendly", "happy",
    "hard", "healthy", "hot", "new", "old", "ready", "sad", "simple", "slow",
    "small", "sure", "young",
}

#: صفت‌هایی که درجه‌پذیر نیستند (برتر/برترینشان بی‌معنی است).
NON_GRADABLE = {
    "adamant", "constant", "entire", "equivalent", "eventual", "extra",
    "identical", "initial",
    "impossible", "inevitable", "local", "mutual", "negligible", "obsolete",
    "paramount", "permanent", "possible", "right", "same", "sole", "ultimate",
    "unique", "wrong",
}

#: صفت‌های بی‌قاعده در حالت برتر/برترین.
IRREGULAR_DEGREE: dict[str, tuple[str, str]] = {
    "bad": ("worse", "worst"),
    "good": ("better", "best"),
    "ill": ("worse", "worst"),
}

#: جمع‌های بی‌قاعده.
IRREGULAR_PLURALS: dict[str, str] = {
    "child": "children",
    "criterion": "criteria",
    "hypothesis": "hypotheses",
    "man": "men",
    "phenomenon": "phenomena",
    "woman": "women",
}

#: اسم‌های غیرقابل‌شمارش (جمع بستنشان بی‌معنی است).
UNCOUNTABLE = {
    "acumen", "altruism", "attention", "autonomy", "behavior", "candor",
    "cohesion", "confidence", "consensus", "courage", "demeanor", "discretion",
    "disdain", "education", "evidence", "food", "health", "impetus",
    "integrity", "knowledge", "luggage", "magnitude", "momentum", "money",
    "music", "myriad", "patience", "percent", "potential", "progress", "rain",
    "snow", "staff", "stress", "sun", "talent", "water", "weather", "work",
    # اسم‌هایی که جمع بستنشان گمراه‌کننده است:
    "internet", "people", "series",
}

#: برچسب‌های مجاز موضوعی — همان واژه‌نامه‌ای که موتورها می‌فهمند.
TOPIC_TAGS = {
    "academic", "body", "business", "daily", "feelings", "food", "health",
    "home", "media", "money", "nature", "people", "science", "society",
    "sports", "study", "tech", "thought", "time", "travel", "work",
}

FORMS_POS = {"n", "v", "adj"}

#: حروف صدادار انگلیسی در نوشتار (نام متفاوت از جدول IPA تا تداخل نشود).
EN_VOWELS = "aeiou"
#: پایانه‌هایی که سوم‌شخص مفرد «es» می‌گیرد (go → goes).
VERB_ES_ENDINGS = ("s", "x", "z", "ch", "sh", "o")
#: پایانه‌هایی که جمع «es» می‌گیرد (bus → buses؛ photo → photos).
NOUN_ES_ENDINGS = ("s", "x", "z", "ch", "sh")


def _double_final(term: str) -> str:
    """بازگرداندن واژه با حرف آخر دوبرابر (stop → stopp)."""
    return term + term[-1]


def _is_consonant(letter: str) -> bool:
    return letter not in EN_VOWELS


def _syllables(term: str) -> int:
    return len(re.findall(r"[aeiouy]+", term))


def _is_vowel(letter: str) -> bool:
    return letter in EN_VOWELS


def _doubles(term: str) -> bool:
    """آیا فعل در صرف، حرف آخرش دو برابر می‌شود؟ (stop → stopping)"""
    if term in DOUBLE_FINAL_VERBS:
        return True
    if len(term) < 3 or term[-1] in "wxy":
        return False
    last, middle, first = term[-3], term[-2], term[-1]
    if _is_consonant(last) and _is_vowel(middle) and _is_consonant(first):
        # فقط فعل‌های تک‌سیلابی به‌طور خودکار دو برابر می‌شوند.
        return _syllables(term) == 1
    return False


def _past_form(term: str) -> tuple[str, str]:
    """شکل گذشته و اسم مفعولی یک فعل ساده."""
    irregular = IRREGULAR_VERBS.get(term)
    if irregular:
        return irregular
    if term.endswith("y") and len(term) > 2 and _is_consonant(term[-2]):
        return term[:-1] + "ied", term[:-1] + "ied"
    if term.endswith("e"):
        return term + "d", term + "d"
    if _doubles(term):
        doubled = _double_final(term)
        return doubled + "ed", doubled + "ed"
    return term + "ed", term + "ed"


def _ing_form(term: str) -> str:
    if term.endswith("ie"):
        return term[:-2] + "ying"
    if term.endswith("e") and not term.endswith(("ee", "ye", "oe")):
        return term[:-1] + "ing"
    if _doubles(term):
        return _double_final(term) + "ing"
    return term + "ing"


def _third_person(term: str) -> str:
    if term.endswith("y") and len(term) > 2 and _is_consonant(term[-2]):
        return term[:-1] + "ies"
    if term.endswith(VERB_ES_ENDINGS):
        return term + "es"
    return term + "s"


def _plural_form(term: str) -> str | None:
    if term in UNCOUNTABLE or term in IRREGULAR_PLURALS:
        return IRREGULAR_PLURALS.get(term)
    if term.endswith("y") and len(term) > 2 and _is_consonant(term[-2]):
        return term[:-1] + "ies"
    if term.endswith(NOUN_ES_ENDINGS):
        return term + "es"
    return term + "s"


def _degree_forms(term: str) -> tuple[str, str] | None:
    irregular = IRREGULAR_DEGREE.get(term)
    if irregular:
        return irregular
    if term in NON_GRADABLE:
        return None
    if term not in DEGREE_ADJS:
        # صفت‌های بلندتر با more/most درجه می‌گیرند.
        return f"more {term}", f"most {term}"
    if term in DOUBLE_FINAL_ADJS:
        doubled = _double_final(term)
        return doubled + "er", doubled + "est"
    if term.endswith("y"):
        return term[:-1] + "ier", term[:-1] + "iest"
    if term.endswith("e"):
        return term + "r", term + "st"
    return term + "er", term + "est"


def forms_for(term: str, pos: str) -> list[dict]:
    """شکل‌های صرفی واژه با برچسب فارسی (خالی برای واژه‌های نقشی)."""
    forms: list[dict] = []
    if pos == "v":
        past, participle = _past_form(term)
        candidates = [
            ("گذشته", past),
            ("اسم مفعول", participle),
            ("حال استمراری", _ing_form(term)),
            ("سوم‌شخص مفرد", _third_person(term)),
        ]
    elif pos == "n":
        plural = _plural_form(term)
        candidates = [("جمع", plural)] if plural else []
    elif pos == "adj":
        degree = _degree_forms(term)
        candidates = [("برتر", degree[0]), ("برترین", degree[1])] if degree else []
    else:
        return forms

    seen = {term.lower()}
    for label, value in candidates:
        if not value or value.lower() in seen:
            continue
        seen.add(value.lower())
        forms.append({"label": label, "value": value})
    return forms


# ------------------------------------------------------------ برچسب موضوعی

def load_topics() -> tuple[dict[str, list[str]], list[str]]:
    """برچسب‌های موضوعی از `tools/content/topics.txt`."""
    rows = read_lines(os.path.join(CONTENT_DIR, "topics.txt"))
    mapping: dict[str, list[str]] = {}
    problems: list[str] = []
    for row in rows:
        if len(row) < 2:
            problems.append(f"topics.txt خط نامعتبر: {'||'.join(row)[:40]}")
            continue
        term = row[0].lower()
        tags = split_multi(row[1])
        if term in mapping:
            problems.append(f"topics.txt واژه‌ی تکراری: {term}")
            continue
        unknown = [tag for tag in tags if tag not in TOPIC_TAGS]
        if unknown:
            problems.append(f"{term}: برچسب ناشناخته {unknown}")
        if not tags:
            problems.append(f"{term}: بدون برچسب")
            continue
        mapping[term] = [tag for tag in tags if tag in TOPIC_TAGS]
    return mapping, problems


# ------------------------------------------------------- کالوکیشن‌های تکمیلی

def load_extra_collocations() -> tuple[dict[str, tuple[str, list[str]]], list[str]]:
    """ترکیب‌های تکمیلی از `tools/content/extra_collocations.txt`.

    قالب: `term||+ترکیب؛ترکیب` برای افزودن و `term||=ترکیب؛ترکیب` برای
    جای‌گزینی. خروجی: term → (حالت، ترکیب‌ها) با حالت `+` یا `=`.
    """
    rows = read_lines(os.path.join(CONTENT_DIR, "extra_collocations.txt"))
    mapping: dict[str, tuple[str, list[str]]] = {}
    problems: list[str] = []
    for row in rows:
        if len(row) < 2:
            problems.append(f"extra_collocations.txt خط نامعتبر: {'||'.join(row)[:40]}")
            continue
        term = row[0].lower()
        raw = row[1].strip()
        mode = "+"
        if raw.startswith("="):
            mode = "="
            raw = raw[1:].strip()
        elif raw.startswith("+"):
            raw = raw[1:].strip()
        items = split_multi(raw)
        if not items:
            problems.append(f"{term}: ترکیب خالی")
            continue
        if term in mapping:
            problems.append(f"extra_collocations.txt واژه‌ی تکراری: {term}")
            continue
        mapping[term] = (mode, items)
    return mapping, problems




# --------------------------------------------------------------- تلفظ (IPA)

IRREGULAR_FORMS: dict[str, set[str]] = {
    "criterion": {"criteria"},
    "phenomenon": {"phenomena"},
    "hypothesis": {"hypotheses"},
    "analysis": {"analyses"},
    "basis": {"bases"},
    "child": {"children"},
    "man": {"men"},
    "woman": {"women"},
    "person": {"people"},
    "foot": {"feet"},
    "tooth": {"teeth"},
    "go": {"went", "gone"},
    "get": {"got", "gotten"},
    "give": {"gave", "given"},
    "take": {"took", "taken"},
    "make": {"made"},
    "see": {"saw", "seen"},
    "come": {"came"},
    "know": {"knew", "known"},
    "find": {"found"},
    "tell": {"told"},
    "say": {"said"},
    "pay": {"paid"},
    "buy": {"bought"},
    "send": {"sent"},
    "lend": {"lent"},
    "spend": {"spent"},
    "lose": {"lost"},
    "win": {"won"},
    "swim": {"swam", "swum"},
    "forget": {"forgot", "forgotten"},
    "forbid": {"forbade", "forbidden"},
    "forgive": {"forgave", "forgiven"},
    "arise": {"arose", "arisen"},
    "withstand": {"withstood"},
    "overcome": {"overcame"},
    "understand": {"understood"},
    "study": {"studied", "studies"},
    "apply": {"applied", "applies"},
    "deny": {"denied", "denies"},
    "rely": {"relied", "relies"},
    "reply": {"replied", "replies"},
    "vary": {"varied", "varies"},
    "imply": {"implied", "implies"},
    "justify": {"justified", "justifies"},
    "satisfy": {"satisfied", "satisfies"},
    "classify": {"classified", "classifies"},
    "occupy": {"occupied", "occupies"},
    "modify": {"modified", "modifies"},
    "exemplify": {"exemplified", "exemplifies"},
    "criticize": {"criticized", "criticizes"},
    "emphasize": {"emphasized", "emphasizes"},
    "analyze": {"analyzed", "analyzes"},
    "realize": {"realized", "realizes"},
    "recognize": {"recognized", "recognizes"},
    "utilize": {"utilized", "utilizes"},
    "paralyze": {"paralyzed", "paralyzes"},
}

ARPABET_TO_IPA = {
    "AA": "ɑ", "AE": "æ", "AH": "ʌ", "AH0": "ə", "AO": "ɔ", "AW": "aʊ",
    "AY": "aɪ", "B": "b", "CH": "tʃ", "D": "d", "DH": "ð", "EH": "e",
    "ER": "ɜːr", "ER0": "ər", "EY": "eɪ", "F": "f", "G": "ɡ", "HH": "h",
    "IH": "ɪ", "IY": "iː", "JH": "dʒ", "K": "k", "L": "l", "M": "m",
    "N": "n", "NG": "ŋ", "OW": "oʊ", "OY": "ɔɪ", "P": "p", "R": "r",
    "S": "s", "SH": "ʃ", "T": "t", "TH": "θ", "UH": "ʊ", "UW": "uː",
    "V": "v", "W": "w", "Y": "j", "Z": "z", "ZH": "ʒ",
}

VOWELS = {"ɑ", "æ", "ʌ", "ə", "ɔ", "a", "aɪ", "aʊ", "e", "eɪ", "iː",
          "ɪ", "oʊ", "ɔɪ", "uː", "ʊ", "ɜːr", "ər", "ɜ"}


#: تلفظ دستی واژه‌های چندبخشی که در cmudict نیستند.
IPA_OVERRIDES: dict[str, str] = {
    "free time": "/frˈiː tˈaɪm/",
    "improve on": "/ɪmprˈuːv ɒn/",
    "learn from": "/lˈɜːrn frəm/",
    "remember to": "/rɪmˈembər tuː/",
}


def _load_cmudict():
    try:
        import cmudict  # type: ignore
    except ImportError:
        print("! cmudict نصب نیست؛ تلفظ‌ها خالی می‌مانند")
        return {}
    return cmudict.dict()


def _load_frequency():
    try:
        from wordfreq import top_n_list  # type: ignore
    except ImportError:
        print("! wordfreq نصب نیست؛ رتبه‌ی کاربرد محاسبه نمی‌شود")
        return {}
    top = top_n_list("en", 50000)
    ranks = {}
    for index, word in enumerate(top, start=1):
        ranks.setdefault(word, index)
    return ranks


def arpabet_to_ipa(phones: list[str]) -> str:
    """تبدیل تلفظ ARPAbet به IPA با استرس ساده."""
    out = []
    for phone in phones:
        phone = phone.upper()
        stress = ""
        if phone.endswith("1"):
            stress = "ˈ"
        elif phone.endswith("2"):
            stress = "ˌ"
        phone = re.sub(r"\d$", "", phone)
        ipa = ARPABET_TO_IPA.get(phone)
        if ipa is None:
            continue
        out.append(stress + ipa)
    return "".join(out)


def ipa_for(term: str, cmu: dict, previous: dict | None = None) -> str | None:
    override = IPA_OVERRIDES.get(term.lower())
    if override:
        return override
    entry = cmu.get(term.lower())
    if not entry:
        # اجرای بیلدر بدون cmudict: تلفظ پیشین حفظ می‌شود.
        return (previous or {}).get(term.lower())
    # نخستین تلفظ در cmudict رایج‌ترین است.
    ipa = arpabet_to_ipa(entry[0])
    if not ipa:
        return None
    return f"/{ipa}/"


def difficulty_for(level: str, rank: int, term: str) -> int:
    """درجه‌ی دشواری ۱..۵ از سطح، کاربرد و املای واژه."""
    base = {"a1": 1, "a2": 1, "b1": 2, "b2": 3, "c1": 4, "c2": 5}.get(level, 3)
    if rank == 0:
        base += 1  # واژه‌ی کم‌کاربرد
    elif rank <= 500:
        base -= 1
    elif rank > 12000:
        base += 1
    if len(term) >= 12 or term.count("-") > 0 or term.count(" ") > 0:
        base += 1
    return max(1, min(5, base))


# ------------------------------------------------------------------- خواندن

def read_lines(path: str) -> list[list[str]]:
    if not os.path.exists(path):
        return []
    rows = []
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            rows.append([part.strip() for part in line.split("||")])
    return rows


def split_multi(value: str) -> list[str]:
    if not value:
        return []
    parts = re.split(r"[؛;]", value)
    return [part.strip() for part in parts if part.strip()]


def term_forms(term: str) -> set[str]:
    """شکل‌های ساده‌ی واژه برای بررسی حضور در مثال (جمع/گذشته/ing)."""
    t = term.lower().strip()
    if " " in t:
        head = t.split()[0]
        return {t, t.replace(head, head + "s", 1)}
    forms = {t}
    if t.endswith("y") and len(t) > 2 and t[-2] not in "aeiou":
        forms |= {t[:-1] + "ies", t[:-1] + "ied"}
    elif t.endswith(("s", "x", "ch", "sh", "z")):
        forms.add(t + "es")
    elif t.endswith("e"):
        forms |= {t + "d", t[:-1] + "ing"}
    else:
        forms |= {t + "s", t + "ed", t + "ing"}
    forms |= IRREGULAR_FORMS.get(t, set())
    return forms


def example_has_term(term: str, sentence: str) -> bool:
    low = sentence.lower()
    return any(form and form in low for form in term_forms(term))


def parse_forms(value: str) -> list[dict]:
    forms = []
    for item in split_multi(value):
        if ":" in item:
            label, form = item.split(":", 1)
            forms.append({"label": label.strip(), "value": form.strip()})
    return forms


def image_for(word_id: str) -> str | None:
    """ارجاع تصویر واژه: فایل هم‌نام شناسه در assets/images.

    تصویر بخشی از بسته‌ی محتوای متنی نیست؛ هر وقت فایل تصویری با نام شناسه
    (مثلاً `a1_001.webp`) در پوشه‌ی تصاویر گذاشته شود، با اجرای بیلدر به
    JSON همان واژه اضافه می‌شود. نبودن تصویر خطا نیست.
    """
    for ext in IMAGE_EXTS:
        rel = f"assets/images/{word_id}{ext}"
        path = os.path.join(ROOT, rel)
        if os.path.exists(path):
            size = os.path.getsize(path)
            if size > 2 * MEBIBYTE:
                print(f"  هشدار: تصویر {rel} بزرگ است ({size // 1024} کیلوبایت)")
            return rel
    return None


def load_previous() -> tuple[dict[str, str], dict[str, int]]:
    """تلفظ و رتبه‌ی کاربرد از بسته‌ی فعلی.

    وقتی cmudict/wordfreq نصب نیستند (مثلاً اجرای بیلدر روی ماشین بدون
    اینترنت)، این دو مقدار از خروجی قبلی حفظ می‌شود تا بیلد، محتوا را
    خراب نکند. با کتابخانه‌های نصب‌شده، مقادیر تازه محاسبه می‌شوند.
    """
    ipas: dict[str, str] = {}
    ranks: dict[str, int] = {}
    for level in LEVELS:
        path = os.path.join(OUT_DIR, f"words_{level}.json")
        if not os.path.exists(path):
            continue
        try:
            with open(path, encoding="utf-8") as handle:
                payload = json.load(handle, object_pairs_hook=OrderedDict)
        except (ValueError, OSError):
            continue
        for item in payload.get("words", []):
            term = str(item.get("term", "")).lower()
            if item.get("ipa"):
                ipas[term] = item["ipa"]
            rank = item.get("rank")
            if isinstance(rank, int) and rank > 0:
                ranks[term] = rank
    return ipas, ranks


def build_words(
    cmu: dict,
    ranks: dict,
    topics: dict[str, list[str]] | None = None,
    previous_ipa: dict[str, str] | None = None,
    extra_collocations: dict[str, tuple[str, list[str]]] | None = None,
) -> tuple[list[dict], list[str]]:
    words: list[dict] = []
    warnings: list[str] = []
    topics = topics or {}
    extra_collocations = extra_collocations or {}
    tagged: set[str] = set()
    used_collocations: set[str] = set()
    seen_ids: set[str] = set()

    for level in LEVELS:
        path = os.path.join(CONTENT_DIR, f"words_{level}.txt")
        rows = read_lines(path)
        print(f"  words_{level}.txt → {len(rows)} واژه")
        for index, row in enumerate(rows, start=1):
            if len(row) < 9:
                warnings.append(f"{level}:{index} فیلدهای ناکافی ({len(row)})")
                continue
            term = row[0]
            pos = row[1].lower()
            fa_meanings = split_multi(row[3])
            entry = OrderedDict()
            entry["id"] = f"{level}{index:03d}"
            entry["term"] = term
            entry["pos"] = pos if pos in POS_CODES else "n"
            if pos not in POS_CODES:
                warnings.append(f"{term}: نقش دستوری ناشناخته «{pos}»")
            entry["level"] = level
            ipa = ipa_for(term, cmu, previous_ipa)
            if ipa:
                entry["ipa"] = ipa
            entry["rank"] = ranks.get(term.lower(), 0)
            entry["diff"] = difficulty_for(level, entry["rank"], term)
            entry["fa"] = fa_meanings or [row[4][:40]]
            entry["def"] = row[4]

            examples = []
            if len(row) > 5 and row[5]:
                examples.append({"en": row[5], "fa": row[6] if len(row) > 6 else ""})
            if len(row) > 7 and row[7]:
                examples.append(
                    {"en": row[7], "fa": row[8] if len(row) > 8 else "", "k": "conv"}
                )
            entry["ex"] = examples
            if examples and not any(example_has_term(term, item["en"]) for item in examples):
                warnings.append(f"{term}: در هیچ مثالی نیامده → {examples[0]['en'][:40]}")
            if len(row) > 9 and row[9]:
                entry["col"] = split_multi(row[9])
            extra = extra_collocations.get(term.lower())
            if extra is not None:
                mode, items = extra
                used_collocations.add(term.lower())
                base = [] if mode == "=" else list(entry.get("col", []))
                for item in items:
                    if item not in base:
                        base.append(item)
                if base:
                    entry["col"] = base
                else:
                    entry.pop("col", None)
            if len(row) > 10 and row[10]:
                entry["syn"] = split_multi(row[10])
            if len(row) > 11 and row[11]:
                entry["ant"] = split_multi(row[11])
            collocations = entry.get("col", [])
            if collocations and not example_has_term(term, collocations[0]):
                warnings.append(
                    f"{term}: ترکیب اول واژه را در خود ندارد → {collocations[0][:40]}"
                )
            if len(row) > 12 and row[12]:
                entry["note"] = row[12]
            if len(row) > 13 and row[13]:
                entry["emoji"] = row[13]
            topic_tags = topics.get(term.lower())
            if topic_tags is None and len(row) > 14 and row[14]:
                topic_tags = split_multi(row[14])
            if topic_tags:
                entry["topics"] = topic_tags
                tagged.add(term.lower())
            if len(row) > 15 and row[15]:
                entry["forms"] = parse_forms(row[15])
            if len(row) > 16 and row[16]:
                entry["mnemonic"] = row[16]
            if len(row) > 17 and row[17] in ("1", "premium", "vip"):
                entry["premium"] = True

            generated_forms = forms_for(term, entry["pos"])
            if generated_forms:
                entry["forms"] = generated_forms

            image = image_for(entry["id"])
            if image:
                entry["image"] = image

            if entry["id"] in seen_ids:
                warnings.append(f"شناسه‌ی تکراری: {entry['id']}")
            seen_ids.add(entry["id"])
            words.append(entry)

    untagged = [word["term"] for word in words if word["term"].lower() not in tagged]
    if untagged:
        warnings.append(
            f"{len(untagged)} واژه بدون برچسب موضوعی: {'، '.join(untagged[:8])}"
        )
    return words, warnings


# ------------------------------------------------------------------ رسانه‌ها

def attach_media(words: list[dict]) -> tuple[int, list[str]]:
    rows = read_lines(os.path.join(CONTENT_DIR, "media_lines.txt"))
    if not rows:
        return 0, []
    index = {word["term"].lower(): word for word in words}
    attached = 0
    problems: list[str] = []
    seen: set[tuple[str, str]] = set()
    for position, row in enumerate(rows, start=1):
        if len(row) < 5:
            problems.append(f"media_lines.txt:{position} فیلدهای ناکافی ({len(row)})")
            continue
        term, line, fa, title = row[0], row[1], row[2], row[3]
        word = index.get(term.lower())
        if word is None:
            problems.append(f"media_lines.txt:{position} واژه‌ی ناشناخته: {term}")
            continue
        if not line.strip() or not fa.strip() or not title.strip():
            problems.append(f"media_lines.txt:{position} متن/ترجمه/عنوان خالی: {term}")
            continue
        if (word["id"], line) in seen:
            problems.append(f"media_lines.txt:{position} دیالوگ تکراری برای {term}")
            continue
        seen.add((word["id"], line))
        item = {"line": line, "fa": fa, "title": title}
        if len(row) > 4 and row[4]:
            item["year"] = int(row[4])
        if len(row) > 5 and row[5]:
            item["who"] = row[5]
        word.setdefault("media", []).append(item)
        attached += 1
    return attached, problems


# -------------------------------------------------------------------- بسته‌ها

def build_packs(words: list[dict]) -> list[dict]:
    rows = read_lines(os.path.join(CONTENT_DIR, "packs.txt"))
    index = {word["term"].lower(): word["id"] for word in words}
    packs = []
    for position, row in enumerate(rows):
        if len(row) < 5:
            continue
        pack_id, title, description, emoji = row[0], row[1], row[2], row[3]
        terms = split_multi(row[4])
        word_ids = [index[term.lower()] for term in terms if term.lower() in index]
        if len(word_ids) < 4:
            print(f"  ! بسته‌ی «{title}» فقط {len(word_ids)} واژه دارد؛ حذف شد")
            continue
        pack = OrderedDict()
        pack["id"] = pack_id
        pack["title"] = title
        pack["desc"] = description
        pack["emoji"] = emoji
        pack["seed"] = position
        pack["words"] = word_ids
        if len(row) > 5 and row[5]:
            pack["level"] = row[5].lower()
        if len(row) > 6 and row[6] in ("1", "premium", "vip"):
            pack["premium"] = True
        packs.append(pack)
    return packs


# -------------------------------------------------------------------- خروجی

def main() -> int:
    print("ساخت بسته‌ی محتوا…")
    cmu = _load_cmudict()
    frequency = _load_frequency()
    previous_ipa, previous_ranks = load_previous()
    topics, topic_problems = load_topics()
    extras, extra_problems = load_extra_collocations()
    # رتبه‌ی کاربرد: عدد تازه، و اگر پیکره در دسترس نبود همان عدد قبلی.
    ranks = dict(previous_ranks)
    ranks.update(frequency)
    words, warnings = build_words(cmu, ranks, topics, previous_ipa, extras)
    media_count, media_problems = attach_media(words)
    packs = build_packs(words)

    os.makedirs(OUT_DIR, exist_ok=True)
    by_level: dict[str, list[dict]] = {level: [] for level in LEVELS}
    for word in words:
        by_level[word["level"]].append(word)

    for level, items in by_level.items():
        payload = OrderedDict()
        payload["level"] = level
        payload["count"] = len(items)
        payload["words"] = items
        path = os.path.join(OUT_DIR, f"words_{level}.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
        size = os.path.getsize(path) / 1024
        print(f"  ✓ {os.path.basename(path)} — {len(items)} واژه ({size:.0f}KB)")

    with open(os.path.join(OUT_DIR, "packs.json"), "w", encoding="utf-8") as handle:
        json.dump({"packs": packs}, handle, ensure_ascii=False, separators=(",", ":"))
    print(f"  ✓ packs.json — {len(packs)} بسته")

    pos_counter = Counter(word["pos"] for word in words)
    manifest = OrderedDict()
    manifest["version"] = "1.0.0"
    manifest["generatedFrom"] = "tools/content/*.txt"
    manifest["totalWords"] = len(words)
    manifest["levels"] = {level: len(items) for level, items in by_level.items()}
    manifest["mediaLines"] = media_count
    manifest["packs"] = len(packs)
    manifest["byPartOfSpeech"] = dict(pos_counter.most_common())
    topic_counter = Counter(
        tag for word in words for tag in word.get("topics", [])
    )
    manifest["topicTags"] = dict(topic_counter.most_common())
    manifest["withForms"] = sum(1 for word in words if word.get("forms"))
    manifest["withCollocations"] = sum(
        1 for word in words if len(word.get("col", [])) >= 2
    )
    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
    print("  ✓ manifest.json")

    problems = list(topic_problems) + list(extra_problems) + list(media_problems)
    if warnings:
        print(f"\n{len(warnings)} هشدار:")
        for item in warnings[:40]:
            print("   -", item)
    if problems:
        print(f"\n{len(problems)} ایراد در داده‌های ورودی:")
        for item in problems[:40]:
            print("   -", item)

    tagged = sum(1 for word in words if word.get("topics"))
    forms = sum(1 for word in words if word.get("forms"))
    rich = sum(1 for word in words if len(word.get("col", [])) >= 2)
    print(
        f"\nجمع: {len(words)} واژه، {media_count} جمله‌ی ماندگار، {len(packs)} بسته،"
        f" {tagged} واژه برچسب‌دار، {forms} واژه با شکل‌های صرفی،"
        f" {rich} واژه با دو کالوکیشن یا بیشتر"
    )
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
