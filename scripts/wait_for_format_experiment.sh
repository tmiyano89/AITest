#!/bin/bash

# @ai[2025-10-07 18:10] フォーマット実験完了待機スクリプト
# 目的: バックグラウンドで起動した parallel_format_experiment.sh の完了/失敗/タイムアウトを厳密に判定する
# 意図: すべてのログ出力が揃う前に集計処理へ進まないようにするためのガード

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

LATEST_LINK="test_logs/latest"
TIMEOUT_SECS="${1:-900}"
SLEEP_SECS=2

# 非同期ワンショット判定モード
# 使い方: ./scripts/wait_for_format_experiment.sh --once
# 返却コード:
#   0: completed
#   1: running（継続中）
#   2: failed
#   3: 異常（PID終了済みだがstatus未設定など）
#   4: latest無し/テストディレクトリ無し
if [ "${1:-}" = "--once" ]; then
  if [ ! -L "$LATEST_LINK" ]; then
    echo "running: latest link not found" >&2
    exit 4
  fi
  TEST_DIR="test_logs/$(readlink "$LATEST_LINK")"
  STATUS_FILE="$TEST_DIR/.status"
  PIDS_FILE="$TEST_DIR/pids.txt"
  if [ ! -d "$TEST_DIR" ]; then
    echo "running: test dir missing" >&2
    exit 4
  fi
  status="running"
  if [ -f "$STATUS_FILE" ]; then
    status=$(cat "$STATUS_FILE" || true)
  fi
  if [ "$status" = "completed" ]; then
    echo "completed: $TEST_DIR"
    exit 0
  fi
  if [ "$status" = "failed" ]; then
    echo "failed: $TEST_DIR" >&2
    exit 2
  fi
  if [ -f "$PIDS_FILE" ]; then
    any_alive=false
    while read -r pid rest; do
      if kill -0 "$pid" 2>/dev/null; then
        any_alive=true
        break
      fi
    done < "$PIDS_FILE"
    if [ "$any_alive" = false ]; then
      echo "abnormal: no alive pids and no final status" >&2
      exit 3
    fi
  fi
  echo "running: $TEST_DIR"
  exit 1
fi

if [ ! -L "$LATEST_LINK" ]; then
  echo "ERROR: $LATEST_LINK が存在しません。実行を開始してから呼び出してください。" >&2
  exit 1
fi

TEST_DIR="test_logs/$(readlink "$LATEST_LINK")"
STATUS_FILE="$TEST_DIR/.status"
PIDS_FILE="$TEST_DIR/pids.txt"

if [ ! -d "$TEST_DIR" ]; then
  echo "ERROR: テストディレクトリが存在しません: $TEST_DIR" >&2
  exit 1
fi

echo "⏳ 実行完了待機を開始: $TEST_DIR (timeout=${TIMEOUT_SECS}s)"

start_ts=$(date +%s)
while true; do
  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))

  # ステータスファイル判定
  if [ -f "$STATUS_FILE" ]; then
    status=$(cat "$STATUS_FILE" || true)
    if [ "$status" = "completed" ]; then
      echo "✅ 実験完了を検知: $TEST_DIR"
      break
    elif [ "$status" = "failed" ]; then
      echo "❌ 実験失敗を検知: $TEST_DIR" >&2
      exit 2
    fi
  fi

  # プロセス監視: pids.txtがあれば生存確認
  if [ -f "$PIDS_FILE" ]; then
    any_alive=false
    while read -r pid rest; do
      if kill -0 "$pid" 2>/dev/null; then
        any_alive=true
        break
      fi
    done < "$PIDS_FILE"

    if [ "$any_alive" = false ] && [ -f "$STATUS_FILE" ]; then
      # プロセスは生存していないのに completed/failed でなければ異常
      echo "❓ すべてのPIDが終了していますが status=${status:-unknown} のため異常終了扱い" >&2
      exit 3
    fi
  fi

  if [ $elapsed -ge $TIMEOUT_SECS ]; then
    echo "⏱️ タイムアウト(${TIMEOUT_SECS}s)に達しました" >&2
    exit 124
  fi
  sleep "$SLEEP_SECS"
done

# オプション: 期待ログの概数チェック（存在すればOK、厳密な件数条件は要件次第）
log_count=$(find "$TEST_DIR" -maxdepth 1 -name "*.log" | wc -l | tr -d ' ')
if [ "$log_count" -eq 0 ]; then
  echo "⚠️ ログファイルが見つかりません: $TEST_DIR" >&2
fi

echo "📄 統合レポート: $TEST_DIR/parallel_format_experiment_report.html"
if [ ! -f "$TEST_DIR/parallel_format_experiment_report.html" ]; then
  echo "⚠️ 統合レポートが未生成です。必要に応じて再生成してください。" >&2
fi

exit 0


