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
    sed -i "s/^ARG MYSQL_SHELL_VERSION=.*/ARG MYSQL_SHELL_VERSION=$new_version/" docker/$type/Dockerfile || {
      echo "::warning::Failed to update version in docker/$type/Dockerfile, but continuing..."
    }
  else
    echo "dry run: docker/$type/Dockerfile 内の ARG MYSQL_SHELL_VERSION=$current_version を $new_version に更新"
  fi
  
  # README.md の更新
  if [[ "$type" == "innovation" ]]; then
    local match_pattern="Innovation Series ([0-9]\\.[0-9]\\.[x0-9])"
    local replace_value="Innovation Series (${major_version}.${minor_version}.x)"
    local tag_pattern="snickerjp\/docker-mysql-shell:${major_version}\\.[0-9]"
    local tag_replace="snickerjp\/docker-mysql-shell:${short_version}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
      # 各sedコマンドを個別にエラーハンドリング
      sed -i "s/$match_pattern/$replace_value/g" README.md || {
        echo "::warning::Failed to update Innovation Series version in README.md, but continuing..."
      }
      
      sed -i "s/$tag_pattern/$tag_replace/g" README.md || {
        echo "::warning::Failed to update Innovation image tag in README.md, but continuing..."
      }
    else
      echo "dry run: README.md 内の '$match_pattern' を '$replace_value' に更新"
      echo "dry run: README.md 内の '$tag_pattern' を '$tag_replace' に更新"
    fi
  else
    local match_pattern="LTS Series ([0-9]\\.[0-9]\\.[x0-9])"
    local replace_value="LTS Series (${major_version}.${minor_version}.x)"
    local tag_pattern="snickerjp\/docker-mysql-shell:${major_version}\\.[0-9]"
    local tag_replace="snickerjp\/docker-mysql-shell:${short_version}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
      sed -i "s/$match_pattern/$replace_value/g" README.md || {
        echo "::warning::Failed to update LTS Series version in README.md, but continuing..."
      }
      
      sed -i "s/$tag_pattern/$tag_replace/g" README.md || {
        echo "::warning::Failed to update LTS image tag in README.md, but continuing..."
      }
    else
      echo "dry run: README.md 内の '$match_pattern' を '$replace_value' に更新"
      echo "dry run: README.md 内の '$tag_pattern' を '$tag_replace' に更新"
    fi
  fi
  
  # ワークフローファイルの更新部分を削除
  # この部分を削除または以下のようにコメントアウト
  echo "::notice::ワークフローファイルは手動更新が必要です: .github/workflows/docker-*.yml 内の version: ${major_version}.[x] を version: ${short_version} に更新してください"
  
  # PR本文に変更内容を追加（整形された形式で）
  PR_BODY="${PR_BODY}

### ${type^} バージョン更新
* **${current_version}** → **${new_version}**
* ℹ️ ワークフローファイル(.github/workflows/docker-*.yml)は手動で更新する必要があります"
  
  # 更新が成功したか確認
  if [[ "$DRY_RUN" != "true" ]]; then
    if ! grep -q "ARG MYSQL_SHELL_VERSION=$new_version" docker/$type/Dockerfile; then
      echo "::warning::Version update in docker/$type/Dockerfile might have failed, but we'll continue..."
    fi
  fi
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

## ⚠️ 必要な手動アクション
1. このPRをマージする前に、ワークフローファイル(.github/workflows/docker-*.yml)を手動で更新してください
2. メジャー・マイナーバージョン番号の記述を正確に更新してください"

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
