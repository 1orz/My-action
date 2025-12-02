#!/usr/bin/env bash

# 用法: ./cleanup_github_repo.sh <owner/repo> [keep]
# 示例: ./cleanup_github_repo.sh myuser/myrepo 4
# 需要: gh CLI (>=2.0) 和 jq
# 功能:
#   1. 仅保留最近 $keep 次 release（含 tag）
#   2. 仅保留最近 $keep 次 GitHub Actions workflow run
#   3. 其余全部删除 / 取消

set -eo pipefail

repo="$1"
keep="${2:-4}"

if [[ -z "$repo" ]]; then
  echo "用法: $0 <owner/repo> [keep_count]" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "jq 未安装，请先安装"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo >&2 "gh CLI 未安装，请先安装"; exit 1; }

echo "准备保留最近 $keep 个 release/tag，其余全部删除..."
releases_json=$(gh release list -R "$repo" --limit 400 --json tagName,createdAt --jq 'sort_by(.createdAt) | reverse')
total_releases=$(echo "$releases_json" | jq length)
if [[ "$total_releases" -gt "$keep" ]]; then
  echo "需要删除 $((total_releases-keep)) 个旧 release..."
  echo "$releases_json" | jq -r ".[$keep:][] | .tagName" | xargs -I{} gh release delete {} -R "$repo" -y --cleanup-tag || true
else
  echo "无需删除 release，总数: $total_releases"
fi

echo "准备保留最近 $keep 次 workflow run，其余全部删除/跳过..."
# 拉取所有 workflow run（可能分页）
workflow_runs=$(gh api -H "Accept: application/vnd.github+json" -X GET "repos/$repo/actions/runs?per_page=100" --paginate)
workflow_runs_sorted=$(echo "$workflow_runs" | jq '[.workflow_runs[] | {id, created_at, status}] | sort_by(.created_at) | reverse')

total_runs=$(echo "$workflow_runs_sorted" | jq length)
if [[ "$total_runs" -gt "$keep" ]]; then
  echo "需要处理 $((total_runs-keep)) 个旧 workflow run..."
  echo "$workflow_runs_sorted" | jq -c ".[${keep}:][]" | while read -r item; do
    run_id=$(echo "$item" | jq -r '.id')
    status=$(echo "$item" | jq -r '.status')
    echo "处理 run $run_id (status=$status) ..."
    if [[ "$status" == "completed" ]]; then
      if gh api -X DELETE "/repos/$repo/actions/runs/$run_id" >/dev/null 2>&1; then
        echo "   ✔ 已删除 run $run_id"
      else
        echo "   删除失败 run $run_id (可能权限不足)"
      fi
    else
      echo "   跳过运行中/排队中 run $run_id"
    fi
  done
else
  echo "无需删除 workflow run，总数: $total_runs"
fi

echo "清理完成！"
