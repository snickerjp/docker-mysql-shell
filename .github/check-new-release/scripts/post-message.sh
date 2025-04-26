# !/bin/bash (This is not used as the script is executed with bash command without execution permission)
# Set strict mode
set -eu

# Only execute if DRY_RUN is not true
if [[ "$DRY_RUN" != "true" ]]; then
  echo "::group::PR Creation Completed"
  echo "✅ PR for MySQL Shell version update has been created."
  echo ""
  echo "⚠️ For security reasons, workflow files were NOT automatically updated."
  echo "Please check the PR description for required manual workflow file updates."
  echo ""
  echo "::endgroup::"
  
  echo "::group::Workflow File Update Procedure"
  echo "1. Checkout the PR branch locally:"
  echo "   git fetch origin $BRANCH_NAME && git checkout $BRANCH_NAME"
  echo ""
  echo "2. Update workflow files with the following commands:"
  
  # For Innovation update
  if [[ "$INNOVATION_UPDATE_NEEDED" == "true" ]]; then
    INNOVATION_MAJOR=$(echo "$LATEST_INNOVATION" | cut -d. -f1)
    INNOVATION_MINOR=$(echo "$LATEST_INNOVATION" | cut -d. -f2)
    INNOVATION_SHORT="${INNOVATION_MAJOR}.${INNOVATION_MINOR}"
    echo "   # Innovation update command:"
    echo "   find .github/workflows -name \"docker-*.yml\" -exec sed -i 's/version: ${INNOVATION_MAJOR}\\.x/version: ${INNOVATION_SHORT}/g' {} \\;"
  fi
  
  # For LTS update
  if [[ "$LTS_UPDATE_NEEDED" == "true" ]]; then
    LTS_MAJOR=$(echo "$LATEST_LTS" | cut -d. -f1)
    LTS_MINOR=$(echo "$LATEST_LTS" | cut -d. -f2)
    LTS_SHORT="${LTS_MAJOR}.${LTS_MINOR}"
    echo "   # LTS update command:"
    echo "   find .github/workflows -name \"docker-*.yml\" -exec sed -i 's/version: ${LTS_MAJOR}\\.x/version: ${LTS_SHORT}/g' {} \\;"
  fi
  
  echo ""
  echo "3. Commit the changes:"
  echo "   git add .github/workflows/"
  echo "   git commit -m \"Update workflow files for MySQL Shell versions\""
  echo ""
  echo "4. Push the changes:"
  echo "   git push origin $BRANCH_NAME"
  echo ""
  echo "This will add workflow file updates to the existing PR."
  echo "::endgroup::"
fi
