#!/bin/bash

set -e

AVAILABLE_STATES=(409123 408251 407159 404345 379502)
LATEST_STATE=${AVAILABLE_STATES[0]}

# Function to display a warning message
display_warning() {
  echo "WARNING: This operation will STOP your node and REPLACE the current state with a new one."
  read -p "Are you sure you want to proceed? (Y/n): " choice

  case "$choice" in
    Y )
      return 0  # User confirmed, proceed
      ;;
    * )
      echo "Operation aborted."
      exit 1  # User declined, exit script
      ;;
  esac
}

list_states() {
  echo "Available states:"
  for state in "${AVAILABLE_STATES[@]}"; do
    echo "- $state"
  done
  exit 0
}

# Check if an argument is provided, otherwise use the fallback value (348211)
if [ $# -eq 0 ]; then
  # No argument provided, use the latest state
  state_number=$LATEST_STATE
elif [ "$1" = "--list" ]; then
  # User requested to list all possible states
  list_states
else
  # User provided a specific state
  state_number=$1
  if ! [[ " ${AVAILABLE_STATES[*]} " =~ " ${state_number} " ]]; then
    echo "Error: State $state_number is not available."
    echo "The following states are available:"
    list_states
    exit 1
  fi
fi

# Display warning and get user confirmation
display_warning

# Download the file
STATE_URL="https://nodes.dusk.network/state/$state_number"
echo "Downloading state $state_number from $STATE_URL..."

if ! curl -f -so  /tmp/state.tar.gz -L "$STATE_URL"; then
  echo "Error: Download failed. Exiting."
  exit 1
fi

service rusk stop

rm -rf /opt/dusk/rusk/state
rm -rf /opt/dusk/rusk/chain.db
tar -xvf /tmp/state.tar.gz -C /opt/dusk/rusk/
chown -R dusk:dusk /opt/dusk/

echo "Operation completed successfully."
