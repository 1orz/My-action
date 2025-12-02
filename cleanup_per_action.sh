#!/usr/bin/env bash

# 用法: ./cleanup_per_action.sh <owner/repo> [keep_count] [--failure-only]
# 示例: 
#   ./cleanup_per_action.sh myuser/myrepo              # 每个 action 保留 2 个，删除全部旧的
#   ./cleanup_per_action.sh myuser/myrepo 3            # 每个 action 保留 3 个
#   ./cleanup_per_action.sh myuser/myrepo 2 --failure-only  # 只删除 failure 状态的 runs
# 需要: gh CLI (>=2.0) 和 jq
# 功能:
#   针对每个 GitHub Actions workflow，分别保留最多 N 个 release 和 N 个 workflow run
#   支持的 workflows:
#     - openwrt-x86-x64 (release前缀: openwrt-x86-64-)
#     - openwrt-armsr-armv8 (release前缀: openwrt-armsr-armv8-)
#     - openwrt-mips-redmi-ac2100 (release前缀: openwrt-mipsel-redmi-ac2100-)
#     - openwrt-arm64-tr3000 (release前缀: openwrt-arm64-tr3000-)

set -eo pipefail

repo="$1"
keep="${2:-2}"  # 每个 action 保留的数量，默认为 2
failure_only=false

# 解析参数
for arg in "$@"; do
  if [[ "$arg" == "--failure-only" ]]; then
    failure_only=true
  fi
done

if [[ -z "$repo" ]]; then
  echo "用法: $0 <owner/repo> [keep_count] [--failure-only]" >&2
  echo "  keep_count: 保留的数量（默认: 2）" >&2
  echo "  --failure-only: 只删除 failure 状态的 workflow runs" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "jq 未安装，请先安装"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo >&2 "gh CLI 未安装，请先安装"; exit 1; }

echo "=========================================="
echo "开始清理 GitHub 仓库: $repo"
echo "每个 action 保留最多 $keep 个 release 和 $keep 个 workflow run"
if [[ "$failure_only" == true ]]; then
  echo "模式: 只删除 failure 状态的 workflow runs"
else
  echo "模式: 删除所有旧的 workflow runs"
fi
echo "=========================================="

# 定义 workflow 和对应的 release tag 前缀、workflow 文件名（兼容 bash 3.2+）
workflows=("openwrt-x86-x64" "openwrt-armsr-armv8" "openwrt-mips-redmi-ac2100" "openwrt-arm64-tr3000")
prefixes=("openwrt-x86-64-" "openwrt-armsr-armv8-" "openwrt-mipsel-redmi-ac2100-" "openwrt-arm64-tr3000-")
workflow_files=("openwrt-x86-x64.yml" "openwrt-armsr-aarch64.yml" "openwrt-mips-redmi-ac2100.yml" "openwrt-arm64-tr3000.yml")

# 辅助函数：根据 workflow 名称获取前缀
get_prefix() {
  local workflow="$1"
  for i in "${!workflows[@]}"; do
    if [[ "${workflows[$i]}" == "$workflow" ]]; then
      echo "${prefixes[$i]}"
      return 0
    fi
  done
}

# 辅助函数：根据 workflow 名称获取文件名
get_workflow_file() {
  local workflow="$1"
  for i in "${!workflows[@]}"; do
    if [[ "${workflows[$i]}" == "$workflow" ]]; then
      echo "${workflow_files[$i]}"
      return 0
    fi
  done
}

# ===========================================
# 第一部分：清理 Releases（按 tag 前缀分组）
# ===========================================
echo ""
echo "第一步：清理 Releases"
echo "===================="

# 获取所有 releases
all_releases=$(gh release list -R "$repo" --limit 400 --json tagName,createdAt)

for i in "${!workflows[@]}"; do
  workflow_name="${workflows[$i]}"
  prefix="${prefixes[$i]}"
  echo ""
  echo "处理 workflow: $workflow_name (前缀: $prefix)"
  
  # 过滤出该 workflow 的 releases，按创建时间倒序排序
  workflow_releases=$(echo "$all_releases" | jq -c "[.[] | select(.tagName | startswith(\"$prefix\"))] | sort_by(.createdAt) | reverse")
  total_releases=$(echo "$workflow_releases" | jq 'length')
  
  if [[ "$total_releases" -gt "$keep" ]]; then
    delete_count=$((total_releases - keep))
    echo "  找到 $total_releases 个 release，需要删除 $delete_count 个旧 release"
    
    echo "$workflow_releases" | jq -r ".[$keep:][] | .tagName" | while read -r tag; do
      if gh release delete "$tag" -R "$repo" -y --cleanup-tag 2>&1; then
        echo "    ✔ 已删除 release: $tag"
      else
        echo "    ⚠ 删除失败 release: $tag"
      fi
    done
  else
    echo "  找到 $total_releases 个 release，无需删除"
  fi
done

# ===========================================
# 第一部分-B：清理孤儿 Releases（不匹配任何当前前缀）
# ===========================================
echo ""
echo "第一步-B：清理孤儿 Releases"
echo "========================="

# 构建 jq 过滤条件来找出不匹配任何前缀的 releases
jq_filter='(.tagName | startswith("openwrt-x86-64-") | not) and (.tagName | startswith("openwrt-armsr-armv8-") | not) and (.tagName | startswith("openwrt-mipsel-redmi-ac2100-") | not) and (.tagName | startswith("openwrt-arm64-tr3000-") | not)'

orphan_releases=$(echo "$all_releases" | jq -c "[.[] | select($jq_filter)]")
total_orphans=$(echo "$orphan_releases" | jq 'length')

if [[ "$total_orphans" -gt 0 ]]; then
  echo "  找到 $total_orphans 个孤儿 release（旧命名格式），准备删除"
  
  echo "$orphan_releases" | jq -r '.[] | .tagName' | while read -r tag; do
    # 删除 release，并尝试清理 tag
    if gh release delete "$tag" -R "$repo" -y --cleanup-tag 2>&1; then
      echo "    ✔ 已删除孤儿 release: $tag"
    else
      echo "    ⚠ 删除失败 release: $tag"
    fi
    
    # 再次确认 tag 是否已删除，如果还在则手动删除
    if gh api "repos/$repo/git/ref/tags/$tag" >/dev/null 2>&1; then
      echo "    ⚠ tag 仍然存在，尝试手动删除..."
      if gh api -X DELETE "repos/$repo/git/refs/tags/$tag" >/dev/null 2>&1; then
        echo "    ✔ 已手动删除 tag: $tag"
      else
        echo "    ✗ 手动删除 tag 失败: $tag"
      fi
    fi
  done
else
  echo "  没有找到孤儿 release"
fi

# ===========================================
# 第一部分-C：清理孤儿 Tags（有 tag 但没有 release）
# ===========================================
echo ""
echo "第一步-C：清理孤儿 Tags"
echo "====================="

# 获取所有 tags
all_tags=$(gh api "repos/$repo/tags?per_page=100" | jq -r '.[] | .name')

# 获取所有 release 的 tags
release_tags=$(echo "$all_releases" | jq -r '.[] | .tagName')

# 找出孤儿 tags（有 tag 但没有 release）
orphan_tags=()
while IFS= read -r tag; do
  if ! echo "$release_tags" | grep -q "^${tag}$"; then
    orphan_tags+=("$tag")
  fi
done <<< "$all_tags"

if [[ ${#orphan_tags[@]} -gt 0 ]]; then
  echo "  找到 ${#orphan_tags[@]} 个孤儿 tag（有 tag 但没有 release），准备删除"
  
  for tag in "${orphan_tags[@]}"; do
    if gh api -X DELETE "repos/$repo/git/refs/tags/$tag" >/dev/null 2>&1; then
      echo "    ✔ 已删除孤儿 tag: $tag"
    else
      echo "    ⚠ 删除失败 tag: $tag"
    fi
  done
else
  echo "  没有找到孤儿 tag"
fi

# ===========================================
# 第二部分：清理 Workflow Runs（按 workflow 名称分组）
# ===========================================
echo ""
echo "第二步：清理 Workflow Runs"
echo "========================="

for workflow_name in "${workflows[@]}"; do
  echo ""
  echo "处理 workflow: $workflow_name"
  
  # 获取正确的 workflow 文件名
  workflow_file=$(get_workflow_file "$workflow_name")
  
  # 获取该 workflow 的所有 runs
  workflow_runs=$(gh api -H "Accept: application/vnd.github+json" \
    "repos/$repo/actions/workflows/$workflow_file/runs?per_page=100" \
    --paginate 2>/dev/null || echo '{"workflow_runs":[]}')
  
  # 按创建时间倒序排序（使用 -s 合并多个 JSON 对象）
  workflow_runs_sorted=$(echo "$workflow_runs" | jq -s '[.[] | (.workflow_runs // [])[] | {id, created_at, status, conclusion}] | sort_by(.created_at) | reverse')
  
  total_runs=$(echo "$workflow_runs_sorted" | jq 'length' | head -1)
  
  if [[ "$failure_only" == true ]]; then
    # 只删除 failure 状态的 runs
    echo "  找到 $total_runs 个 workflow run，正在筛选 failure 状态的 runs"
    
    echo "$workflow_runs_sorted" | jq -c '.[]' | while read -r item; do
      run_id=$(echo "$item" | jq -r '.id')
      status=$(echo "$item" | jq -r '.status')
      conclusion=$(echo "$item" | jq -r '.conclusion')
      
      if [[ "$status" == "completed" && "$conclusion" == "failure" ]]; then
        if gh api -X DELETE "/repos/$repo/actions/runs/$run_id" >/dev/null 2>&1; then
          echo "    ✔ 已删除 failure run $run_id"
        else
          echo "    ⚠ 删除失败 run $run_id (可能权限不足)"
        fi
      fi
    done
  else
    # 保留前 N 个，删除其余的
    if [[ "$total_runs" -gt "$keep" ]]; then
      delete_count=$((total_runs - keep))
      echo "  找到 $total_runs 个 workflow run，需要处理 $delete_count 个旧 run"
      
      echo "$workflow_runs_sorted" | jq -c ".[${keep}:][]" | while read -r item; do
        run_id=$(echo "$item" | jq -r '.id')
        status=$(echo "$item" | jq -r '.status')
        conclusion=$(echo "$item" | jq -r '.conclusion')
        
        if [[ "$status" == "completed" ]]; then
          if gh api -X DELETE "/repos/$repo/actions/runs/$run_id" >/dev/null 2>&1; then
            echo "    ✔ 已删除 run $run_id (结论: $conclusion)"
          else
            echo "    ⚠ 删除失败 run $run_id (可能权限不足)"
          fi
        else
          echo "    ⏭ 跳过运行中 run $run_id (状态: $status)"
        fi
      done
    else
      echo "  找到 $total_runs 个 workflow run，无需删除"
    fi
  fi
done

echo ""
echo "=========================================="
echo "清理完成！"
echo "=========================================="

