#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""بررسی ایستا: هر ارجاع «Type.member» باید عضو واقعی همان کلاس باشد.

این ابزار برای محیط‌هایی است که Flutter SDK در آن‌ها نصب نیست و
«flutter analyze» قابل اجرا نیست. جای تحلیل‌گر را نمی‌گیرد؛ شبکه‌ی
ایمنی سریع است.

اجرا (از ریشه‌ی مخزن):
    python3 tools/dev/member_check.py .
"""
import os
import re
import sys

import os as _os

ROOT = sys.argv[1] if len(sys.argv) > 1 else _os.path.dirname(
    _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))))
LIB = os.path.join(ROOT, 'lib')

INHERITED = {
    'toString', 'hashCode', 'runtimeType', 'noSuchMethod', 'name', 'index',
    'values', 'length', 'first', 'last', 'isEmpty', 'isNotEmpty', 'contains',
    'iterator', 'single', 'any', 'every', 'where', 'map', 'toList', 'toSet',
}

CLASS_RE = re.compile(
    r'\b(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+|mixin\s+)*'
    r'(?:class|enum|mixin)\s+([A-Z]\w*)'
)
NAMED_RE = re.compile(r'\b([a-zA-Z_]\w*)\s*(?:<[^<>]*>)?\s*[({]')
FIELD_RE = re.compile(r'\b([a-zA-Z_]\w*)\s*(?:=|;|=>)')
GETTER_RE = re.compile(r'\bget\s+([a-zA-Z_]\w*)')
TYPED_RE = re.compile(
    r'^[ \t]*[A-Za-z_][\w<>,\.\?\[\] ]*\s+([a-zA-Z_]\w*)\s*(?:=|;)', re.M
)


def strip_code(src):
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
        else:
            out.append(src[i])
            i += 1
    return ''.join(out)


def body_of(code, start):
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


def collect():
    declared, enums, sources = {}, {}, {}
    roots = [LIB] + [os.path.join(ROOT, 'test')] if os.path.isdir(os.path.join(ROOT, 'test')) else [LIB]
    for base, _dirs, names in [(b, d, n) for root in roots for b, d, n in os.walk(root)]:
        for name in sorted(names):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(base, name)
            rel = os.path.relpath(path, ROOT)
            with open(path, encoding='utf-8') as handle:
                src = handle.read()
            sources[rel] = src
            code = strip_code(src)
            for match in CLASS_RE.finditer(code):
                cls = match.group(1)
                brace = code.find('{', match.end())
                if brace < 0:
                    continue
                body = body_of(code, brace)
                members = declared.setdefault(cls, set())
                head_text = code[match.start():match.end()].strip()
                if head_text.startswith('enum'):
                    head = re.sub(r'\([^()]*\)', '', body.split(';')[0])
                    constants = set()
                    for token in re.finditer(r'(?:^|,)\s*([a-zA-Z_]\w*)', head):
                        constants.add(token.group(1))
                    enums.setdefault(cls, set()).update(constants)
                    members.update(constants)
                for token in NAMED_RE.finditer(body):
                    members.add(token.group(1))
                for token in FIELD_RE.finditer(body):
                    members.add(token.group(1))
                for token in GETTER_RE.finditer(body):
                    members.add(token.group(1))
                for token in TYPED_RE.finditer(body):
                    members.add(token.group(1))
    return declared, enums, sources


def main():
    declared, enums, sources = collect()
    problems = []
    for rel, src in sorted(sources.items()):
        code = strip_code(src)
        for match in re.finditer(r'\b([A-Z]\w*)\.([a-zA-Z_]\w*)', code):
            cls, member = match.group(1), match.group(2)
            if cls not in declared:
                continue
            if member in declared[cls] or member in INHERITED:
                continue
            line = code.count('\n', 0, match.start()) + 1
            problems.append(f'{rel}:{line}: {cls}.{member} (no such member)')
    # enum switch completeness (heuristic: a switch that names >= 2 cases of an enum)
    for rel, src in sorted(sources.items()):
        code = strip_code(src)
        for sw in re.finditer(r'\bswitch\s*\(', code):
            brace = code.find('{', sw.end())
            if brace < 0:
                continue
            body = body_of(code, brace)
            per_enum = {}
            for case in re.finditer(r'\b([A-Z]\w*)\.([a-zA-Z_]\w*)', body):
                cls, member = case.group(1), case.group(2)
                if cls in enums and member in enums[cls]:
                    per_enum.setdefault(cls, set()).add(member)
            for cls, used in per_enum.items():
                if len(used) < 2:
                    continue
                missing = sorted(enums[cls] - used)
                if missing and 'default:' not in body and 'case _' not in body:
                    line = code.count('\n', 0, sw.start()) + 1
                    problems.append(
                        f'{rel}:{line}: switch on {cls} misses {missing}'
                    )
    for line in sorted(problems, key=lambda p: (p.split(':')[0], int(p.split(':')[1]))):
        print(line)
    print(f'checked classes: {len(declared)}  problems: {len(problems)}')


if __name__ == '__main__':
    main()
