#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "用法: $0 FILE [FILE...]" >&2
  exit 1
fi

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "跳过非文件: $file" >&2
    continue
  fi

  # 只删除 # CONFIG_ 格式的注释行（允许前导空白），保留分节标题等其他注释
  sed -i '' -E '/^[[:space:]]*#[[:space:]]*CONFIG_/d' "$file"
done


