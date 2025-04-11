#!/bin/bash
set -e

source /opt/dusk/bin/download_state_inner.sh

service rusk stop

replace_state_with_newly_downloaded 

chown -R dusk:dusk /opt/dusk/

echo "Operation completed successfully."
