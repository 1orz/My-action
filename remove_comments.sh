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

  # 删除以 # 开头（允许前导空白）的整行注释（不改动行内注释）
  sed -i -E '/^[[:space:]]*#/d' "$file"
done


