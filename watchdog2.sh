#!/bin/bash

DATASET="rpool/data/vm-100-disk-0"

CHECK_INTERVAL=10
TIMEOUT=120

TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

send_telegram() {
    local message="$1"

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" >/dev/null
}

get_used() {
    zfs list | awk -v ds="$DATASET" '$1 == ds {print $2}'
}

last_value=""
last_change_time=$(date +%s)

while true; do
    current_value=$(get_used)

    if [[ -z "$current_value" ]]; then
        echo "Dataset not found: $DATASET"
        sleep "$CHECK_INTERVAL"
        continue
    fi

    now=$(date +%s)

    if [[ -z "$last_value" ]]; then
        last_value="$current_value"
        last_change_time=$now
        echo "Init value: $current_value"

    elif [[ "$current_value" != "$last_value" ]]; then
        echo "Changed: $last_value -> $current_value"
        last_value="$current_value"
        last_change_time=$now

    else
        elapsed=$((now - last_change_time))
        echo "No change for ${elapsed}s (value: $current_value)"

        if (( elapsed >= TIMEOUT )); then
            send_telegram "⚠️ ZFS ALERT: $DATASET unchanged for ${TIMEOUT}s. Current value: $current_value"

            # предотвращаем спам уведомлений
            last_change_time=$now
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
