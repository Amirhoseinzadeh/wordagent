#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""بررسی ایستا: آرگومان‌های نام‌دار/جایگاهی هر فراخوانی با اعلان سازنده یا تابع بخواند.

این ابزار برای محیط‌هایی است که Flutter SDK در آن‌ها نصب نیست و
«flutter analyze» قابل اجرا نیست. جای تحلیل‌گر را نمی‌گیرد؛ شبکه‌ی
ایمنی سریع است.

اجرا (از ریشه‌ی مخزن):
    python3 tools/dev/arg_check.py .
"""
import os
import re
import sys

import os as _os

ROOT = sys.argv[1] if len(sys.argv) > 1 else _os.path.dirname(
    _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))))

CLASS_RE = re.compile(r'\b(?:abstract\s+|final\s+|sealed\s+|base\s+)*class\s+([A-Z]\w*)')
TOP_FN_RE = re.compile(r'^(?:[\w<>,\?\[\]\. ]+\s+)?([a-z_]\w*)\s*\(', re.M)


def strip_strings(src):
    out, i, n = [], 0, len(src)
    while i < n:
        if src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
        elif src.startswith('/*', i):
            j = src.find('*/', i + 2)
            i = n if j < 0 else j + 2
        elif src[i] in '\'"':
            c = src[i]
            if src.startswith(c * 3, i):
                j = src.find(c * 3, i + 3)
                i = n if j < 0 else j + 3
            else:
                j = i + 1
                while j < n:
                    if src[j] == '\\':
                        j += 2
                        continue
                    if src[j] == c:
                        break
                    j += 1
                i = n if j >= n else j + 1
            out.append('""')
        else:
            out.append(src[i])
            i += 1
    return ''.join(out)


def balanced(code, open_index):
    depth, i, n = 0, open_index, len(code)
    while i < n:
        if code[i] == '(':
            depth += 1
        elif code[i] == ')':
            depth -= 1
            if depth == 0:
                return code[open_index + 1:i], i
        i += 1
    return code[open_index + 1:], n


def split_args(text):
    args, depth, angle, cur, i, n = [], 0, 0, [], 0, len(text)
    while i < n:
        c = text[i]
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == '<' and i + 1 < n and (text[i + 1].isalpha() or text[i + 1] in '_?'):
            angle += 1
        elif c == '>' and angle > 0:
            angle -= 1
        elif c == ',' and depth == 0 and angle == 0:
            args.append(''.join(cur))
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    if ''.join(cur).strip():
        args.append(''.join(cur))
    return args


def collect_param_names(text):
    """نام پارامترهای یک امضا؛ برای تشخیص فراخوانی متغیرهای تابعی."""
    names = set()
    for part in split_args(text.replace('{', ',').replace('}', ',')
                               .replace('[', ',').replace(']', ',')):
        part = part.strip()
        if not part:
            continue
        part = re.sub(r'^required\\s+', '', part)
        part = part.split('=')[0].strip()
        tokens = part.split()
        if len(tokens) >= 2:
            names.add(tokens[-1].split('.')[-1])
        elif tokens and re.match(r'^[a-zA-Z_]\\w*$', tokens[0]) is None:
            pass
    return names


def parse_params(text):
    """-> (positional_count, required_positional, named, required_named)"""
    named, required_named = set(), set()
    positional_text = text
    if '{' in text:
        before, after = text.split('{', 1)
        brace_body = after
        # find matching close brace of the named block
        depth = 1
        for idx, ch in enumerate(after):
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    brace_body = after[:idx]
                    break
        positional_text = before
        for part in split_args(brace_body):
            part = part.strip()
            if not part:
                continue
            is_required = part.startswith('required ')
            part = re.sub(r'^required\s+', '', part)
            part = part.split('=')[0].strip()
            name = part.split()[-1].lstrip('@').split('.')[-1] if part.split() else ''
            if not re.match(r'^[a-zA-Z_]\w*$', name or ''):
                continue
            named.add(name)
            if is_required:
                required_named.add(name)
    # optional positional block [ ... ]
    optional_positional = 0
    if '[' in positional_text:
        head, tail = positional_text.split('[', 1)
        optional_positional = len([a for a in split_args(tail.replace(']', '')) if a.strip()])
        positional_text = head
    positional = [a for a in split_args(positional_text) if a.strip()]
    return len(positional), optional_positional, named, required_named


def brace_body(code, start):
    depth, i, n = 0, start, len(code)
    while i < n:
        if code[i] == '{':
            depth += 1
        elif code[i] == '}':
            depth -= 1
            if depth == 0:
                return code[start + 1:i]
        i += 1
    return code[start + 1:]


CLASS_RE = re.compile(
    r'\b(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+)*class\s+([A-Z]\w*)'
)
DECL_WITH_TYPE_RE = re.compile(
    r'(?:^|\n)[ \t]*(?:@\w+(?:\([^)]*\))?[ \t]*)*'
    r'(?:static[ \t]+|external[ \t]+)*'
    r'(?:Future(?:<[^<>]*>)?|void|int|bool|double|num|String|dynamic|'
    r'[A-Z][\w<>, \?\[\]\.]*|[a-z]\w*\??)[ \t]+'
    r'([a-z_]\w*)[ \t]*(?:<[^<>]*>)?[ \t]*\(',
)


def collect():
    """name -> list of (positional, optional_positional, named, required_named)"""
    decls = {}
    decl_spans = {}
    class_names = set()
    param_names = set()
    sources = {}
    roots = [os.path.join(ROOT, 'lib')]
    test_dir = os.path.join(ROOT, 'test')
    if os.path.isdir(test_dir):
        roots.append(test_dir)
    for base, _dirs, names in [(b, d, n) for root in roots for b, d, n in os.walk(root)]:
        for name in sorted(names):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(base, name)
            rel = os.path.relpath(path, ROOT)
            with open(path, encoding='utf-8') as handle:
                src = handle.read()
            code = strip_strings(src)
            sources[rel] = code
            spans = decl_spans.setdefault(rel, set())
            for match in DECL_WITH_TYPE_RE.finditer(code):
                params, _end = balanced(code, match.end() - 1)
                decls.setdefault(match.group(1), []).append(parse_params(params))
                spans.add(match.end() - 1)
                param_names.update(collect_param_names(params))
            # constructors inside class bodies
            for cls_match in CLASS_RE.finditer(code):
                cls = cls_match.group(1)
                class_names.add(cls)
                brace = code.find('{', cls_match.end())
                if brace < 0:
                    continue
                body = brace_body(code, brace)
                offset = brace + 1
                ctor_re = re.compile(
                    r'(?:^|\n)[ \t]*(?:@\w+(?:\([^)]*\))?[ \t]*)*'
                    r'(?:const[ \t]+|factory[ \t]+|external[ \t]+)*'
                    + re.escape(cls) + r'(?:\.(\w+))?[ \t]*\('
                )
                for ctor in ctor_re.finditer(body):
                    params, _end = balanced(body, ctor.end() - 1)
                    key = ctor.group(1) or cls
                    decls.setdefault(key, []).append(parse_params(params))
                    spans.add(offset + ctor.end() - 1)
                    param_names.update(collect_param_names(params))
    return decls, sources, decl_spans, class_names, param_names


def main():
    decls, sources, decl_spans, class_names, param_names = collect()
    problems = []
    call_re = re.compile(r'(?<![\w.$])([A-Za-z_]\w*)(?:\.([a-zA-Z_]\w*))?\s*\(')
    for rel, code in sorted(sources.items()):
        spans = decl_spans.get(rel, set())
        for call in call_re.finditer(code):
            if call.end() - 1 in spans:
                continue
            base, member = call.group(1), call.group(2)
            if base in ('if', 'for', 'while', 'switch', 'catch', 'assert', 'return', 'await'):
                continue
            candidates = []
            if member:
                # `Type.member(...)` is only checked when `Type` is a class of
                # this repo (otherwise it is a Flutter/dart: API) and the
                # member itself is declared here too.
                if base[:1].isupper() and base in class_names:
                    candidates.extend(decls.get(member, []))
                    if not candidates:
                        continue
                else:
                    continue
            else:
                # نامی که در جایی پارامتر تابعی است ممکن است متغیر باشد.
                if base in param_names:
                    continue
                candidates.extend(decls.get(base, []))
            if not candidates:
                continue
            args_text, _end = balanced(code, call.end() - 1)
            seen, pos_count = [], 0
            for arg in split_args(args_text):
                stripped = arg.strip()
                if not stripped:
                    continue
                named_match = re.match(r'^([a-zA-Z_]\w*)\s*:', stripped)
                if named_match:
                    seen.append(named_match.group(1))
                else:
                    pos_count += 1
            ok = False
            for positional, optional_positional, named, required_named in candidates:
                if pos_count > positional + optional_positional:
                    continue
                if any(arg not in named for arg in seen if arg != 'key'):
                    continue
                if any(need not in seen for need in required_named if need != 'key'):
                    continue
                ok = True
                break
            if not ok:
                line = code.count('\n', 0, call.start()) + 1
                problems.append(
                    f'{rel}:{line}: {base}{"." + member if member else ""}'
                    f'(named={seen}, pos={pos_count}) vs {len(candidates)} declaration(s)'
                )
    for line in sorted(problems, key=lambda p: (p.split(':')[0], int(p.split(':')[1]))):
        print(line)
    print(f'callable names known: {len(decls)}  problems: {len(problems)}')


if __name__ == '__main__':
    main()
