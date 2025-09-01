#! /usr/bin/env sh

IF="./Scripts/Build.swift"
OF="./Scripts/Build"

# Check if submodule needs updating
echo "Checking for submodule updates..."
git submodule update --init --recursive

# Check if there are remote updates available
SUBMODULE_STATUS=$(git submodule status)
if echo "$SUBMODULE_STATUS" | grep -q "^+"; then
    echo "Submodule has local changes, updating to remote..."
    git submodule update --remote --force --recursive
elif git submodule foreach --quiet 'git fetch --quiet && [ $(git rev-list HEAD...origin/$(git branch --show-current) --count) -gt 0 ]' 2>/dev/null; then
    echo "Remote updates available, updating submodule..."
    git submodule update --remote --force --recursive
else
    echo "Submodule is up to date, skipping update"
fi

xcrun --sdk macosx swiftc -parse-as-library $IF -o $OF
$OF
