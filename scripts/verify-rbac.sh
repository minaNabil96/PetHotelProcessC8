#!/bin/bash

# Determine Keycloak URL based on environment
# In Codespaces devcontainer (zeebe service), we should use the service name 'keycloak'
# If running on host, we use 'localhost'
if ping -c 1 keycloak &> /dev/null; then
  KC_HOST="keycloak"
  KC_PORT="8080"
  echo "Detected internal network, using Keycloak at http://$KC_HOST:$KC_PORT/auth"
else
  KC_HOST="localhost"
  KC_PORT="8085"
  echo "Using Keycloak at http://$KC_HOST:$KC_PORT/auth"
fi

KC_URL="http://$KC_HOST:$KC_PORT/auth"

# Function to wait for Keycloak
wait_for_keycloak() {
  echo "Waiting for Keycloak to be ready..."
  until curl -s -f "$KC_URL/realms/camunda-platform/.well-known/openid-configuration" > /dev/null; do
    echo -n "."
    sleep 5
  done
  echo " Keycloak is ready!"
}

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
    echo "$response" | jq -r '.access_token'
  else
    echo "null"
    echo "Authentication failed. Response from Keycloak:" >&2
    echo "$response" >&2
  fi
}

wait_for_keycloak

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
