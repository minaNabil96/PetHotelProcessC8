#!/bin/bash

# Function to get access token
get_token() {
  username=$1
  password=$2
  curl -s -X POST "http://localhost:8085/auth/realms/camunda-platform/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$username" \
    -d "password=$password" \
    -d "grant_type=password" \
    -d "client_id=tasklist" \
    -d "client_secret=tasklist-secret" | jq -r '.access_token'
}

echo "Testing Administrator Access..."
ADMIN_TOKEN=$(get_token "admin" "admin")
if [ "$ADMIN_TOKEN" != "null" ]; then
  echo "Admin authentication successful."
else
  echo "Admin authentication failed."
fi

echo "Testing Supervisor Access..."
SUPERVISOR_TOKEN=$(get_token "supervisor" "camunda")
if [ "$SUPERVISOR_TOKEN" != "null" ]; then
  echo "Supervisor authentication successful."
else
  echo "Supervisor authentication failed."
fi

echo "Testing Executor Access..."
EXECUTOR_TOKEN=$(get_token "executor" "camunda")
if [ "$EXECUTOR_TOKEN" != "null" ]; then
  echo "Executor authentication successful."
else
  echo "Executor authentication failed."
fi

# Example API call to Tasklist (requires Tasklist to be running and accessible)
# echo "Fetching tasks as Executor..."
# curl -s -X POST "http://localhost:8082/graphql" \
#   -H "Authorization: Bearer $EXECUTOR_TOKEN" \
#   -H "Content-Type: application/json" \
#   -d '{"query": "{ tasks { id name } }"}'
