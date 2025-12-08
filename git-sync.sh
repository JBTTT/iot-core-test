#!/bin/bash

# ------------------------------------------
# Auto Git Sync Script (Safe Rebase Workflow)
# ------------------------------------------

# Detect current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "🔍 Current branch: $BRANCH"
echo ""

# Ask user for commit message
read -p "Enter commit message: " COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
  echo "❌ Commit message cannot be empty."
  exit 1
fi

echo "📌 Staging changes..."
git add .

# Check if there is anything to commit
if git diff --cached --quiet; then
  echo "ℹ️ No changes to commit."
else
  echo "📝 Committing changes..."
  git commit -m "$COMMIT_MSG"
fi

echo ""
echo "🔄 Fetching remote updates..."
git fetch origin

echo "🌿 Rebasing $BRANCH with origin/$BRANCH..."
git rebase origin/$BRANCH

# Check rebase exit code
if [ $? -ne 0 ]; then
  echo ""
  echo "⚠️ Merge conflicts detected!"
  echo "➡️ Fix conflicts manually, then run:"
  echo "   git add ."
  echo "   git rebase --continue"
  echo "❌ Auto sync aborted."
  exit 1
fi

echo ""
echo "⬆️ Pushing changes to remote..."
git push origin $BRANCH

if [ $? -ne 0 ]; then
  echo "❌ Push failed! Force push is not used for safety."
  exit 1
fi

echo ""
echo "✅ Sync complete! Local and remote are up to date."
