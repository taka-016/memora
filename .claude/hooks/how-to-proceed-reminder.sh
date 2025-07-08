#!/bin/bash
# 標準入力からJSONを読み取る
INPUT=$(cat)

# トランスクリプトを処理（.jsonl形式に対応）
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
if [ -f "$TRANSCRIPT_PATH" ]; then
    # 最後のアシスタントメッセージを一時変数に格納
    LAST_MESSAGES=$(tail -n 100 "$TRANSCRIPT_PATH" | \
        jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null | tail -n 1)
    # メッセージが存在し、かつHOW_TO_PROCEED_DISPLAYEDが含まれているかチェック
    if [ -n "$LAST_MESSAGES" ] && echo "$LAST_MESSAGES" | grep -q "HOW_TO_PROCEED_DISPLAYED"; then
        exit 0
    fi
fi

HOW_TO_PROCEED=$(cat << 'EOF'
CLAUDE.md記載の実装作業の進め方を復唱する。
復唱後、「HOW_TO_PROCEED_DISPLAYED」とだけ発言する。
EOF
)

ESCAPED_HOW_TO_PROCEED=$(echo "$HOW_TO_PROCEED" | jq -Rs .)
cat << EOF
{
  "decision": "block",
  "reason": $ESCAPED_HOW_TO_PROCEED
}
EOF
