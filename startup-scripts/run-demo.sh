#!/bin/bash

# Store the current working directory
ORIGINAL_PWD=$(pwd)

# Export the environment variables
export CONFIG_HOME=/Users/jjarae/source/demo/cdl/moderizing-brownfield-apps/config
export NEW_PROPS_LOCATION=$CONFIG_HOME/application-new.properties
export SPRING_CONFIG_LOCATION=$CONFIG_HOME/application.properties

# Start the applications in the background and save their PIDs
java -jar moderizing-brownfield-apps-0.0.1-SNAPSHOT.jar --server.port=8080 &
APP1_PID=$!

java -jar moderizing-brownfield-apps-0.0.1-SNAPSHOT.jar --server.port=8084 &
APP2_PID=$!

sleep 10

# Change directory to agent as things are referenced locally in the agent config
cd ../agent

# Retrieve role ID and secret ID
vault read -field=role_id auth/brownfield/role/brownfield-role/role-id > role-id.txt
vault write -f -field=secret_id auth/brownfield/role/brownfield-role/secret-id > secret-id.txt

# Start the Vault agent in the background and save its PID
vault agent -config vault-agent-config.hcl -log-level info &
VAULT_AGENT_PID=$!

# Define a cleanup function that kills the background processes and returns to the original directory
cleanup() {
    echo "Cleaning up..."
    kill $APP1_PID $APP2_PID $VAULT_AGENT_PID
    wait $APP1_PID $APP2_PID $VAULT_AGENT_PID
    echo "All background processes have been terminated."
    
    cd "$ORIGINAL_PWD"
}

# Set up a trap to call the cleanup function on SIGINT (Ctrl+C)
trap cleanup SIGINT

# Wait for all background processes to finish
wait $APP1_PID $APP2_PID $VAULT_AGENT_PID
