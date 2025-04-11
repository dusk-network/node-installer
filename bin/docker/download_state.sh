#!/bin/bash
set -e

# Download the state 
source /opt/dusk/bin/download_state_inner.sh $@

replace_state_with_newly_downloaded

echo "Operation completed successfully."
