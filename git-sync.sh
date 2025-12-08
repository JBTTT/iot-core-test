#!/bin/bash

echo "======================================"
echo "     AUTO GIT SYNC (LOCAL → REMOTE)"
echo "======================================"

# Ensure we are inside a git repo
if [ ! -d ".git" ]; then
  echo "❌ Error: Not a Git repository."
  exit 1
fi

# 1. Show status
echo "📌 Current branch:"
git branch --show-current

echo "📌 Git status:"
git status

# 2. Stage all modified files
echo "📦 Staging all changes..."
git add .

# 3. Ask for commit message
echo "✏️ Enter commit message:"
read commit_message

# If empty message, abort
if [ -z "$commit_message" ]; then
  echo "❌ Commit message cannot be empty."
  exit 1
fi

# 4. Commit
echo "📝 Committing..."
git commit -m "$commit_message"

# 5. Rebase to sync with remote
echo "🔄 Rebasing with origin..."
git pull --rebase origin dev

# If rebase fails:
if [ $? -ne 0 ]; then
  echo "⚠️ Rebase encountered conflicts."
  echo "👉 Resolve conflicts manually, then run:"
  echo "     git add ."
  echo "     git rebase --continue"
  echo "👉 After rebase succeeds, push manually:"
  echo "     git push"
  exit 1
fi

# 6. Push to remote if rebase succeeded
echo "🚀 Pushing to origin..."
git push origin dev

echo "✅ Sync completed successfully!"
