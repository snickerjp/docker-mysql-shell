# !/bin/bash (This is not used as the script is executed with bash command without execution permission)
# Set strict mode
set -eu

# Check if in dry run mode
if [[ "$DRY_RUN" == "true" ]]; then
  echo "::notice::Running in dry run mode. No actual changes will be made."
fi

# Use the BRANCH_NAME environment variable passed from the workflow
# Verify that BRANCH_NAME is set
if [[ -z "${BRANCH_NAME:-}" ]]; then
  echo "::error::BRANCH_NAME environment variable is not set. This should be set by the workflow."
  exit 1
fi

echo "Using branch name: $BRANCH_NAME"

if [[ "$DRY_RUN" != "true" ]]; then
  git config --global user.name 'github-actions[bot]'
  git config --global user.email 'github-actions[bot]@users.noreply.github.com'
  git checkout -b $BRANCH_NAME
else
  echo "dry run: git checkout -b $BRANCH_NAME"
fi

# Initialize PR body
PR_TEMPLATE=$(cat .github/check-new-release/templates/pr.md)
PR_BODY=""

# Initialize workflow update status flag
WORKFLOW_UPDATED="false"

# Version update function
update_version() {
  local type=$1
  local current_version=$2
  local new_version=$3
  local major_version=$(echo "$new_version" | cut -d. -f1)
  local minor_version=$(echo "$new_version" | cut -d. -f2)
  local short_version="${major_version}.${minor_version}"
  
  echo "Updating $type to $new_version (major.minor: $short_version)..."
  
  # Update Dockerfile
  if [[ "$DRY_RUN" != "true" ]]; then
    if ! sed -i "s/^ARG MYSQL_SHELL_VERSION=.*/ARG MYSQL_SHELL_VERSION=$new_version/" docker/$type/Dockerfile; then
      echo "::error::Failed to update version in docker/$type/Dockerfile"
      echo "This is a critical error while updating an important file. Aborting."
      exit 1
    fi
    
    # Verify the update was successful
    if ! grep -q "ARG MYSQL_SHELL_VERSION=$new_version" docker/$type/Dockerfile; then
      echo "::error::Version update in docker/$type/Dockerfile could not be verified"
      echo "Cannot verify Dockerfile update. Aborting."
      exit 1
    fi
  else
    # Show more detailed information in dry run mode
    echo "dry run: Command to execute: sed -i \"s/^ARG MYSQL_SHELL_VERSION=.*/ARG MYSQL_SHELL_VERSION=$new_version/\" docker/$type/Dockerfile"
    echo "dry run: Update ARG MYSQL_SHELL_VERSION=$current_version to $new_version in docker/$type/Dockerfile"
  fi
  
  # Update README.md
  if [[ "$type" == "innovation" ]]; then
    local match_pattern="Innovation Series ([0-9]\\.[0-9]\\.[x0-9])"
    local replace_value="Innovation Series (${major_version}.${minor_version}.x)"
    local tag_pattern="snickerjp\/docker-mysql-shell:${major_version}\\.[0-9]"
    local tag_replace="snickerjp\/docker-mysql-shell:${short_version}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
      # README updates are important but we continue even if they fail
      sed -i "s/$match_pattern/$replace_value/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update Innovation Series version in README.md"
        echo "Failed to update README.md but will continue with the process."
      fi
      
      sed -i "s/$tag_pattern/$tag_replace/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update Innovation image tag in README.md"
        echo "Failed to update tag in README.md but will continue with the process."
      fi
    else
      # Show more detailed information in dry run mode
      echo "dry run: Command to execute: sed -i \"s/$match_pattern/$replace_value/g\" README.md"
      echo "dry run: Command to execute: sed -i \"s/$tag_pattern/$tag_replace/g\" README.md"
      echo "dry run: Update '$match_pattern' to '$replace_value' in README.md"
      echo "dry run: Update '$tag_pattern' to '$tag_replace' in README.md"
    fi
  else
    local match_pattern="LTS Series ([0-9]\\.[0-9]\\.[x0-9])"
    local replace_value="LTS Series (${major_version}.${minor_version}.x)"
    local tag_pattern="snickerjp\/docker-mysql-shell:${major_version}\\.[0-9]"
    local tag_replace="snickerjp\/docker-mysql-shell:${short_version}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
      sed -i "s/$match_pattern/$replace_value/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update LTS Series version in README.md"
        echo "Failed to update README.md but will continue with the process."
      fi
      
      sed -i "s/$tag_pattern/$tag_replace/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update LTS image tag in README.md"
        echo "Failed to update tag in README.md but will continue with the process."
      fi
    else
      # Show more detailed information in dry run mode
      echo "dry run: Command to execute: sed -i \"s/$match_pattern/$replace_value/g\" README.md"
      echo "dry run: Command to execute: sed -i \"s/$tag_pattern/$tag_replace/g\" README.md"
      echo "dry run: Update '$match_pattern' to '$replace_value' in README.md"
      echo "dry run: Update '$tag_pattern' to '$tag_replace' in README.md"
    fi
  fi
  
  # Check workflow files for potential updates (but don't modify)
  local workflow_files=$(find .github/workflows -name "docker-*.yml" 2>/dev/null || echo "")
  if [[ -n "$workflow_files" ]]; then
    echo "Checking workflow files for necessary updates (will not modify them)..."
    
    # Create patterns to match both formats: version: X.Y and version: X.x
    local version_pattern1="version: ${major_version}\\.x"
    local version_replace1="version: ${short_version}"
    local version_pattern2="version: ${major_version}\\.[0-9]"
    local version_replace2="version: ${short_version}"
    
    # Create a section in PR body for workflow file updates
    WORKFLOW_INSTRUCTIONS=""
    local any_needs_update=false
    
    # Check each workflow file
    for workflow_file in $workflow_files; do
      # Check for version: X.x pattern
      if grep -q "$version_pattern1" "$workflow_file"; then
        any_needs_update=true
        echo "Found workflow file needing update (pattern 1): $workflow_file"
        
        # Get the line number and context for the PR description
        local line_info=$(grep -n "$version_pattern1" "$workflow_file")
        local line_num=$(echo "$line_info" | cut -d':' -f1)
        local line_content=$(echo "$line_info" | cut -d':' -f2-)
        
        # Add to workflow update instructions
        WORKFLOW_INSTRUCTIONS="${WORKFLOW_INSTRUCTIONS}
- **$workflow_file** (line $line_num):
  - From: \`$line_content\`
  - To: \`$(echo "$line_content" | sed "s/$version_pattern1/$version_replace1/")\`"
      # Check for version: X.Y pattern
      elif grep -q "$version_pattern2" "$workflow_file"; then
        # Only consider it an update if the minor version actually changed
        local current_pattern="version: ${major_version}\\.${minor_version_old}"
        if grep -q "$current_pattern" "$workflow_file"; then
          any_needs_update=true
          echo "Found workflow file needing update (pattern 2): $workflow_file"
          
          # Get the line number and context for the PR description
          local line_info=$(grep -n "$current_pattern" "$workflow_file")
          local line_num=$(echo "$line_info" | cut -d':' -f1)
          local line_content=$(echo "$line_info" | cut -d':' -f2-)
          
          # Add to workflow update instructions
          WORKFLOW_INSTRUCTIONS="${WORKFLOW_INSTRUCTIONS}
- **$workflow_file** (line $line_num):
  - From: \`$line_content\`
  - To: \`$(echo "$line_content" | sed "s/$current_pattern/version: ${short_version}/")\`"
        else
          echo "::info::Version pattern found but no update needed (current version): $workflow_file"
        fi
      else
        echo "::info::No matching pattern found, no update needed: $workflow_file"
      fi
    done
    
    # Set flag if any workflows need updates
    if [[ "$any_needs_update" == "true" ]]; then
      WORKFLOW_UPDATED="true"
      echo "⚠️ Found workflow files that need manual updates (details will be in PR description)"
    fi
  else
    echo "::warning::No workflow files found."
    # No files found
    echo "⚠️ No workflow files found for checking"
  fi
  
  # Add version update details to PR body (formatted)
  PR_BODY="${PR_BODY}

### $(if [[ "$type" == "lts" ]]; then echo "LTS"; else echo "${type^}"; fi) Version Update
* **${current_version}** → **${new_version}**"
  
  # Success log
  echo "✅ $type version update completed"
}

# Update Innovation
if [[ "$INNOVATION_UPDATE_NEEDED" == "true" ]]; then
  update_version "innovation" "$CURRENT_INNOVATION" "$LATEST_INNOVATION"
fi

# Update LTS
if [[ "$LTS_UPDATE_NEEDED" == "true" ]]; then
  update_version "lts" "$CURRENT_LTS" "$LATEST_LTS"
fi

# Add necessary steps to PR body
PR_BODY="${PR_BODY}

## Update Content
- Updated version numbers in Dockerfiles
- Updated version references in README.md"

# Add workflow update instructions if needed
if [[ "${WORKFLOW_UPDATED:-}" == "true" && -n "${WORKFLOW_INSTRUCTIONS:-}" ]]; then
  PR_BODY="${PR_BODY}

## ⚠️ Required Manual Updates for Workflow Files
For security reasons, workflow files cannot be automatically updated by GitHub Actions.
Please manually update the following files:
${WORKFLOW_INSTRUCTIONS}

You can apply these changes by:
1. Checking out the branch: \`git checkout ${BRANCH_NAME}\`
2. Making the changes shown above
3. Committing and pushing: \`git commit -am 'Update workflow versions' && git push\`"
else
  PR_BODY="${PR_BODY}
- ✓ No workflow file updates needed"
fi

PR_BODY="${PR_BODY}

## ⚠️ Notes
1. Please verify all file changes before merging
2. Workflow files require manual updates (if any are listed above)"

# Commit and push changes
changed_files=$(git status --porcelain | awk '{print $2}')
if [[ -z "$changed_files" ]]; then
  echo "No changes to commit."
  exit 0
fi

# Check changed files
echo "Changed files:"
for file in $changed_files; do
  echo "- $file"
done

# Stage all changes
if [[ "$DRY_RUN" != "true" ]]; then
  git add $changed_files
  git commit -m "Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)"
  
  # Push with error handling
  if ! git push origin $BRANCH_NAME; then
    echo "::error::Failed to push changes to GitHub"
    exit 1
  fi
  
  # Create pull request
  if ! gh pr create \
    --base develop \
    --head $BRANCH_NAME \
    --title "Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)" \
    --body "$PR_BODY"; then
    echo "::error::Failed to create Pull Request"
    exit 1
  fi
  
  echo "Pull request created successfully!"
else
  echo "dry run: The following files would be changed:"
  for file in $changed_files; do
    echo "- $file"
  done
  echo "dry run: Commit message: Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)"
  echo "dry run: PR creation: Title: Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)"
  echo "dry run: PR body:"
  echo -e "$PR_BODY"
  echo "dry run completed: No actual changes were made."
fi
