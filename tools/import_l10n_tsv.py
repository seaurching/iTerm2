#!/usr/bin/env python3
# 批量导入翻译到 <表名>.strings 的全部 lproj 变体。
# 用法: python3 tools/import_l10n_tsv.py <sources子目录> <表名> <tsv文件>
# TSV 格式(制表符分隔,UTF-8):key<TAB>zh-Hans<TAB>zh-Hant
# en/Base 自动补英文恒等键;8 个变体(含 zh_CN/zh_TW/zh-Hans-CN/zh-Hant-TW)自动同步。
import sys
import os
import glob

VARIANTS = {
    'zh-Hans': 1, 'zh-Hans-CN': 1, 'zh_CN': 1,
    'zh-Hant': 2, 'zh-Hant-TW': 2, 'zh_TW': 2,
    'en': 0, 'Base': 0,
}

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

def main():
    src_dir, table, tsv_path = sys.argv[1], sys.argv[2], sys.argv[3]
    entries = []
    for line in open(tsv_path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        parts = line.split('\t')
        if len(parts) != 3:
            print(f"跳过格式错误行: {line[:60]}")
            continue
        entries.append(parts)
    if not entries:
        print("TSV 为空")
        return 1
    for variant, col in VARIANTS.items():
        path = os.path.join(src_dir, variant + '.lproj', table + '.strings')
        if not os.path.exists(path):
            print(f"警告: {path} 不存在,跳过")
            continue
        existing = set()
        for line in open(path, encoding='utf-8'):
            m = None
            import re
            m = re.match(r'^"((?:[^"\\]|\\.)*)"\s*=', line)
            if m:
                existing.add(m.group(1).replace('\\n', '\n').replace('\\"', '"'))
        with open(path, 'a', encoding='utf-8') as f:
            for key, hans, hant in entries:
                k = key  # TSV 中 key 已是未转义形式
                if k in existing:
                    continue
                val = (hans, hant, key)[col]
                f.write(f'"{esc(key)}" = "{esc(val)}";\n')
        print(f"{variant}: 追加 {len(entries)} 条检查完成")
    print(f"共 {len(entries)} 条")

if __name__ == '__main__':
    sys.exit(main())
