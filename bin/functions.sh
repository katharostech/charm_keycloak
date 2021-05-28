# function to send log messages to a file
log_this () {

  # create the logfile if needed
  if [ !${logfile_created} ]; then
    # gather some data
    now=$(date "+%Y%m%d-%H%M%S")
    logdir=/var/log/lucky
    script="${0}"
    scriptbase=$(basename -s ".sh" "${script}")
    logname="keycloak-${scriptbase}"
    logfile="${logdir}/${logname}-${now}.log"

    # create the dir if it doesn't exist
    mkdir -p ${logdir}
    touch ${logfile}
    # say we created it
    logfile_created=true
  fi

  # write message to log
  echo "${LUCKY_HOOK}::${1}" >> ${logfile}

  # clean up files older than 10 minutes
  find ${logdir} -name "${logname}-*" -mmin +10 -print | xargs rm -f
}

# Function to set the http interface relation
# Convention found here: https://discourse.jujucharms.com/t/interface-http/2392
set_pgsql_kv_data () {
  # Set the KV values based on pgsql relation data
  lucky kv set "pgsql_hostname=$(lucky relation get hostname)"
  lucky kv set "pgsql_port=$(lucky relation get port)"
  lucky kv set "pgsql_docker_tag=$(lucky relation get docker_tag)"
  lucky kv set "pgsql_POSTGRES_PASSWORD=$(lucky relation get POSTGRES_PASSWORD)"
  lucky kv set "pgsql_POSTGRES_USER=$(lucky relation get POSTGRES_USER)"
  lucky kv set "pgsql_POSTGRES_DB=$(lucky relation get POSTGRES_DB)"
}

# function to remove the listen_address
delete_pgsql_kv_data () {
  # Set the KV values to null string
  lucky kv set pgsql_hostname=""
  lucky kv set pgsql_port=""
  lucky kv set pgsql_docker_tag=""
  lucky kv set pgsql_POSTGRES_PASSWORD=""
  lucky kv set pgsql_POSTGRES_USER=""
  lucky kv set pgsql_POSTGRES_DB=""
}

# Function to set the http interface relation
# Convention found here: https://discourse.jujucharms.com/t/interface-http/2392
set_http_relation () {
  # Get the port from the KV store
  app_port=$(lucky kv get bind_port)

  # Publish the Keycloak listen address to the relation
  lucky relation set "hostname=$(lucky private-address)"
  lucky relation set "port=${app_port}"
}

# function to remove the listen_address
remove_http_relation () {
  log_this \
    "Removing relation value for 'hostname': $(lucky relation get hostname)"
  lucky relation set hostname=""
  log_this \
    "Removing relation value for 'port': $(lucky relation get port)"
  lucky relation set port=""
  log_this "hostname and port relation values removed"
}

# Get random port if not set
set_container_port () {
  if [ -z "$(lucky kv get bind_port)" ]; then
    # Use random function of Lucky
    rand_port=$(lucky random --available-port)
    lucky kv set bind_port="$rand_port"
  fi
}
