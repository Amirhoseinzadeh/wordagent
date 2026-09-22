/**
 * dartcheck — بررسی ایستا و آفلاین کد Dart پروژه (بدون نیاز به Flutter SDK).
 *
 * چون در محیط ساخت این پروژه، Flutter/Dart SDK در دسترس نیست، این ابزار با
 * گرامر درخت‌نحو (tree-sitter-dart) این چهار بررسی را انجام می‌دهد:
 *   1. خطای نگارشی (syntax error) در هر فایل
 *   2. اعلان‌های تکراری در یک فایل (کلاس/تابع/enum با نام یکسان)
 *   3. import های نسبی که به فایل موجود اشاره نمی‌کنند
 *   4. آرگومان‌های نام‌دار نادرست در فراخوانی سازنده‌های داخل پروژه
 *
 * نصب پیش‌نیاز (یک‌بار):
 *   cd tools/dev && npm install web-tree-sitter tree-sitter-wasms
 *
 * اجرا:
 *   node tools/dev/dartcheck.mjs [مسیرریشه]
 */
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { Parser, Language } = require('web-tree-sitter');

const ROOT = path.resolve(process.argv[2] ?? path.join(import.meta.dirname, '..', '..'));
const SKIP_DIRS = new Set(['.git', 'build', 'node_modules', '.dart_tool', 'assets']);

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      walk(path.join(dir, entry.name), out);
    } else if (entry.name.endsWith('.dart')) {
      out.push(path.join(dir, entry.name));
    }
  }
  return out;
}

await Parser.init();
const wasm = require.resolve('tree-sitter-wasms/out/tree-sitter-dart.wasm');
await Parser.init();
const language = await Language.load(wasm);
const parser = new Parser();
parser.setLanguage(language);

const files = walk(ROOT).sort();
const problems = [];
const declarations = new Map(); // class name -> { file, params:Set|null, required:Set, allNamed:bool }
const enums = new Map(); // enum name -> Set of member names
const extensionMembers = new Set(); // نام getter/متدهای extension ها (سراسری)
const classStatics = new Map(); // class name -> Set of static member names
const stringKeys = new Set(); // کلیدهای کلاس S
const trees = new Map();

function text(node) {
  return node.text;
}

/**
 * پارامترهای یک سازنده را از متن امضای آن بیرون می‌کشد.
 *
 * گرامر tree-sitter-dart گره‌ی «required» را در درخت نگه نمی‌دارد، پس این‌جا
 * متن خام امضا تجزیه می‌شود: `const A({required this.x, String? y = 'z'})`.
 */
function constructorParams(ctorText) {
  const open = ctorText.indexOf('(');
  if (open < 0) return null;
  let depth = 0;
  let close = -1;
  for (let index = open; index < ctorText.length; index += 1) {
    const char = ctorText[index];
    if (char === '(') depth += 1;
    else if (char === ')') {
      depth -= 1;
      if (depth === 0) {
        close = index;
        break;
      }
    }
  }
  if (close < 0) return null;
  const inner = ctorText.slice(open + 1, close);

  const params = new Set();
  const required = new Set();
  let allNamed = true;
  let found = false;
  let braceDepth = 0;
  let squareDepth = 0;
  let parenDepth = 0;
  let angleDepth = 0;
  let item = '';
  let itemNamed = false;

  const flush = () => {
    const raw = item.trim();
    item = '';
    if (!raw) return;
    found = true;
    const needsValue = raw.startsWith('{') && raw.endsWith('}');
    const body = needsValue ? raw.slice(1, -1).trim() : raw;
    const parts = body.split(',');
    for (const part of parts) {
      const cleaned = part.trim();
      if (!cleaned) continue;
      if (!itemNamed) allNamed = false;
      if (/^required\b/.test(cleaned)) {
        const name = lastNameIdentifier(cleaned);
        if (name) required.add(name);
      }
      const name = lastNameIdentifier(cleaned);
      if (name) params.add(name);
    }
    itemNamed = false;
  };

  const chars = [...inner];
  for (let index = 0; index < chars.length; index += 1) {
    const char = chars[index];
    const prev = index > 0 ? chars[index - 1] : '';
    const next = index + 1 < chars.length ? chars[index + 1] : '';
    if (char === '<' && /[A-Za-z0-9_$]/.test(prev) && /[A-Za-z0-9_$]/.test(next)) {
      angleDepth += 1;
      item += char;
      continue;
    }
    if (char === '>' && angleDepth > 0) {
      angleDepth -= 1;
      item += char;
      continue;
    }
    if (char === '{') {
      braceDepth += 1;
      if (braceDepth === 1) itemNamed = true;
    } else if (char === '}') braceDepth -= 1;
    else if (char === '[') squareDepth += 1;
    else if (char === ']') squareDepth -= 1;
    else if (char === '(') parenDepth += 1;
    else if (char === ')') parenDepth -= 1;

    if (char === ',' && braceDepth === 0 && squareDepth === 0 && parenDepth === 0 && angleDepth === 0) {
      flush();
      continue;
    }
    item += char;
  }
  flush();

  if (!found) return null;
  return { params, required, allNamed };
}

/** آخرین شناسه‌ی یک پارامتر (نام آن) را از متن بیرون می‌کشد. */
function lastNameIdentifier(rawText) {
  const withoutRequired = rawText.replace(/^required\s+/, '');
  const beforeDefault = withoutRequired.split('=')[0];
  const cleaned = beforeDefault.replace(/{|}/g, ' ').trim();
  const match = /([A-Za-z_$][\w$]*)\s*$/.exec(cleaned);
  if (!match) return null;
  // نام پارامتر هرگز با حرف بزرگ شروع نمی‌شود؛ «String» در «Map<String» نام نیست.
  if (!/^[a-z_$]/.test(match[1])) return null;
  return match[1];
}

/** نام و پارامترهای سازنده‌های کلاس‌های داخل پروژه را جمع می‌کند. */
function collectDeclarations(file, tree) {
  const stack = [tree.rootNode];
  while (stack.length) {
    const node = stack.pop();
    if (node.type === 'enum_declaration') {
      const nameNode = node.namedChildren.find((c) => c.type === 'identifier');
      if (nameNode) {
        const members = new Set();
        for (const inner of descend(node)) {
          if (inner.type === 'enum_constant' || inner.type === 'identifier' ||
              inner.type === 'getter_signature' || inner.type === 'method_signature' ||
              inner.type === 'function_signature') {
            if (inner.type === 'enum_constant') {
              const id = inner.namedChildren.find((c) => c.type === 'identifier');
              if (id) members.add(text(id));
            } else if (inner.type === 'identifier' && inner.parent &&
                       ['getter_signature', 'method_signature', 'function_signature'].includes(inner.parent.type)) {
              members.add(text(inner));
            }
          }
        }
        enums.set(text(nameNode), members);
      }
    }
    if (node.type === 'extension_declaration') {
      for (const inner of descend(node)) {
        if (['getter_signature', 'method_signature', 'function_signature'].includes(inner.type)) {
          const id = inner.namedChildren.find((c) => c.type === 'identifier');
          if (id) extensionMembers.add(text(id));
        }
        if (inner.type === 'field_declaration') {
          const id = inner.namedChildren.find((c) => c.type === 'identifier');
          if (id) extensionMembers.add(text(id));
        }
      }
    }
    const isType = ['class_definition', 'enum_declaration', 'mixin_declaration', 'extension_declaration'].includes(node.type);
    if (isType) {
      const nameNode = node.namedChildren.find((c) => c.type === 'identifier');
      const name = nameNode ? text(nameNode) : null;
      if (name) {
        const info = { file, params: null, required: new Set(), allNamed: false };
        const statics = new Set();
        const body = node.namedChildren.find((c) =>
          ['class_body', 'enum_body', 'extension_body'].includes(c.type));
        if (body) {
          for (const inner of descend(body)) {
            if (inner.type === 'field_declaration') {
              const id = inner.namedChildren.find((c) => c.type === 'identifier');
              if (id) statics.add(text(id));
            }
            if (inner.type === 'getter_signature' || inner.type === 'method_signature') {
              const id = inner.namedChildren.find((c) => c.type === 'identifier');
              if (id) statics.add(text(id));
            }
            if (inner.type !== 'constant_constructor_signature' && inner.type !== 'constructor_signature') continue;
            if (info.params) continue;
            const parsed = constructorParams(inner.text);
            if (parsed) {
              info.params = parsed.params;
              info.required = parsed.required;
              info.allNamed = parsed.allNamed;
            }
          }
        }
        if (name === 'S') {
          for (const inner of descend(node)) {
            const match = /static\s+const\s+([A-Za-z_$][\w$]*)/.exec(inner.text ?? '');
            if (match) stringKeys.add(match[1]);
          }
        }
        if (!classStatics.has(name)) classStatics.set(name, statics);
        if (!declarations.has(name)) declarations.set(name, info);
      }
    }
    stack.push(...node.namedChildren);
  }
}

function* descend(node) {
  yield node;
  for (const child of node.namedChildren) yield* descend(child);
}

function checkSyntaxAndDeclarations(file, tree) {
  const errors = [];
  for (const node of descend(tree.rootNode)) {
    if (node.type === 'ERROR' || node.isMissing) {
      errors.push(node);
    }
  }
  if (errors.length) {
    const first = errors[0];
    problems.push(`SYNTAX ${path.relative(ROOT, file)}:${first.startPosition.row + 1} «${first.text.slice(0, 60)}»`);
  }

  const seen = new Map();
  for (const node of tree.rootNode.namedChildren) {
    const nameNode = node.childForFieldName?.('name') ??
      node.namedChildren?.find?.((c) => c.type === 'identifier');
    if (!nameNode || nameNode.type !== 'identifier') continue;
    if (!['class_definition', 'enum_declaration', 'mixin_declaration', 'function_declaration',
          'extension_declaration', 'type_alias'].includes(node.type)) continue;
    const name = text(nameNode);
    if (seen.has(name)) {
      problems.push(`DUP ${path.relative(ROOT, file)}:${nameNode.startPosition.row + 1} «${name}»`);
    }
    seen.set(name, true);
  }
}

function checkImports(file, tree) {
  const dir = path.dirname(file);
  for (const node of tree.rootNode.namedChildren) {
    if (node.type !== 'import_or_export') continue;
    const match = /^import\s+'([^']+)'/.exec(node.text);
    if (!match) continue;
    const target = match[1];
    if (target.startsWith('dart:')) continue;
    if (!target.startsWith('.') && !target.startsWith('package:')) continue;
    let resolved;
    if (target.startsWith('package:')) {
      // فقط بسته‌های خودمان قابل بررسی‌اند.
      const [, rest] = target.split('package:');
      const [pkg, ...segments] = rest.split('/');
      if (pkg !== 'wordagent') continue;
      resolved = path.join(ROOT, 'lib', ...segments);
    } else {
      resolved = path.resolve(dir, target);
    }
    if (!fs.existsSync(resolved) && !fs.existsSync(`${resolved}.dart`)) {
      problems.push(`IMPORT ${path.relative(ROOT, file)}:${node.startPosition.row + 1} «${target}» پیدا نشد`);
    }
  }
}

function checkNamedArguments(file, tree) {
  const rel = (node) => node;
  for (const node of descend(tree.rootNode)) {
    if (node.type !== 'selector' && node.type !== 'object_expression' &&
        node.type !== 'const_object_expression') continue;
    if (node.type === 'selector' && node.previousSibling && node.previousSibling.type === 'selector') {
      continue; // فراخوانی زنجیره‌ای (a.b().c()) سازنده نیست
    }
    const call = node.type === 'selector'
      ? node.namedChildren.find((c) => c.type === 'argument_part')
      : node;
    if (!call) continue;
    const args = descend(call).find?.((c) => c.type === 'arguments');
    if (!args) continue;
    // نام سازنده: شناسه‌ی پیش از پرانتز
    let name = null;
    if (node.type === 'selector') {
      const prev = node.previousSibling;
      if (prev && prev.type === 'identifier') name = text(prev);
    } else {
      const head = node.namedChildren.find((c) => c.type === 'identifier' || c.type === 'type_identifier');
      if (head) name = text(head);
    }
    if (!name) continue;
    const info = declarations.get(name);
    if (!info || !info.params || !info.allNamed) continue;

    const provided = new Set();
    for (const arg of args.namedChildren) {
      if (arg.type !== 'named_argument') continue;
      const label = arg.childForFieldName?.('label') ??
        arg.namedChildren.find((c) => c.type === 'label');
      const labelText = label ? text(label).replace(/:$/, '').trim() : '';
      if (!labelText) continue;
      provided.add(labelText);
      if (!info.params.has(labelText)) {
        problems.push(`ARG ${path.relative(ROOT, file)}:${arg.startPosition.row + 1} «${name}» پارامتر «${labelText}» را ندارد`);
      }
    }
    for (const required of info.required) {
      if (!provided.has(required) && !/\[/.test(args.text.split(':')[0] ?? '')) {
        // فقط وقتی مطمئن‌ایم آرگومان‌ها کاملاً نام‌دار هستند هشدار می‌دهیم.
        const hasPositional = args.namedChildren.some((c) => c.type !== 'named_argument');
        if (!hasPositional) {
          problems.push(`ARG ${path.relative(ROOT, file)}:${args.startPosition.row + 1} «${name}» پارامتر لازم «${required}» داده نشده`);
        }
      }
    }
  }
}

/** اعضای enum/کلاس‌های داخلی و کلیدهای S را بررسی می‌کند. */
function checkMemberAccess(file, tree) {
  const builtins = new Set(['index', 'name', 'values', 'hashCode', 'toString', 'runtimeType']);
  for (const node of descend(tree.rootNode)) {
    if (node.type !== 'unconditional_assignable_selector' && node.type !== 'conditional_assignable_selector') continue;
    const memberNode = node.namedChildren.find((c) => c.type === 'identifier');
    // ساختار درخت: selector(identifier base, unconditional_assignable_selector(.member))
    const holder = node.parent;
    if (!memberNode || !holder || holder.type !== 'selector') continue;
    const base = holder.previousSibling;
    if (!base || base.type !== 'identifier') continue;
    const baseName = text(base);
    const member = text(memberNode);
    if (baseName === 'S' && stringKeys.size) {
      if (!stringKeys.has(member)) {
        problems.push(`KEY ${path.relative(ROOT, file)}:${memberNode.startPosition.row + 1} «S.${member}» در strings.dart نیست`);
      }
      continue;
    }
    const enumMembers = enums.get(baseName);
    if (enumMembers && !enumMembers.has(member) && !builtins.has(member) && !extensionMembers.has(member)) {
      problems.push(`ENUM ${path.relative(ROOT, file)}:${memberNode.startPosition.row + 1} «${baseName}.${member}» عضو ندارد`);
    }
  }
}

for (const file of files) {
  let source;
  try {
    source = fs.readFileSync(file, 'utf8');
  } catch {
    continue;
  }
  const tree = parser.parse(source);
  trees.set(file, tree);
  collectDeclarations(file, tree);
}

for (const [file, tree] of trees) {
  checkSyntaxAndDeclarations(file, tree);
  checkImports(file, tree);
  checkNamedArguments(file, tree);
  checkMemberAccess(file, tree);
}

const grouped = new Map();
for (const problem of problems) {
  const key = problem.split(' ')[0];
  grouped.set(key, (grouped.get(key) ?? 0) + 1);
}

console.log(`files=${files.length} declarations=${declarations.size}`);
for (const problem of problems.slice(0, 200)) console.log(problem);
console.log('warnings:', Object.fromEntries(grouped));
console.log(problems.length === 0 ? 'OK: بدون ایراد' : `TOTAL: ${problems.length} ایراد`);
process.exit(problems.length === 0 ? 0 : 1);
