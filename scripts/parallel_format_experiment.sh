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

echo "🚀 並列フォーマット実験を開始"
echo "⏱️  タイムアウト: ${TIMEOUT}秒"
echo "🔄 最大並列数: ${MAX_PARALLEL}"
echo "📁 テスト実行ディレクトリ: $TEST_DIR"
echo "=========================================="

# パターン指定（コマンドライン引数から取得、デフォルトは全パターン）
if [ $# -eq 0 ]; then
    PATTERNS=("chat" "contract" "creditcard" "voicerecognition" "passwordmanager")
else
    PATTERNS=("$@")
fi

# 実行する実験の組み合わせを生成
declare -a experiments=()
for pattern in "${PATTERNS[@]}"; do
    experiments+=("generable_ja_${pattern}")
    experiments+=("generable_en_${pattern}")
    experiments+=("json_ja_${pattern}")
    experiments+=("json_en_${pattern}")
    experiments+=("yaml_ja_${pattern}")
    experiments+=("yaml_en_${pattern}")
done

echo "📋 実行予定の実験数: ${#experiments[@]}"
echo "📋 パターン: ${PATTERNS[*]}"
echo "=========================================="

# 並列実行のための関数
run_experiment() {
    local experiment=$1
    local log_file="$TEST_DIR/format_experiment_${experiment}.log"
    
    # 実験名を解析（method_language_pattern形式）
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
    timeout ${TIMEOUT}s swift run AITestApp --test-extraction-methods --experiment=${method}_${language} --pattern=${pattern} --timeout=${TIMEOUT} --test-dir="$TEST_DIR" > "$log_file" 2>&1 &
    local pid=$!
    
    echo "🆔 プロセスID: $pid" >&2
    echo "$pid"  # PIDを標準出力として返す
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
    pid=$(run_experiment "$experiment")
    pids+=($pid)
done

# 残りのプロセスが完了するまで待機
echo "⏳ 残りの実験の完了を待機中..."
for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        echo "⏳ プロセス $pid の完了を待機中..."
        wait $pid 2>/dev/null || true
        echo "✅ プロセス $pid 完了"
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
