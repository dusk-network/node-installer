#!/bin/bash
set -e

RUSK_CONFIG_FILE="/opt/dusk/conf/rusk.toml"
NETWORK=""
LIST_STATES=0
STATE_NUMBER=""

usage() {
  echo "Usage: $0 [--network mainnet|testnet] [--list] [state_number]"
}

detect_network() {
  if [ -f "$RUSK_CONFIG_FILE" ]; then
    case "$(grep -E "^kadcast_id" "$RUSK_CONFIG_FILE" | head -n 1 | awk -F= '{print $2}' | tr -d "[:space:]")" in
      0x1)
        printf '%s\n' "mainnet"
        return 0
        ;;
      0x2)
        printf '%s\n' "testnet"
        return 0
        ;;
    esac
  fi

  return 1
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --network)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: --network requires a value."
        usage
        exit 1
      fi
      NETWORK="$2"
      shift 2
      ;;
    --list)
      LIST_STATES=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$STATE_NUMBER" ]]; then
        echo "Error: Unexpected argument '$1'."
        usage
        exit 1
      fi
      STATE_NUMBER="$1"
      shift
      ;;
  esac
done

if [[ -z "$NETWORK" ]]; then
  if ! NETWORK=$(detect_network); then
    echo "Error: Failed to detect network from $RUSK_CONFIG_FILE. Use --network mainnet|testnet."
    exit 1
  fi
fi

case "$NETWORK" in
  mainnet)
    STATE_BASE_URL="https://nodes.dusk.network/state"
    ;;
  testnet)
    STATE_BASE_URL="https://testnet.nodes.dusk.network/state"
    ;;
  *)
    echo "Error: Unsupported network '$NETWORK'."
    exit 1
    ;;
esac

STATE_LIST_URL="$STATE_BASE_URL/list"

# Function to display a warning message
display_warning() {
  echo "Selected network: $NETWORK"
  echo "WARNING: This operation will STOP your node and REPLACE the current state with a new one."
  
  while : ; do
    read -r -p "Are you sure you want to proceed? [y/N]: " choice
    choice=${choice,,}  # to lowercase

    case "$choice" in
      y|yes)
        echo "Proceeding with state replacement..."
        return 0
        ;;
      n|no|"")
        echo "Operation aborted by user."
        exit 1
        ;;
      *)
        echo "Please answer 'y' or 'n'."
        ;;
    esac
  done
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

if [[ "$LIST_STATES" == "1" ]]; then
  # List all possible states
  list_states
  exit 0
elif [[ -n "$STATE_NUMBER" ]]; then
  # User provided a specific state, check if it exists
  state_number=$STATE_NUMBER
  state_exists "$STATE_NUMBER"
else
  # No argument provided, use the latest state
  state_number=$(get_latest_state)
fi

# Display warning and get user confirmation
display_warning

# Download the file
STATE_URL="$STATE_BASE_URL/$state_number"

STATE_ARCHIVE=$(mktemp --suffix=.tar.gz /tmp/dusk-state.XXXXXX)
echo "Downloading state $state_number from $STATE_URL to $STATE_ARCHIVE..."
cleanup_state_archive() {
  rm -f "$STATE_ARCHIVE"
}
trap cleanup_state_archive EXIT

if ! curl -f -L -sS -o "$STATE_ARCHIVE" "$STATE_URL"; then
  echo "Error: Failed to download state $state_number from $STATE_URL."
  exit 1
fi

service rusk stop

rm -rf /opt/dusk/rusk/state
rm -rf /opt/dusk/rusk/chain.db
if ! tar -xvf "$STATE_ARCHIVE" -C /opt/dusk/rusk/; then
  echo "Error: Failed to extract downloaded state archive."
  exit 1
fi
chown -R dusk:dusk /opt/dusk/

echo "Operation completed successfully."
