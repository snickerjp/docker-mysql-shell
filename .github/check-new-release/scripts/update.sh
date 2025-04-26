# !/bin/bash (実行権限を付与せずbashコマンドで実行されるため実際には使用されない)
# 厳格モードを設定
set -eu

# dry runモードを確認
if [[ "$DRY_RUN" == "true" ]]; then
  echo "::notice::dry runモードで実行しています。実際の変更は行いません。"
fi

# ブランチ作成
BRANCH_NAME="bot/update-mysql-shell-$(date +%Y%m%d%H%M%S)"
if [[ "$DRY_RUN" != "true" ]]; then
  git config --global user.name 'github-actions[bot]'
  git config --global user.email 'github-actions[bot]@users.noreply.github.com'
  git checkout -b $BRANCH_NAME
else
  echo "dry run: git checkout -b $BRANCH_NAME"
fi

# PR本文の初期化
PR_TEMPLATE=$(cat .github/check-new-release/templates/pr.md)
PR_BODY=""

# バージョン更新関数
update_version() {
  local type=$1
  local current_version=$2
  local new_version=$3
  local major_version=$(echo "$new_version" | cut -d. -f1)
  local minor_version=$(echo "$new_version" | cut -d. -f2)
  local short_version="${major_version}.${minor_version}"
  
  echo "Updating $type to $new_version (major.minor: $short_version)..."
  
  # Dockerfile の更新
  if [[ "$DRY_RUN" != "true" ]]; then
    if ! sed -i "s/^ARG MYSQL_SHELL_VERSION=.*/ARG MYSQL_SHELL_VERSION=$new_version/" docker/$type/Dockerfile; then
      echo "::error::Failed to update version in docker/$type/Dockerfile"
      echo "このエラーは重要なファイル更新に失敗したため、処理を中断します。"
      exit 1
    fi
    
    # 更新が成功したか検証
    if ! grep -q "ARG MYSQL_SHELL_VERSION=$new_version" docker/$type/Dockerfile; then
      echo "::error::Version update in docker/$type/Dockerfile could not be verified"
      echo "Dockerfileの更新内容を確認できないため処理を中断します。"
      exit 1
    fi
  else
    # dry runモードではより詳細な情報を表示
    echo "dry run: 実行予定のコマンド: sed -i \"s/^ARG MYSQL_SHELL_VERSION=.*/ARG MYSQL_SHELL_VERSION=$new_version/\" docker/$type/Dockerfile"
    echo "dry run: docker/$type/Dockerfile 内の ARG MYSQL_SHELL_VERSION=$current_version を $new_version に更新"
  fi
  
  # README.md の更新
  if [[ "$type" == "innovation" ]]; then
    local match_pattern="Innovation Series ([0-9]\\.[0-9]\\.[x0-9])"
    local replace_value="Innovation Series (${major_version}.${minor_version}.x)"
    local tag_pattern="snickerjp\/docker-mysql-shell:${major_version}\\.[0-9]"
    local tag_replace="snickerjp\/docker-mysql-shell:${short_version}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
      # READMEの更新は重要だが失敗しても処理は継続する
      sed -i "s/$match_pattern/$replace_value/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update Innovation Series version in README.md"
        echo "README.mdの更新に失敗しましたが、処理は継続します。"
      fi
      
      sed -i "s/$tag_pattern/$tag_replace/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update Innovation image tag in README.md"
        echo "README.mdのタグ更新に失敗しましたが、処理は継続します。"
      fi
    else
      # dry runモードではより詳細な情報を表示
      echo "dry run: 実行予定のコマンド: sed -i \"s/$match_pattern/$replace_value/g\" README.md"
      echo "dry run: 実行予定のコマンド: sed -i \"s/$tag_pattern/$tag_replace/g\" README.md"
      echo "dry run: README.md 内の '$match_pattern' を '$replace_value' に更新"
      echo "dry run: README.md 内の '$tag_pattern' を '$tag_replace' に更新"
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
        echo "README.mdの更新に失敗しましたが、処理は継続します。"
      fi
      
      sed -i "s/$tag_pattern/$tag_replace/g" README.md
      if [ $? -ne 0 ]; then
        echo "::warning::Failed to update LTS image tag in README.md"
        echo "README.mdのタグ更新に失敗しましたが、処理は継続します。"
      fi
    else
      # dry runモードではより詳細な情報を表示
      echo "dry run: 実行予定のコマンド: sed -i \"s/$match_pattern/$replace_value/g\" README.md"
      echo "dry run: 実行予定のコマンド: sed -i \"s/$tag_pattern/$tag_replace/g\" README.md"
      echo "dry run: README.md 内の '$match_pattern' を '$replace_value' に更新"
      echo "dry run: README.md 内の '$tag_pattern' を '$tag_replace' に更新"
    fi
  fi
  
  # ワークフローファイルの自動更新
  local workflow_files=$(find .github/workflows -name "docker-*.yml" 2>/dev/null || echo "")
  if [[ -n "$workflow_files" ]]; then
    echo "ワークフローファイルを自動的に更新します..."
    
    local version_pattern="version: ${major_version}\\.x"
    local version_replace="version: ${short_version}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
      # 各ファイルに対して実行
      for workflow_file in $workflow_files; do
        if grep -q "$version_pattern" "$workflow_file"; then
          echo "更新: $workflow_file"
          sed -i "s/$version_pattern/$version_replace/g" "$workflow_file"
          if [ $? -ne 0 ]; then
            echo "::warning::Failed to update version in $workflow_file"
            echo "ワークフローファイル $workflow_file の更新に失敗しましたが、処理は継続します。"
          fi
        else
          echo "::info::該当するパターンがないため更新不要: $workflow_file"
        fi
      done
    else
      echo "dry run: 以下のファイルを更新予定:"
      for workflow_file in $workflow_files; do
        if grep -q "$version_pattern" "$workflow_file"; then
          echo "dry run: $workflow_file 内の '$version_pattern' を '$version_replace' に更新"
          echo "dry run: 実行予定のコマンド: sed -i \"s/$version_pattern/$version_replace/g\" \"$workflow_file\""
        fi
      done
    fi
    
    # PR説明文にワークフローファイル更新の旨を追加
    PR_BODY="${PR_BODY} (ワークフローファイルも自動的に更新されました)"
  else
    echo "::warning::ワークフローファイルが見つかりませんでした。"
  fi
  
  # PR本文に変更内容を追加（整形された形式で）
  PR_BODY="${PR_BODY}

### ${type^} バージョン更新
* **${current_version}** → **${new_version}**"
  
  # 成功ログ
  echo "✅ $type のバージョン更新が完了しました"
}

# Innovation の更新
if [[ "$INNOVATION_UPDATE_NEEDED" == "true" ]]; then
  update_version "innovation" "$CURRENT_INNOVATION" "$LATEST_INNOVATION"
fi

# LTS の更新
if [[ "$LTS_UPDATE_NEEDED" == "true" ]]; then
  update_version "lts" "$CURRENT_LTS" "$LATEST_LTS"
fi

# PR本文に必要な手順を追加
PR_BODY="${PR_BODY}

## 更新内容
- Dockerfileのバージョン番号更新
- README.mdのバージョン表記を更新
- ワークフローファイルを自動的に更新

## ⚠️ 注意事項
1. ワークフローファイルの自動更新が行われていない場合は手動で更新してください
2. マージ前に各ファイルの更新内容を確認してください"

# 変更をコミットしてプッシュ
changed_files=$(git status --porcelain | awk '{print $2}')
if [[ -z "$changed_files" ]]; then
  echo "No changes to commit."
  exit 0
fi

# ファイルの変更をチェック
echo "Changed files:"
for file in $changed_files; do
  echo "- $file"
done

# すべての変更をステージング
if [[ "$DRY_RUN" != "true" ]]; then
  git add $changed_files
  git commit -m "Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)"
  
  # エラーハンドリング付きでプッシュ
  if ! git push origin $BRANCH_NAME; then
    echo "::error::Failed to push changes to GitHub"
    exit 1
  fi
  
  # プルリクエストを作成
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
  echo "dry run: 以下のファイルが変更されます:"
  for file in $changed_files; do
    echo "- $file"
  done
  echo "dry run: コミットメッセージ: Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)"
  echo "dry run: PR作成: タイトル: Update MySQL Shell versions (Innovation: $LATEST_INNOVATION, LTS: $LATEST_LTS)"
  echo "dry run: PR本文:"
  echo -e "$PR_BODY"
  echo "dry run終了: 実際の変更は行われていません。"
fi
