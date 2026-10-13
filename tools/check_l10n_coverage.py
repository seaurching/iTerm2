#!/usr/bin/env python3
# 穷尽式本地化覆盖校验(供逐组适配使用)。
# 用法: python3 tools/check_l10n_coverage.py <sources子目录> <strings表名>
# 例:   python3 tools/check_l10n_coverage.py sources/TerminalView TerminalView
#
# 校验内容:
#   1. 目录内全部 .m/.swift 中声明的 NSLocalizedString(FromTableInBundle) 键
#      (含 ObjC 相邻字面量拼接、Swift \u{...} 转义)是否在全部 zh 变体的
#      <表名>.strings 中有键;
#   2. 各 lproj 变体的键集合是否完全一致(防止某变体漏追加);
#   3. zh 变体中键值相同的"疑似未翻译"条目。
# 退出码: 0=通过, 1=有问题。
import re
import sys
import glob
import os
import subprocess

def unesc(s):
    out, i = [], 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            c = s[i+1]
            if c == 'n':
                out.append('\n'); i += 2; continue
            if c == 't':
                out.append('\t'); i += 2; continue
            if c == '"':
                out.append('"'); i += 2; continue
            if c == '\\':
                out.append('\\'); i += 2; continue
            if c == 'u' and i + 5 < len(s):
                try:
                    out.append(chr(int(s[i+2:i+6], 16))); i += 6; continue
                except ValueError:
                    pass
                m = re.match(r'\{([0-9a-fA-F]+)\}', s[i+2:])
                if m:  # Swift \u{XXXX}
                    out.append(chr(int(m.group(1), 16))); i += 2 + m.end(); continue
        out.append(s[i]); i += 1
    return ''.join(out)

def load_strings(path):
    d = {}
    for line in open(path, encoding='utf-8'):
        m = re.match(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', line)
        if m:
            d[unesc(m.group(1))] = unesc(m.group(2))
    return d

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    src_dir, table = sys.argv[1], sys.argv[2]
    lproj_dirs = sorted(
        d for d in glob.glob(os.path.join(src_dir, '*.lproj'))
        if os.path.exists(os.path.join(d, table + '.strings')))
    if not lproj_dirs:
        print(f"未找到 {src_dir} 下的 {table}.strings")
        return 1
    tables = {os.path.basename(d)[:-6]: load_strings(os.path.join(d, table + '.strings'))
              for d in lproj_dirs}

    # 1) 收集代码中的键(按表名过滤)
    seen = set()
    for f in sorted(glob.glob(os.path.join(src_dir, '*.m')) + glob.glob(os.path.join(src_dir, '*.swift'))):
        src = open(f, encoding='utf-8').read()
        # ObjC: NSLocalizedStringFromTableInBundle(@"key" @"cont", @"TABLE", …)
        for m in re.finditer(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)"', src):
            rest, parts = src[m.end():], [m.group(1)]
            while True:
                m2 = re.match(r'\s*@"((?:[^"\\]|\\.)*)"', rest)
                if not m2:
                    break
                parts.append(m2.group(1))
                rest = rest[m2.end():]
            tm = re.match(r'\s*,\s*@"((?:[^"\\]|\\.)*)"', rest)
            if not tm or unesc(tm.group(1)) != table:
                continue
            seen.add(unesc(''.join(parts)))
        # Swift: NSLocalizedString("key", tableName: "TABLE", …) —— 允许跨行参数
        for m in re.finditer(r'NSLocalizedString\("((?:[^"\\]|\\.)*)"', src):
            tm = re.search(r'tableName:\s*"([^"]+)"', src[m.end():m.end() + 300], re.S)
            if not tm or tm.group(1) != table:
                continue
            seen.add(unesc(m.group(1)))

    problems = []
    # 2) 覆盖检查
    for key in sorted(seen):
        for t, d in tables.items():
            if key not in d:
                problems.append(f"MISSING [{t}] {key!r}")
    # 3) 变体一致性
    base = set(next(iter(tables.values())))
    for t, d in tables.items():
        if set(d) != base:
            only_missing = sorted(base - set(d))
            problems.append(f"键集差异 [{t}]: 缺 {only_missing[:10]}")
    # 4) 疑似未翻译(简繁中键值相同且含 3 个以上连续英文字母,排除 %@ 开头的格式串)
    for t in tables:
        if not t.startswith('zh'):
            continue
        for k, v in tables[t].items():
            if k == v and re.search(r'[A-Za-z]{3}', k) and not re.match(r'^%@', k):
                problems.append(f"疑似未翻译 [{t}] {k!r}")

    for p in problems:
        print(p)
    print(f"代码键去重 {len(seen)} 个,变体 {len(tables)} 个: "
          + ("通过 ✓" if not problems else f"{len(problems)} 个问题 ✗"))
    return 0 if not problems else 1

if __name__ == '__main__':
    sys.exit(main())
