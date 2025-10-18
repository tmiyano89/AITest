curl -s http://182.171.83.172/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer EMPTY" \
  -d '{
    "model": "openai/gpt-oss-20b",
    "messages": [
      {"role":"user", "content":"テキストデータからアカウントに関する情報を抽出し、以下のJSON形式で回答してください。\n\n重要: 回答は必ず有効なJSON形式で出力してください。説明文やコメントは含めず、JSONオブジェクトのみを出力してくださ い。\n\n制約:\n- 抽出できなかった項目はnullを設定すること\n- 備忘録(note)には、アカウントの用途や注意事項などの補足情報を要約して記載すること\n- 鍵情報(authKey)は、先頭行(BEGIN)と末尾行(END)を含む完全な文字列で出力すること\n- ポート番号は1-65535の範囲内の整数で出力すること\n- 信頼度(confidence)は0.0-1.0の範囲で自己評価すること\n\n必須のJSON形式（こ の形式に厳密に従ってください）:\n{\n  \"title\": \"サービス名、アプリ名、サイト名\",\n  \"userID\": \"メールアドレス 、ユーザー名、ログインID\",\n  \"password\": \"パスワード文字列\",\n  \"url\": \"ログインページURL、サービスURL\",\n  \"note\": \"備考、メモ、追加情報\",\n  \"host\": \"ホスト名またはIPアドレス\",\n  \"port\": ポート番号,\n  \"authKey\": \"認証キー（SSH秘密鍵など）\",\n  \"confidence\": 信頼度\n}\n\n注意: 上記のJSON形式に厳密に従い、説明文やコメントは一切含めず、JSONオブジェクトのみを出力してください。\n\nテキストデータ:\nHey! 新しいサーバーのアカウント情報を送る ね\n\nAWS EC2にログインするには\nアカウントはadmin/SecurePass18329です\nでアクセスできるよ\n\nよろしく！"}
    ],
    "max_tokens": 4096,
    "temperature": 1.0,"top_p": 1.0
  }'