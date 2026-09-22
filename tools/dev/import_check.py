#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""بررسی ایستا: هر نام بزرگ (نوع/کلاس) در فایل باید از ایمپورت‌ها یا خود فایل دیده شود.

این ابزار برای محیط‌هایی است که Flutter SDK در آن‌ها نصب نیست و
«flutter analyze» قابل اجرا نیست. جای تحلیل‌گر را نمی‌گیرد؛ شبکه‌ی
ایمنی سریع است.

اجرا (از ریشه‌ی مخزن):
    python3 tools/dev/import_check.py .
"""
import os
import re
import sys

import os as _os

ROOT = sys.argv[1] if len(sys.argv) > 1 else _os.path.dirname(
    _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))))

CORE = set('''Object String int double num bool List Map Set Iterable Future Stream Duration DateTime
RegExp Exception Error ArgumentError StateError FormatException UnsupportedError State UnmodifiableListView
Comparable Iterator Null Function Symbol Type Record Enum BigInt Uri StringBuffer Pattern Match
Uint8List ByteData Int8List Float64List TypeError NoSuchMethodError StatefulWidget StatelessWidget Widget
BuildContext Key ValueKey GlobalKey UniqueKey SizedBox Column Row Container Padding Center Expanded Flex
Text TextStyle Icon Icons Colors Color Offset Size Rect EdgeInsets EdgeInsetsGeometry Alignment BoxDecoration
BoxConstraints BorderRadius Border BorderSide Gradient LinearGradient RadialGradient MaterialApp Scaffold
AppBar Theme ThemeData ColorScheme TextTheme MediaQuery Navigator Route MaterialPageRoute PageRouteBuilder
RouteSettings WidgetBuilder TransitionBuilder Curve Curves FadeTransition SlideTransition ScaleTransition
AnimatedBuilder Tween AnimationController Duration TickerProviderStateMixin SingleTickerProviderStateMixin
CustomPainter Canvas Paint PaintingStyle Path PathMetric RRects RRect StrokeCap StrokeJoin BlendMode
Brightness CircularProgressIndicator LinearProgressIndicator
ScrollController ScrollPhysics ListView SingleChildScrollView CustomScrollView SliverList SliverGrid
GridView Wrap Stack Positioned GestureDetector InkWell Ink ClipRRect ClipOval Opacity Visibility
AnimatedContainer AnimatedOpacity AnimatedSwitcher Hero FractionallySizedBox AspectRatio Spacer
Image AssetImage NetworkImage IconButton TextButton ElevatedButton OutlinedButton FilledButton
TextField TextEditingController TextInputType FocusNode FocusScope InputDecoration Form FormState
SnackBar SnackBarAction Tooltip Drawer BottomNavigationBar NavigationBar TabBar TabBarView TabController
RefreshIndicator PopupMenuButton PopupMenuItem MenuAnchor CircleAvatar Divider VerticalDivider Chip
Switch Slider Radio RadioListTile CheckboxListTile SwitchListTile ListTile Card DecoratedBox
SafeArea SystemUiOverlayStyle HapticFeedback Clipboard SystemChrome FilteringTextInputFormatter
TextInputFormatter LengthLimitingTextInputFormatter MethodChannel rootBundle FontFeature Locale
Directionality TextDirection TextAlign TextOverflow FontWeight FontStyle TextDecoration TextDecorationStyle
BoxShadow ColorFilter ImageFilter PageTransitionsTheme PageTransitionsBuilder MaterialPageRouteBuilder
Ticker FutureBuilder StreamBuilder ValueListenableBuilder AnimatedWidget Listenable ValueNotifier ValueListenable
ChangeNotifier InheritedWidget InheritedNotifier InheritedModel StateSetter Orientation Axis MainAxisAlignment
CrossAxisAlignment MainAxisSize WrapAlignment WrapCrossAlignment VerticalDirection TextBaseline TextHeightBehavior
BorderRadiusGeometry RoundedRectangleBorder ShapeBorder BoxShape Clip ColorFiltered BackdropFilter
Animation AnimationStatus ReverseAnimation ProxyAnimation Semantics SemanticsNode SliverAppBar
Dismissible ReorderableListView Timeline TileMode ImageProvider FileImage MemoryImage
Timer Stopwatch Completer Zone StreamSubscription StreamController Sink EventSink
jsonEncode jsonDecode utf8 json ascii base64 LineSplitter
File Directory Platform SocketException Process HttpClient
Locale JsonEncoder JsonDecoder
TestWidgetsFlutterBinding TestDefaultBinaryMessengerBinding WidgetTester Finder KeyFinder
expect test group setUp setUpAll tearDown tearDownAll addTearDown RegExp
pumpWidget pumpAndSettle pump matchesGoldenFile TestGesture
'''.split())

SKIP_IMPORTS = {'dart:core', 'dart:async', 'dart:math', 'dart:ui', 'dart:typed_data',
                'dart:convert', 'dart:io', 'dart:collection', 'dart:developer'}


def strip(src):
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


DECL = re.compile(r'\b(?:class|enum|mixin|extension|typedef|abstract\s+class)\s+([A-Z]\w*)')
TOP = re.compile(r'^(?:[\w<>,\?\[\]\. ]+\s+)?([A-Z]\w*)\s*\(', re.M)


def decls_of(src):
    code = strip(src)
    names = set(DECL.findall(code))
    names.update(TOP.findall(code))
    return names


def main():
    decl_cache = {}
    problems = []
    for base, _d, names in os.walk(ROOT):
        if '.git' in base or 'build' in base.split(os.sep):
            continue
        for name in sorted(names):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(base, name)
            rel = os.path.relpath(path, ROOT)
            if rel.startswith('lib/'):
                continue
            with open(path, encoding='utf-8') as handle:
                src = handle.read()
            code = strip(src)
            imports = re.findall(r"^import\s+'([^']+)'", src, re.M)
            visible = set(CORE) | decls_of(src)
            for uri in imports:
                if uri in SKIP_IMPORTS or uri.startswith('dart:'):
                    continue
                if uri.startswith('package:wordagent/'):
                    target = os.path.join(ROOT, 'lib', uri[len('package:wordagent/'):])
                elif uri.startswith('package:'):
                    # third-party: whitelist by known package symbols
                    continue
                else:
                    target = os.path.normpath(os.path.join(os.path.dirname(path), uri))
                if target not in decl_cache:
                    decl_cache[target] = decls_of(open(target, encoding='utf-8').read()) \
                        if os.path.exists(target) else set()
                visible |= decl_cache[target]
            used = set()
            for match in re.finditer(r'(?<![\w.$])([A-Z]\w*)', code):
                used.add(match.group(1))
            for token in sorted(used - visible):
                line = code.count('\n', 0, code.find(token)) + 1
                problems.append(f'{rel}:{line}: {token} (not visible via imports)')
    for line in problems:
        print(line)
    print(f'problems: {len(problems)}')


if __name__ == '__main__':
    main()
