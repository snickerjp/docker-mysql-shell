# !/bin/bash (実行権限を付与せずbashコマンドで実行されるため実際には使用されない)
# 厳格モードを設定
set -eu

# DRY_RUNがtrueでない場合のみ実行
if [[ "$DRY_RUN" != "true" ]]; then
  echo "::group::ワークフローファイル更新手順"
  echo "PR #xxx が作成されました。次に手動でワークフローファイルを更新してください。"
  echo "1. PRブランチをローカルにチェックアウト:"
  echo "   git fetch origin $BRANCH_NAME && git checkout $BRANCH_NAME"
  echo ""
  echo "2. 以下のコマンドでワークフローファイルを更新:"
  
  # Innovation更新の場合
  if [[ "$INNOVATION_UPDATE_NEEDED" == "true" ]]; then
    INNOVATION_MAJOR=$(echo "$LATEST_INNOVATION" | cut -d. -f1)
    INNOVATION_MINOR=$(echo "$LATEST_INNOVATION" | cut -d. -f2)
    INNOVATION_SHORT="${INNOVATION_MAJOR}.${INNOVATION_MINOR}"
    echo "   # Innovation更新コマンド:"
    echo "   find .github/workflows -name \"docker-*.yml\" -exec sed -i 's/version: ${INNOVATION_MAJOR}\\.x/version: ${INNOVATION_SHORT}/g' {} \\;"
  fi
  
  # LTS更新の場合
  if [[ "$LTS_UPDATE_NEEDED" == "true" ]]; then
    LTS_MAJOR=$(echo "$LATEST_LTS" | cut -d. -f1)
    LTS_MINOR=$(echo "$LATEST_LTS" | cut -d. -f2)
    LTS_SHORT="${LTS_MAJOR}.${LTS_MINOR}"
    echo "   # LTS更新コマンド:"
    echo "   find .github/workflows -name \"docker-*.yml\" -exec sed -i 's/version: ${LTS_MAJOR}\\.x/version: ${LTS_SHORT}/g' {} \\;"
  fi
  
  echo ""
  echo "3. 変更をコミット:"
  echo "   git add .github/workflows/"
  echo "   git commit -m \"Update workflow files for MySQL Shell versions\""
  echo ""
  echo "4. 変更をプッシュ:"
  echo "   git push origin $BRANCH_NAME"
  echo ""
  echo "これで既存のPRにワークフロー更新が追加されます。"
  echo "::endgroup::"
fi
