#!/bin/bash

url="$1"
response_field="$2"
response_value="$3"
interval="$4"
timeout="$5"

END_TIME=$(($(date +%s) + $timeout))

echo "Starting pinging... from $(date +%s) until $END_TIME"

while [[ "$(date +%s)" -le "$END_TIME" ]]; do
    response=$(curl -s "$url" || echo "")

    if [ "$response" != "" ]; then
        received_value=$(echo "$response" | jq -r ".$response_field")

        if [ "$received_value" == "$response_value" ]; then
            echo "Response $response_field matches with given value"
            exit 0
        else
            echo "Received $received_value expected $response_value"
        fi
    else
        echo "No response from the server"
    fi

    sleep "$interval"
done

echo "Timeout reached without match"
exit 1
