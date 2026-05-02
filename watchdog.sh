#!/bin/bash

FILE="$1"
BOT_TOKEN=""
CHAT_ID=""

if [ -z "$FILE" ]; then
  echo "Usage: $0 /path/to/file"
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "File not found!"
  exit 1
fi

last_size=$(stat -c%s "$FILE")

while true; do
  sleep 60

  current_size=$(stat -c%s "$FILE")

  if [ "$current_size" -eq "$last_size" ]; then
    MESSAGE="⚠️ File $FILE size has not changed in the last 60 seconds"

    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d chat_id="${CHAT_ID}" \
      -d text="${MESSAGE}"
  fi

  last_size=$current_size
done
