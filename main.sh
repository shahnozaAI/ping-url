#!/bin/bash

url="$1"
response_field="$2"
response_value="$3"
interval="$4"
timeout="$5"

# Map of common HTTP status codes to reason phrases
declare -A status_reasons
status_reasons=(
    [200]="OK"
    [400]="Bad Request"
    [401]="Unauthorized"
    [403]="Forbidden"
    [404]="Not Found"
    [500]="Internal Server Error"
    [503]="Service Unavailable"
)

END_TIME=$(($(date +%s) + $timeout))

echo "Starting pinging... from $(date +%s) until $END_TIME"
echo "Calling:=$url"
while [[ "$(date +%s)" -le "$END_TIME" ]]; do

    # Get the full response headers
    response_headers=$(curl -s -D - -o /dev/null "$url")
    # Extract the first line which contains the HTTP status code and reason phrase
    http_status_line=$(echo "$response_headers" | head -n 1)
    http_status_code=$(echo "$http_status_line" | awk '{print $2}')

    if [ -n "$http_status_code" ] && [ "$http_status_code" -eq 200 ]; then
        # Server is up, now get the response value
        received_value=$(curl -s "$url" | jq -r ".$response_field" 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo "Error parsing JSON from $url"
        elif [ "$received_value" == "$response_value" ]; then
            echo "Response $response_field matches with given value"
            exit 0
        else
            echo "Received $received_value expected $response_value"
        fi
    elif [ -z "$http_status_code" ]; then
        echo "No response from the server"
    else
        # Lookup the reason phrase from the status_reasons array
        reason_phrase=${status_reasons[$http_status_code]}
        echo "Server returned HTTP status $http_status_code ${reason_phrase:-Unknown Status}"
    fi

    sleep "$interval"
done

echo "Timeout reached without match"
exit 1
