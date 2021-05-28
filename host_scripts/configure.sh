#!/bin/bash
set -e

# Source the helper functions
. functions.sh

# Set status to maintenance
lucky set-status -n config-status maintenance \
  "Updating Keycloak configuration"

# Load bash variables with configuration settings
kctag=$(lucky get-config KEYCLOAK_DOCKER_TAG)
if [ -z $kctag ]; then lucky set-status -n config-status blocked \
  "Config required: 'KEYCLOAK_DOCKER_TAG'"; exit 0; 
fi
kcpass=$(lucky get-config KEYCLOAK_PASSWORD)
if [ -z $kcpass ]; then lucky set-status -n config-status blocked \
  "Config required: 'KEYCLOAK_PASSWORD'"; exit 0; 
fi
kcuser=$(lucky get-config KEYCLOAK_USER)
if [ -z $kcuser ]; then lucky set-status -n config-status blocked \
  "Config required: 'KEYCLOAK_USER'"; exit 0; 
fi
kcurl=$(lucky get-config KEYCLOAK_FRONTEND_URL)
kcproxy=$(lucky get-config PROXY_ADDRESS_FORWARDING)

# Exit and block if the relation with the DB is not setup
if [ $(lucky relation list-ids -n db | wc -l) -ne 1 ]; then
  # Set config status back to active
  lucky set-status -n config-status active
  # Set relation status to blocked and exit
  lucky set-status -n pgsql-relation-status blocked \
    "One and only one relation to PostgreSQL required"
  exit 0
else
  lucky set-status -n pgsql-relation-status active
fi

# Set the container image
lucky container image set "jboss/keycloak:${kctag}"

# Load container env vars with config settings
lucky container env set \
  "KEYCLOAK_PASSWORD=${kcpass}" \
  "KEYCLOAK_USER=${kcuser}" \
  "DB_VENDOR=POSTGRES" \
  "DB_ADDR=$(lucky kv get pgsql_hostname)" \
  "DB_PORT=$(lucky kv get pgsql_port)" \
  "DB_DATABASE=$(lucky kv get pgsql_POSTGRES_DB)" \
  "DB_USER=$(lucky kv get pgsql_POSTGRES_USER)" \
  "DB_SCHEMA=public" \
  "DB_PASSWORD=$(lucky kv get pgsql_POSTGRES_PASSWORD)"

# Set optional variables
if [ -n ${kcurl} ]; then
  lucky container env set "KEYCLOAK_FRONTEND_URL=${kcurl}"
fi
if [ "${kcproxy}" == "true" ]; then
  lucky container env set "PROXY_ADDRESS_FORWARDING=true"
fi

# Set up the ports
set_container_port
bind_port=$(lucky kv get bind_port)

# Remove previously opened ports
lucky port close --all
lucky container port remove --all

# Bind the app port
lucky container port add "${bind_port}:8080"

# Open the port on the firewall
lucky port open ${bind_port}

lucky set-status -n config-status active
