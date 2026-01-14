#!/bin/bash
# Start Hydra nodes using Docker for all participants defined in config.sh
set -e

# Source config and env
source "$(dirname "$0")/../utils/config-path.sh"
source "$CONFIG_PATH"

ENV_FILE="$ROOT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo ".env file not found. Please run: npm run start:devnet"
    exit 1
fi
source "$ENV_FILE"

PROTOCOL_PARAMS="config/hydra/protocol-parameters.json"
if [ ! -f "$ROOT_DIR/$PROTOCOL_PARAMS" ]; then
    echo "Error: protocol-parameters.json not found at $ROOT_DIR/$PROTOCOL_PARAMS. Please provide a valid file in config/hydra."
    exit 1
fi

# Path to the Docker wrapper
HYDRA_DOCKER_WRAPPER="$ROOT_DIR/$HYDRA_NODE"
if [ ! -x "$HYDRA_DOCKER_WRAPPER" ]; then
    echo "Error: Docker wrapper not found or not executable at $HYDRA_DOCKER_WRAPPER"
    exit 1
fi

echo "Starting Hydra nodes with Docker..."
echo "Hydra Version: $HYDRA_VERSION"
echo ""

# Optional: Check if Yaci DevKit is running
if ! curl -s http://localhost:${YACI_STORE_PORT}/api/v1/epochs/latest > /dev/null 2>&1; then
    echo "Warning: Yaci DevKit is not running!"
    echo "Please start it with: npm run start:devnet"
fi

start_hydra_node_docker() {
    local NAME=$1
    local API_PORT=$2
    local PEER_PORT=$3
    local MONITORING_PORT=$4
    local ADVERTISED_HOST=$5

    echo "Starting Hydra node for participant: $NAME"

    local NODE_DIR="hydra-nodes/$NAME"
    mkdir -p "$ROOT_DIR/$NODE_DIR/logs"
    mkdir -p "$ROOT_DIR/$NODE_DIR/persistence"

    HYDRA_KEY_DIR="$KEYS_DIR/$HYDRA_SUBDIR/$NAME"
    HYDRA_SK="$HYDRA_KEY_DIR/hydra.sk"
    CARDANO_SK="$KEYS_DIR/$PAYMENT_SUBDIR/$NAME/payment.skey"

    # Verify keys exist (use absolute paths for host check)
    if [ ! -f "$ROOT_DIR/$HYDRA_SK" ]; then
        echo "Error: Hydra signing key not found at $ROOT_DIR/$HYDRA_SK"
        exit 1
    fi
    if [ ! -f "$ROOT_DIR/$CARDANO_SK" ]; then
        echo "Error: Cardano signing key not found at $ROOT_DIR/$CARDANO_SK"
        exit 1
    fi

    # Check if container already running
    if docker ps --format '{{.Names}}' | grep -q "^hydra-$NAME$"; then
        echo " $NAME is already running"
        return
    fi

    # Build peers list - exclude self
    PEERS=""
    for idx2 in "${!PARTICIPANTS[@]}"; do
        OTHER="${PARTICIPANTS[$idx2]}"
        if [ "$OTHER" != "$NAME" ]; then
            OTHER_PEER_PORT=$((PEER_BASE + idx2))
            PEERS="$PEERS --peer $HOST_DEFAULT:$OTHER_PEER_PORT"
        fi
    done

    # Build verification keys list - exclude self
    ALL_KEYS=""
    for other in "${PARTICIPANTS[@]}"; do
        if [ "$other" != "$NAME" ]; then
            OTHER_HYDRA_VK="$KEYS_DIR/$HYDRA_SUBDIR/$other/hydra.vk"
            OTHER_CARDANO_VK="$KEYS_DIR/$PAYMENT_SUBDIR/$other/payment.vkey"
            
            # Verify other keys exist (use absolute paths for host check)
            if [ ! -f "$ROOT_DIR/$OTHER_HYDRA_VK" ]; then
                echo "Error: Verification key not found at $ROOT_DIR/$OTHER_HYDRA_VK"
                exit 1
            fi
            if [ ! -f "$ROOT_DIR/$OTHER_CARDANO_VK" ]; then
                echo "Error: Verification key not found at $ROOT_DIR/$OTHER_CARDANO_VK"
                exit 1
            fi
            
            ALL_KEYS="$ALL_KEYS --hydra-verification-key $OTHER_HYDRA_VK"
            ALL_KEYS="$ALL_KEYS --cardano-verification-key $OTHER_CARDANO_VK"
        fi
    done

    # Use the wrapper to start the node in background with proper Docker settings
    nohup "$HYDRA_DOCKER_WRAPPER" \
        --node-id "$NAME" \
        --api-host 0.0.0.0 \
        --api-port $API_PORT \
        --listen 0.0.0.0:$PEER_PORT \
        --advertise "$ADVERTISED_HOST:$PEER_PORT" \
        --monitoring-port $MONITORING_PORT \
        --hydra-signing-key "$HYDRA_SK" \
        --cardano-signing-key "$CARDANO_SK" \
        $ALL_KEYS \
        --ledger-protocol-parameters "$PROTOCOL_PARAMS" \
        --testnet-magic "$TESTNET_MAGIC" \
        --node-socket "yaci-socket/node.socket" \
        --hydra-scripts-tx-id "$HYDRA_SCRIPTS_TX_ID" \
        --persistence-dir "$NODE_DIR/persistence" \
        $PEERS \
        > "$ROOT_DIR/$NODE_DIR/logs/hydra-node.log" 2>&1 &

    local NODE_PID=$!
    echo $NODE_PID > "$ROOT_DIR/$NODE_DIR/hydra-node.pid"
    
    echo " Started (PID: $NODE_PID)"
    echo " API: http://localhost:$API_PORT"
    echo " Peer: $ADVERTISED_HOST:$PEER_PORT"
    echo " Logs: $ROOT_DIR/$NODE_DIR/logs/hydra-node.log"
    echo ""
}

API_BASE=4000
PEER_BASE=5000
MON_BASE=6000
HOST_DEFAULT="127.0.0.1"

# Start all participants dynamically
for idx in "${!PARTICIPANTS[@]}"; do
    NAME="${PARTICIPANTS[$idx]}"
    API_PORT=$((API_BASE + idx))
    PEER_PORT=$((PEER_BASE + idx))
    MON_PORT=$((MON_BASE + idx))
    HOST="$HOST_DEFAULT"
    
    start_hydra_node_docker "$NAME" "$API_PORT" "$PEER_PORT" "$MON_PORT" "$HOST"
    
    if [ "$NAME" == "${PARTICIPANTS[0]}" ]; then
        echo "Waiting for $NAME to initialize cluster..."
    fi
    sleep 5
done

echo "Waiting for Hydra nodes to start..."
sleep 5

echo "Hydra nodes started successfully!"
echo "Verifying node status..."
echo ""

ALL_RUNNING=true

for idx in "${!PARTICIPANTS[@]}"; do
    NAME="${PARTICIPANTS[$idx]}"
    API_PORT=$((API_BASE + idx))
    CONTAINER_NAME="hydra-$NAME"
    
    # Check if Docker container is running (Hydra uses WebSocket API, not HTTP)
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "   ✓ $NAME is running (container: $CONTAINER_NAME, API: ws://localhost:$API_PORT)"
    else
        echo "   ✗ $NAME container is NOT running"
        echo "   Check logs: $ROOT_DIR/hydra-nodes/$NAME/logs/hydra-node.log"
        echo "   Last 10 lines:"
        tail -10 "$ROOT_DIR/hydra-nodes/$NAME/logs/hydra-node.log" 2>&1 || true
        ALL_RUNNING=false
    fi
done

echo ""
echo "--------------------------------------------"

if [ "$ALL_RUNNING" = true ]; then
    echo "✓ All Hydra nodes are running!"
    echo "--------------------------------------------"
    echo ""
    echo "WebSocket API Endpoints:"
    for idx in "${!PARTICIPANTS[@]}"; do
        NAME="${PARTICIPANTS[$idx]}"
        API_PORT=$((API_BASE + idx))
        echo "  $NAME:  ws://localhost:$API_PORT"
    done
    echo ""
    echo "View logs: tail -f hydra-nodes/<name>/logs/hydra-node.log"
    echo "To stop nodes: npm run hydra:stop:docker"
else
    echo "⚠ Some nodes failed to start"
    echo "--------------------------------------------"
    echo ""
    echo "Check logs in hydra-nodes/*/logs/ for details"
    exit 1
fi