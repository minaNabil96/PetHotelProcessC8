#!/bin/bash

# Keycloak 23+ uses /realms directly, not /auth/realms
KC_URL="http://localhost:8085"

echo "Waiting for Keycloak to be ready..."
until curl -s -f "$KC_URL/realms/camunda-platform/.well-known/openid-configuration" > /dev/null 2>&1; do
  echo -n "."
  sleep 5
done
echo " Keycloak is ready!"

# Function to get access token
get_token() {
  username=$1
  password=$2
  response=$(curl -s -X POST "$KC_URL/realms/camunda-platform/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$username" \
    -d "password=$password" \
    -d "grant_type=password" \
    -d "client_id=tasklist" \
    -d "client_secret=tasklist-secret")
  
  if echo "$response" | grep -q "access_token"; then
    echo "success"
  else
    echo "failed: $response"
  fi
}

echo ""
echo "Testing Administrator Access (admin/admin)..."
result=$(get_token "admin" "admin")
echo "Admin: $result"

echo ""
echo "Testing Supervisor Access (supervisor/camunda)..."
result=$(get_token "supervisor" "camunda")
echo "Supervisor: $result"

echo ""
echo "Testing Executor Access (executor/camunda)..."
result=$(get_token "executor" "camunda")
echo "Executor: $result"

echo ""
echo "Keycloak Admin Console: $KC_URL/admin"
echo "Tasklist: http://localhost:8082"
echo "Operate: http://localhost:8081"
