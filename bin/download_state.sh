#!/bin/bash
set -e

STATE_LIST_URL="https://nodes.dusk.network/state/list"

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

# Function to display all published states
list_states() {
  echo "Fetching available states..."
  if ! curl -f -L -s "$STATE_LIST_URL"; then
    echo "Error: Failed to fetch the list of states."
    exit 1
  fi
}

# Function to check if a specific state exists
state_exists() {
  local state=$1
  while : ; do
    if curl -f -L -s "$STATE_LIST_URL" | grep -q "^$state$"; then
      return 0 # State exists
    else
      echo "State does not exist. Please enter a state from the list below:"
      list_states
      read -p "Enter a valid state number: " state
      # Update the state_number variable in the global scope
      state_number=$state
    fi
  done
}

# Function to get the latest state
get_latest_state() {
  curl -f -L -s "$STATE_LIST_URL" | tail -n 1
}

# Check if an argument is provided, otherwise use the fallback value (348211)
if [ "$1" = "--list" ]; then
  # List all possible states
  list_states
  exit 0
elif [ -n "$1" ]; then
  # User provided a specific state, check if it exists
  state_exists "$1"
  state_number=$1
else
  # No argument provided, use the latest state
  state_number=$(get_latest_state)
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
