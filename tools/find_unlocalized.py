#!/usr/bin/env python3
# 找出 sources 下未适配的疑似 UI 英文,并按目录分组输出清单。
# 用法: python3 tools/find_unlocalized.py [sources目录] [输出文件]
# 默认: 扫 sources/,输出 /tmp/unlocalized_report.txt
#
# 过滤规则(与 localization-adaptation-rules 记忆一致):
#   - 排除注释行、日志/断言宏行(RLog/DLog/NSLog/PtyLog/XLog/CrashLog/
#     ITAssert*/it_assert/DebugLog/AccLog/print/precondition/fatalError 等)
#   - 排除已适配行(NSLocalizedString/String(localized))
#   - 排除 NSString 常量声明行
#   - 仅保留"像 UI 英文"的字面量:含空格、含小写字母、非路径/URL/标识符
#   - 排除已出现在任意 *.strings 中作为键的串(已适配/已翻译)
# 输出: 按目录分节,每条为 `文件:行号  串内容`,并按候选数排序。
import re
import os
import glob
import sys

LOG = re.compile(
    r'\b(RLog|DLog|NSLog|PtyLog|XLog|CrashLog|ITAssertWithMessage|ITBetaAssert|'
    r'it_assert|it_fatalError|assert|NSAssert|preconditionFailure|DebugLog|AccLog|'
    r'ITDebug|precondition|print\(|SetPinnedDebugLogMessage|fatalError)\s*[\(\[]')


def ui_like(lit):
    t = lit.strip()
    if len(t) < 4:
        return False
    if ' ' not in t and '\n' not in t:
        return False
    if not re.search(r'[a-z]', t):
        return False
    if t.startswith(('/', 'http', 'com.', 'kPTY', 'NS', 'UI')):
        return False
    if re.match(r'^[A-Za-z0-9_%@.\-]+$', t.replace(' ', '')) and re.match(r'^[a-z]', t):
        return False
    return True


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else 'sources'
    out_path = sys.argv[2] if len(sys.argv) > 2 else '/tmp/unlocalized_report.txt'
    os.chdir(src)

    strings_keys = set()
    for p in glob.glob('**/*.lproj/*.strings', recursive=True):
        for line in open(p, encoding='utf-8', errors='replace'):
            m = re.match(r'^"((?:[^"\\]|\\.)*)"\s*=', line)
            if m:
                strings_keys.add(m.group(1).replace('\\n', '\n').replace('\\"', '"'))

    results = {}
    files = (glob.glob('**/*.m', recursive=True) + glob.glob('**/*.swift', recursive=True))
    for f in files:
        if 'iTermTests' in f or '/tests/' in f:
            continue
        try:
            lines = open(f, encoding='utf-8', errors='replace').readlines()
        except OSError:
            continue
        d = os.path.dirname(f) or '.'
        objc = f.endswith('.m')
        for i, line in enumerate(lines, 1):
            s = line.strip()
            if '"' not in line:
                continue
            if s.startswith('//') or s.startswith('*') or s.startswith('/*'):
                continue
            if 'NSLocalizedString' in line or 'String(localized' in line:
                continue
            if LOG.search(line):
                continue
            if re.search(r'(NSString\s*(\*const|\*)\s*\w+|static\s+NSString)', line):
                continue
            pat = r'@"((?:[^"\\]|\\.)*)"' if objc else r'"([^"\n\\](?:[^"\n\\]|\\.)*)"'
            lits = re.findall(pat, line)
            hits = [l.strip() for l in lits if ui_like(l) and l.strip() not in strings_keys]
            if hits:
                results.setdefault(d, []).append((f, i, hits[0][:90]))

    with open(out_path, 'w', encoding='utf-8') as out:
        for d in sorted(results, key=lambda x: -len(results[x])):
            out.write(f"===== {d} ({len(results[d])}) =====\n")
            for f, i, t in results[d]:
                out.write(f"{f}:{i}: {t}\n")
            out.write("\n")
        print(f"TOTAL {sum(len(v) for v in results.values())} 条,目录 {len(results)} 个 -> {out_path}")
        for d in sorted(results, key=lambda x: -len(results[x]))[:15]:
            print(f"{len(results[d]):5d}  {d}")


if __name__ == '__main__':
    main()
