#!/bin/bash
# NOTE: The "shabang" above is required for the script to execute properly
# Exit non-zero is any command in the script exits non-zero
set -e

# Say that we are in the middle of installing
lucky set-status -n install-status maintenance 'Installing Keycloak.'

# Not really anything to do to install.

# Indicate we are done installing
lucky set-status -n install-status active
