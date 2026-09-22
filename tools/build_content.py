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


def ipa_for(term: str, cmu: dict) -> str | None:
    entry = cmu.get(term.lower())
    if not entry:
        return None
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


def build_words(cmu: dict, ranks: dict) -> tuple[list[dict], list[str]]:
    words: list[dict] = []
    warnings: list[str] = []
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
            ipa = ipa_for(term, cmu)
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
            if len(row) > 10 and row[10]:
                entry["syn"] = split_multi(row[10])
            if len(row) > 11 and row[11]:
                entry["ant"] = split_multi(row[11])
            if len(row) > 12 and row[12]:
                entry["note"] = row[12]
            if len(row) > 13 and row[13]:
                entry["emoji"] = row[13]
            if len(row) > 14 and row[14]:
                entry["topics"] = split_multi(row[14])
            if len(row) > 15 and row[15]:
                entry["forms"] = parse_forms(row[15])
            if len(row) > 16 and row[16]:
                entry["mnemonic"] = row[16]
            if len(row) > 17 and row[17] in ("1", "premium", "vip"):
                entry["premium"] = True

            image = image_for(entry["id"])
            if image:
                entry["image"] = image

            if entry["id"] in seen_ids:
                warnings.append(f"شناسه‌ی تکراری: {entry['id']}")
            seen_ids.add(entry["id"])
            words.append(entry)
    return words, warnings


# ------------------------------------------------------------------ رسانه‌ها

def attach_media(words: list[dict]) -> int:
    rows = read_lines(os.path.join(CONTENT_DIR, "media_lines.txt"))
    if not rows:
        return 0
    index = {word["term"].lower(): word for word in words}
    attached = 0
    for row in rows:
        if len(row) < 5:
            continue
        term, line, fa, title = row[0], row[1], row[2], row[3]
        word = index.get(term.lower())
        if word is None:
            continue
        item = {"line": line, "fa": fa, "title": title}
        if len(row) > 4 and row[4]:
            item["year"] = int(row[4])
        if len(row) > 5 and row[5]:
            item["who"] = row[5]
        word.setdefault("media", []).append(item)
        attached += 1
    return attached


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
    ranks = _load_frequency()
    words, warnings = build_words(cmu, ranks)
    media_count = attach_media(words)
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
    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
    print("  ✓ manifest.json")

    if warnings:
        print(f"\n{len(warnings)} هشدار:")
        for item in warnings[:40]:
            print("   -", item)
    print(f"\nجمع: {len(words)} واژه، {media_count} دیالوگ سینمایی، {len(packs)} بسته")
    return 0


if __name__ == "__main__":
    sys.exit(main())
