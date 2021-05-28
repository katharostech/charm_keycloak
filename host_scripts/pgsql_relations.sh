#!/bin/bash
set -e
# Source the helper functions
. functions.sh

lucky set-status -n pgsql-relation-status maintenance \
  "Configuring pgsql relation"

# Capture count of reql relations
rel_count=$(lucky relation list-ids -n db | wc -l)
log_this "Relation count: ${rel_count}"

# Do different stuff based on which hook is running
if [ ${LUCKY_HOOK} == "db-relation-joined" ]; then
  # We know that if we are in 'joined' hook that there will be
  # either 1 or more than 1 relations, but not less than 1.

  # When there is one and only one pgsql relation
  if [ ${rel_count} -eq 1 ]; then
    # Set the data
    set_pgsql_kv_data
  elif [ ${rel_count} -gt 1 ]; then
    # The operator has added more than 1 pgsql relation which is
    # not permitted for this charm...so let's tell them that and exit
    lucky set-status -n pgsql-relation-status blocked \
      "One and only one relation to PostgreSQL required; remove relation ${JUJU_RELATION}"
    exit 0
  fi
elif [ ${LUCKY_HOOK} == "db-relation-changed" ]; then
  # Set the data
  set_pgsql_kv_data
  # Run the update script without forking
  exec ./host_scripts/configure.sh 
elif [ ${LUCKY_HOOK} == "db-relation-departed" ]; then
  if [ ${rel_count} -eq 0 ]; then
    log_this "Removing the following pgsql KV data"
    delete_pgsql_kv_data
    lucky set-status -n pgsql-relation-status blocked \
      "One and only one relation to PostgreSQL required"
    exit 0
  fi
  # Run the update script
  exec ./host_scripts/configure.sh
elif [ ${LUCKY_HOOK} == "db-relation-broken" ]; then
  # In this context, the departing relation is still included in the output
  # Therefore we reduce by 1
  new_count=$((${rel_count} - 1))
  if [ ${new_count} -eq 0 ]; then
    log_this "Removing the following KV data: $(lucky kv get)"
    delete_pgsql_kv_data
    lucky set-status -n pgsql-relation-status blocked \
      "One and only one relation to PostgreSQL required; remove relation ${JUJU_RELATION}"
    exit 0
  fi
fi

lucky set-status -n pgsql-relation-status active