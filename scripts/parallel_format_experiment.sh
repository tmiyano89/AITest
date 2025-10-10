#!/bin/bash

# @ai[2024-12-19 18:00] 並列フォーマット実験実行スクリプト
# 目的: 複数のAITestAppを並列実行してフォーマット実験を高速化
# 背景: 単一プロセスでは実行時間が非常に長いため、並列実行で効率化
# 意図: 各パターン・抽出方法・言語の組み合わせを独立したプロセスで実行

set -e

# プロジェクトルートに移動（スクリプトの場所を基準に）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 設定
TIMEOUT=300  # 各プロセスのタイムアウト（秒）
MAX_PARALLEL=6  # 最大並列実行数

# テスト実行ディレクトリを作成（タイムスタンプ付き）
TIMESTAMP=$(date +"%Y%m%d%H%M")
TEST_DIR="test_logs/test_${TIMESTAMP}"

# ディレクトリ作成
mkdir -p "$TEST_DIR"
# ステータス/メタ情報の初期化
echo "running" > "$TEST_DIR/.status"
date +"%Y-%m-%dT%H:%M:%S%z" > "$TEST_DIR/.started_at"
echo -n > "$TEST_DIR/pids.txt"

# 最新実行へのシンボリックリンクを更新（便利参照: test_logs/latest → $TEST_DIR）
mkdir -p test_logs
ln -sfn "$(basename "$TEST_DIR")" test_logs/latest 2>/dev/null || true

echo "🚀 並列フォーマット実験を開始"
echo "⏱️  タイムアウト: ${TIMEOUT}秒"
echo "🔄 最大並列数: ${MAX_PARALLEL}"
echo "📁 テスト実行ディレクトリ: $TEST_DIR"
echo "=========================================="

# パターン指定（コマンドライン引数から取得、デフォルトはchatのみ）
if [ $# -eq 0 ]; then
    PATTERNS=("chat")
else
    PATTERNS=("$@")
fi

# パターン名をAITestAppが期待する形式に変換する関数
convert_pattern() {
    case "$1" in
        "chat") echo "Chat" ;;
        "contract") echo "Contract" ;;
        "creditcard") echo "CreditCard" ;;
        "voicerecognition") echo "VoiceRecognition" ;;
        "passwordmanager") echo "PasswordManager" ;;
        *) 
            echo "❌ 無効なパターン: $1"
            echo "有効なパターン: chat, contract, creditcard, voicerecognition, passwordmanager"
            exit 1
            ;;
    esac
}

# パターン名を変換
declare -a converted_patterns=()
for pattern in "${PATTERNS[@]}"; do
    converted_patterns+=("$(convert_pattern "$pattern")")
done

# 実行する実験の組み合わせを生成（デフォルトはgenerableとjsonのみ）
declare -a experiments=()
for i in "${!PATTERNS[@]}"; do
    pattern="${PATTERNS[$i]}"
    converted_pattern="${converted_patterns[$i]}"
    experiments+=("generable_ja_${pattern}:${converted_pattern}")
    experiments+=("generable_en_${pattern}:${converted_pattern}")
    experiments+=("json_ja_${pattern}:${converted_pattern}")
    experiments+=("json_en_${pattern}:${converted_pattern}")
done

echo "📋 実行予定の実験数: ${#experiments[@]}"
echo "📋 パターン: ${PATTERNS[*]}"
echo "=========================================="

# エラー/割り込み時に実行中のプロセスを全て中断して失敗マークを記録
cleanup_and_exit() {
    echo "🛑 エラーまたは割り込みを検出しました。実行中のプロセスを中断します..."
    
    # 実行中のプロセスを全て中断
    echo "🛑 実行中のプロセスを確認中..."
    
    # 現在のプロセス管理配列から中断
    for pid in "${pids[@]}"; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "🛑 プロセス $pid を中断中..."
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    
    # pids.txtファイルからも中断（バックアップ）
    if [ -f "$TEST_DIR/pids.txt" ]; then
        while read -r pid experiment; do
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                echo "🛑 プロセス $pid ($experiment) を中断中..."
                kill -TERM "$pid" 2>/dev/null || true
            fi
        done < "$TEST_DIR/pids.txt"
    fi
    
    # 強制終了が必要な場合
    sleep 3
    for pid in "${pids[@]}"; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "🛑 プロセス $pid を強制終了中..."
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
    
    # 失敗マークを記録
    echo "failed" > "$TEST_DIR/.status"
    date +"%Y-%m-%dT%H:%M:%S%z" > "$TEST_DIR/.ended_at"
    echo "❌ 並列フォーマット実験が中断されました"
    exit 1
}

trap cleanup_and_exit ERR INT TERM

# 並列実行のための関数
run_experiment() {
    local experiment_with_converted=$1
    local log_file="$TEST_DIR/format_experiment_${experiment_with_converted%:*}.log"
    
    # 実験名を解析（method_language_pattern:converted_pattern形式）
    IFS=':' read -ra PARTS <<< "$experiment_with_converted"
    local experiment="${PARTS[0]}"
    local converted_pattern="${PARTS[1]}"
    
    IFS='_' read -ra PARTS <<< "$experiment"
    local method="${PARTS[0]}"
    local language="${PARTS[1]}"
    local pattern="${PARTS[2]}"
    
    echo "🔬 実験開始: $experiment" >&2
    echo "   📋 パターン: $pattern" >&2
    echo "   🔧 抽出方法: $method" >&2
    echo "   🌐 言語: $language" >&2
    echo "📝 ログファイル: $log_file" >&2
    
    # 特定のexperimentのみを実行（テストディレクトリとパターンを指定）
    timeout ${TIMEOUT}s swift run AITestApp --test-extraction-methods --experiment=${method}_${language} --pattern=${converted_pattern} --timeout=${TIMEOUT} --test-dir="$TEST_DIR" > "$log_file" 2>&1 &
    local timeout_pid=$!
    
    # 実際のAITestAppプロセスを取得（少し待ってから）
    sleep 1
    local actual_pid=$(pgrep -P $timeout_pid | head -1)
    if [ -n "$actual_pid" ]; then
        local pid=$actual_pid
    else
        local pid=$timeout_pid
    fi
    
    echo "🆔 プロセスID: $pid (timeout: $timeout_pid)" >&2
    echo "$pid $timeout_pid"  # 実際のPIDとtimeout PIDを返す
}

# プロセス管理用の配列
declare -a pids=()

# 実験を順次開始（最大並列数まで）
for experiment in "${experiments[@]}"; do
    # 最大並列数に達している場合は待機
    while [ ${#pids[@]} -ge $MAX_PARALLEL ]; do
        # 完了したプロセスをチェック
        for i in "${!pids[@]}"; do
            if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                echo "✅ 実験完了: ${experiments[$i]} (PID: ${pids[$i]})"
                unset pids[$i]
            fi
        done
        # 配列を再構築
        pids=("${pids[@]}")
        sleep 1
    done
    
    # 新しい実験を開始
    pid_info=$(run_experiment "$experiment")
    actual_pid=$(echo $pid_info | cut -d' ' -f1)
    timeout_pid=$(echo $pid_info | cut -d' ' -f2)
    pids+=($actual_pid)
    echo "$actual_pid $timeout_pid $experiment" >> "$TEST_DIR/pids.txt"
done

# 残りのプロセスが完了するまで待機
echo "⏳ 残りの実験の完了を待機中..."
for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        echo "⏳ プロセス $pid の完了を待機中..."
        
        # 1秒間隔でプロセスの終了を待機
        while kill -0 "$pid" 2>/dev/null; do
            sleep 1
        done
        
        echo "✅ プロセス $pid 完了"
    fi
done

# プロセス制御のアサーション: 各実験のlevel3_1.jsonファイルの存在確認
echo "🔍 プロセス制御のアサーション: 各実験の完了確認中..."
for experiment in "${experiments[@]}"; do
    experiment_name="${experiment%:*}"  # :converted_pattern の部分を除去
    level3_file="$TEST_DIR/${experiment_name}_level3_1.json"
    
    if [ ! -f "$level3_file" ]; then
        echo "⚠️  警告: 実験 $experiment_name の level3_1.json が見つかりません"
        echo "   期待されるファイル: $level3_file"
        echo "   プロセス制御ロジックに問題がある可能性があります"
        
        # 該当するプロセスがまだ実行中かチェック
        if [ -f "$TEST_DIR/pids.txt" ]; then
            while read -r actual_pid timeout_pid exp_name; do
                if [ "$exp_name" = "$experiment_name" ]; then
                    if kill -0 "$actual_pid" 2>/dev/null; then
                        echo "   → 実際のプロセス $actual_pid はまだ実行中です"
                    fi
                    if kill -0 "$timeout_pid" 2>/dev/null; then
                        echo "   → timeoutプロセス $timeout_pid はまだ実行中です"
                    fi
                fi
            done < "$TEST_DIR/pids.txt"
        fi
    else
        echo "✅ 実験 $experiment_name の level3_1.json が確認されました"
    fi
done

echo "=========================================="
echo "🎉 すべての実験が完了しました"

# テスト実行結果の確認
echo "📊 実行結果サマリー:"
for experiment in "${experiments[@]}"; do
    success_count=$(find "$TEST_DIR" -name "${experiment}_*.json" -not -name "*_error.json" | wc -l)
    error_count=$(find "$TEST_DIR" -name "${experiment}_*_error.json" | wc -l)
    echo "  $experiment: 成功 $success_count, エラー $error_count"
done

# 統合レポートの生成
echo "📄 統合レポートを生成中..."
python3 scripts/generate_combined_report.py "$TEST_DIR"

echo "✅ 並列フォーマット実験完了"
echo "📁 テスト実行結果: $TEST_DIR/"
echo "📁 統合レポート: $TEST_DIR/"

# 完了マーク
echo "completed" > "$TEST_DIR/.status"
date +"%Y-%m-%dT%H:%M:%S%z" > "$TEST_DIR/.ended_at"
