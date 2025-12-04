#!/bin/bash

echo "Generating .env file for Codespaces..."

# Default to localhost if not in Codespaces
KEYCLOAK_HOST="localhost"
OPERATE_HOST="localhost"
TASKLIST_HOST="localhost"
IDENTITY_HOST="localhost"

# Check if running in Codespaces
if [ -n "$CODESPACE_NAME" ] && [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
  echo "Detected Codespaces environment."
  KEYCLOAK_HOST="${CODESPACE_NAME}-8085.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  OPERATE_HOST="${CODESPACE_NAME}-8081.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  TASKLIST_HOST="${CODESPACE_NAME}-8082.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  IDENTITY_HOST="${CODESPACE_NAME}-8084.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
fi

# Write to .env file
cat <<EOF > .env
CAMUNDA_KEYCLOAK_URL_EXTERNAL=https://${KEYCLOAK_HOST}/auth
CAMUNDA_OPERATE_URL_EXTERNAL=https://${OPERATE_HOST}
CAMUNDA_TASKLIST_URL_EXTERNAL=https://${TASKLIST_HOST}
CAMUNDA_IDENTITY_URL_EXTERNAL=https://${IDENTITY_HOST}
EOF

echo ".env file created with the following values:"
cat .env

echo "Starting Docker Compose..."
docker-compose down -v
docker-compose up -d
