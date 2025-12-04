#!/bin/bash
echo "Waiting for Keycloak to start..."
# In a real scenario, we might want to wait for the health check
# but for now we just print a message.
echo "Keycloak is configured to import the realm on startup."
echo "Users: admin, supervisor, executor"
echo "Passwords: admin (for admin), camunda (for others)"
