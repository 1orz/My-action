#!/usr/bin/env bash

set -eo pipefail

repo="$1"
keep="${2:-2}"

if [[ -z "$repo" ]]; then
  echo "Usage: $0 <owner/repo> [keep_count]" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "jq not installed" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh CLI not installed" >&2; exit 1; }

echo "Cleaning repo: $repo (keep $keep per action)"

prefixes=("openwrt-x86-64-" "openwrt-armsr-aarch64-" "openwrt-mipsel-redmi-ac2100-" "openwrt-arm64-tr3000-" "openwrt-arm64-glinet-mt3000-")
workflow_file="openwrt-build.yml"

echo -e "\n=== Cleaning Releases ==="
all_releases=$(gh release list -R "$repo" --limit 400 --json tagName,createdAt)

for prefix in "${prefixes[@]}"; do
  echo "Processing prefix: $prefix"
  
  workflow_releases=$(echo "$all_releases" | jq -c "[.[] | select(.tagName | startswith(\"$prefix\"))] | sort_by(.createdAt) | reverse")
  total=$(echo "$workflow_releases" | jq 'length')
  
  if [[ "$total" -gt "$keep" ]]; then
    echo "$workflow_releases" | jq -r ".[$keep:][] | .tagName" | while read -r tag; do
      gh release delete "$tag" -R "$repo" -y --cleanup-tag 2>&1 && echo "  Deleted: $tag" || echo "  Failed: $tag"
    done
  fi
done

echo -e "\n=== Cleaning Orphan Releases ==="
jq_filter='(.tagName | startswith("openwrt-x86-64-") | not) and (.tagName | startswith("openwrt-armsr-aarch64-") | not) and (.tagName | startswith("openwrt-mipsel-redmi-ac2100-") | not) and (.tagName | startswith("openwrt-arm64-tr3000-") | not) and (.tagName | startswith("openwrt-arm64-glinet-mt3000-") | not)'
orphan_releases=$(echo "$all_releases" | jq -c "[.[] | select($jq_filter)]")
total_orphans=$(echo "$orphan_releases" | jq 'length')

if [[ "$total_orphans" -gt 0 ]]; then
  echo "$orphan_releases" | jq -r '.[] | .tagName' | while read -r tag; do
    gh release delete "$tag" -R "$repo" -y --cleanup-tag 2>&1 && echo "  Deleted: $tag" || true
    gh api "repos/$repo/git/ref/tags/$tag" >/dev/null 2>&1 && gh api -X DELETE "repos/$repo/git/refs/tags/$tag" >/dev/null 2>&1 || true
  done
fi

echo -e "\n=== Cleaning Orphan Tags ==="
all_tags=$(gh api "repos/$repo/tags?per_page=100" 2>/dev/null | jq -r '.[] | .name' || echo "")
release_tags=$(echo "$all_releases" | jq -r '.[] | .tagName')

if [[ -n "$all_tags" ]]; then
  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue
    if ! echo "$release_tags" | grep -q "^${tag}$"; then
      gh api -X DELETE "repos/$repo/git/refs/tags/$tag" >/dev/null 2>&1 && echo "  Deleted: $tag"
    fi
  done <<< "$all_tags"
fi

echo -e "\n=== Cleaning Workflow Runs (Keep $keep Success) ==="

workflow_runs=$(gh api -H "Accept: application/vnd.github+json" \
  "repos/$repo/actions/workflows/$workflow_file/runs?per_page=100" \
  --paginate 2>/dev/null || echo '{"workflow_runs":[]}')

all_runs=$(echo "$workflow_runs" | jq -s '[.[] | (.workflow_runs // [])[] | {id, created_at, status, conclusion}] | sort_by(.created_at) | reverse')

success_runs=$(echo "$all_runs" | jq -c '[.[] | select(.conclusion == "success")]')
failed_runs=$(echo "$all_runs" | jq -c '[.[] | select(.conclusion != "success")]')

success_count=$(echo "$success_runs" | jq 'length')
failed_count=$(echo "$failed_runs" | jq 'length')

echo "Total runs - Success: $success_count, Failed/Other: $failed_count"

if [[ "$success_count" -ge "$keep" ]]; then
  to_keep_ids=$(echo "$success_runs" | jq -r ".[0:$keep][] | .id")
else
  to_keep_ids=$(echo "$success_runs" | jq -r '.[] | .id')
fi

total_runs=$(echo "$all_runs" | jq 'length')
deleted=0

for ((idx=0; idx<total_runs; idx++)); do
  item=$(echo "$all_runs" | jq -c ".[$idx]")
  run_id=$(echo "$item" | jq -r '.id')
  status=$(echo "$item" | jq -r '.status')
  conclusion=$(echo "$item" | jq -r '.conclusion')
  
  if echo "$to_keep_ids" | grep -q "^${run_id}$"; then
    continue
  fi
  
  if [[ "$status" == "completed" ]]; then
    if gh api -X DELETE "/repos/$repo/actions/runs/$run_id" 2>/dev/null; then
      echo "  Deleted: run $run_id ($conclusion)"
      ((deleted++))
      sleep 0.5
    else
      echo "  Failed: run $run_id (may lack permission)"
    fi
  fi
done || true

echo "Deleted $deleted workflow runs"

echo -e "\n=== Cleanup Complete ==="
