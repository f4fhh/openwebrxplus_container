#!/bin/bash
set -euo pipefail

if [[ ! -z "${OPENWEBRX_ADMIN_USER:-}" ]] && [[ ! -z "${OPENWEBRX_ADMIN_PASSWORD:-}" ]] ; then
  if ! openwebrx admin --silent hasuser "${OPENWEBRX_ADMIN_USER}" ; then
    OWRX_PASSWORD="${OPENWEBRX_ADMIN_PASSWORD}" openwebrx admin --noninteractive adduser "${OPENWEBRX_ADMIN_USER}"
  fi
fi

_term() {
  echo "Caught signal!" 
  kill -TERM "$child" 2>/dev/null
}
    
trap _term SIGTERM SIGINT

sdrplay_apiService &
sleep 1
codecserver &
sleep 1
openwebrx $@ &

child=$! 
wait "$child"