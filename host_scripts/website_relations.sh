#!/bin/bash
set -e
# Source the helper functions
. functions.sh

lucky set-status -n website-relation-status maintenance \
  "Configuring website-relation"

# Do different stuff based on which hook is running
if [ ${LUCKY_HOOK} == "website-relation-joined" ]; then
  # Set the listen address
  set_http_relation
elif [ ${LUCKY_HOOK} == "website-relation-changed" ]; then
  # Just re-set the listen_address
  set_http_relation
elif [ ${LUCKY_HOOK} == "website-relation-departed" ]; then
  remove_http_relation
elif [ ${LUCKY_HOOK} == "website-relation-broken" ]; then
  remove_http_relation  
fi

# Do this stuff regardless of which hook is running
lucky set-status -n website-relation-status active