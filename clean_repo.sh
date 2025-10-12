#!/bin/bash
repo=$1
keep_count=$2

echo "Fetching all releases..."
releases=$(gh release list -R "${repo}" --limit 100 --json tagName,name,createdAt --jq 'sort_by(.createdAt) | reverse')
echo "Total releases found: $(echo "$releases" | jq length)"
# Keep the latest 3 releases, delete the rest
delete_count=$(echo "$releases" | jq ".[${keep_count}:] | length")
if [ "$delete_count" -gt 0 ]; then
  echo "🧹 Will delete $delete_count old releases..."
  echo "$releases" | jq -r ".[${keep_count}:][] | .tagName" | xargs -I{} sh -c '
    echo "Deleting release and tag: {}"
    gh release delete "{}" -R "'"${repo}"'" -y --cleanup-tag || true
  '
else
  echo "✅ Nothing to delete, only $(echo "$releases" | jq length) releases exist."
fi

gh api -X GET /repos/${repo}/actions/runs --paginate | jq '.workflow_runs[] | .id' | xargs -I{} gh api --silent -X DELETE /repos/${repo}/actions/runs/{} ;