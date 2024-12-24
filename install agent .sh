#!/bin/bash

# Dynamic Values (to be passed during installation)
API_ENDPOINT="https://10.0.34.181:8000/api/v1/agents/"
OMEGA_UID="310b297d-29c9-4407-9506-e7bc5e7fbf46"
AGENT_NAME="CustomAgent-$(hostname)"
PORT="3000"

# Running the Helm install command with dynamic values
echo "Running Helm install with dynamic values..."
helm install my-monitoring-stack ./my-monitoring-chart -n alloy \
  --set agentRegistration.apiEndpoint="$API_ENDPOINT" \
  --set agentRegistration.omegaUid="$OMEGA_UID" \
  --set agentRegistration.agentNamePrefix="$AGENT_NAME" \
  --set agentRegistration.port="$PORT" \
  -f values.yaml


#!/bin/bash

# Dynamic Values for registration
API_ENDPOINT=$1
OMEGA_UID=$2
AGENT_NAME=$3
PORT=$4

HOST_IP=$(hostname -I | awk '{print $1}')
AGENT_NAME="${AGENT_NAME}-$(hostname)"

# Send HTTP request to register the agent
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating new agent..."

response=$(curl -k -v -s -w "\n%{http_code}" -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d '{
        "host_name": "'"$HOSTNAME"'",
        "ip_port": "'"$HOST_IP:$PORT"'",
        "keycloak_id": "'"$OMEGA_UID"'",
        "agent_name": "'"$AGENT_NAME"'",
        "status": "Active"
    }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "$(date '+%Y-%m-%d %H:%M:%S') - Response Code: $http_code"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Response Body: $body"

if [[ "$http_code" == "201" ]]; then
    echo "Agent created successfully."
elif [[ "$body" == *"UNIQUE constraint failed"* ]]; then
    echo "ERROR: IP:PORT combination already exists"
else
    echo "Agent creation failed. Check the logs for details."
fi
