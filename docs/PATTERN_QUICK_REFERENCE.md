# 実験パターン クイックリファレンス

## パターン一覧表

| パターンID | 表示名 | 指示タイプ | 例示 | ステップ | フォーマット | 用途 |
|------------|--------|------------|------|----------|------------|------|
| `chat_abs_gen` | Chat・抽象指示・@Generable | 抽象 | なし | 1 | gen | 基本性能測定 |
| `chat_abs-ex_gen` | Chat・抽象指示(例示)・@Generable | 抽象 | あり | 1 | gen | 例示効果測定 |
| `chat_strict_gen` | Chat・厳格指示・@Generable | 厳格 | なし | 1 | gen | 制約効果測定 |
| `chat_strict-ex_gen` | Chat・厳格指示(例示)・@Generable | 厳格 | あり | 1 | gen | 最高精度追求 |
| `chat_persona_gen` | Chat・人格指示・@Generable | 人格 | なし | 1 | gen | 人格効果測定 |
| `chat_persona-ex_gen` | Chat・人格指示(例示)・@Generable | 人格 | あり | 1 | gen | 人格+例示効果 |
| `chat_twosteps_gen` | Chat・2ステップ・@Generable | 厳格 | なし | 2 | gen | ステップ効果測定 |
| `chat_twosteps_json` | Chat・2ステップ・JSON | 厳格 | なし | 2 | json | フォーマット比較 |

## 命名規則

```
{pattern}_{algo}_{method}
```

- **pattern**: `chat`(チャット形式のテストデータ)
- **algo**: `abs`(抽象指示) / `strict`(厳格指示) / `persona`(人格指示) / `twosteps`(2ステップ) / `abs-ex`(抽象指示+例示) / `strict-ex`(厳格指示+例示) / `persona-ex`(人格指示+例示)
- **method**: `gen`(@Generable) / `json`(JSON) / `yaml`(YAML)

## よく使用されるパターン

### 基本性能測定
```bash
python3 scripts/run_experiments.py --patterns chat_abs_gen --runs 5
```

### 制約効果測定
```bash
python3 scripts/run_experiments.py --patterns chat_abs_gen chat_strict_gen --runs 3
```

### 例示効果測定
```bash
python3 scripts/run_experiments.py --patterns chat_strict_gen chat_strict-ex_gen --runs 3
```

### 人格効果測定
```bash
python3 scripts/run_experiments.py --patterns chat_strict_gen chat_persona_gen --runs 3
```

### ステップ効果測定
```bash
python3 scripts/run_experiments.py --patterns chat_strict_gen chat_twosteps_gen --runs 3
```

### フォーマット比較
```bash
python3 scripts/run_experiments.py --patterns chat_twosteps_gen chat_twosteps_json --runs 3
```

### 全パターン比較
```bash
python3 scripts/run_experiments.py --patterns chat_abs_gen chat_abs-ex_gen chat_strict_gen chat_strict-ex_gen chat_persona_gen chat_persona-ex_gen chat_twosteps_gen chat_twosteps_json --runs 1
```

## 評価指標

- **正規化スコア**: `(正解項目数 - 誤り項目数 - 余分項目数) / 期待項目数`
- **正解率**: `正解項目数 / 期待項目数`
- **精度**: `正解項目数 / (正解項目数 + 誤り項目数)`

## 推奨パターン

- **最高精度**: `PATTERN_STRICT-EX1-S1-gen`
- **バランス**: `PATTERN_STRICT-EX0-S1-gen`
- **基本性能**: `PATTERN_ABS-EX0-S1-gen`
- **複雑タスク**: `PATTERN_STRICT-EX0-S2-gen`
