#!/bin/bash
# Robust script to start all Hydra nodes for all participants using npm/yaci workflow
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

HYDRA_NODE_PATH="$ROOT_DIR/$HYDRA_NODE"
if [ ! -x "$HYDRA_NODE_PATH" ]; then
    echo "hydra-node binary not found at $HYDRA_NODE_PATH"
    echo "Please run: npm run setup:hydra-node"
    exit 1
fi

PROTOCOL_PARAMS="$ROOT_DIR/config/hydra/protocol-parameters.json"
if [ ! -f "$PROTOCOL_PARAMS" ]; then
    echo "Error: protocol-parameters.json not found at $PROTOCOL_PARAMS. Please provide a valid file in config/hydra."
    exit 1
fi

start_hydra_node() {
    local NAME=$1
    local API_PORT=$2
    local PEER_PORT=$3
    local MONITORING_PORT=$4
    local ADVERTISED_HOST=$5

    echo "Starting Hydra node for participant: $NAME"
    local NODE_DIR="$ROOT_DIR/hydra-nodes/$NAME"
    local LOG_FILE="$NODE_DIR/logs/hydra-node.log"
    local PID_FILE="$NODE_DIR/hydra-node.pid"
    mkdir -p "$NODE_DIR/logs"

    HYDRA_KEY_DIR="$ROOT_DIR/$KEYS_DIR/$HYDRA_SUBDIR/$NAME"
    HYDRA_SK="$HYDRA_KEY_DIR/hydra.sk"
    CARDANO_SK="$ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/$NAME/payment.skey"

    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo " $NAME is already running with PID $PID"
            return
        fi
    fi

    PEERS=""
    for idx2 in "${!PARTICIPANTS[@]}"; do
        OTHER="${PARTICIPANTS[$idx2]}"
        if [ "$OTHER" != "$NAME" ]; then
            OTHER_PEER_PORT=$((PEER_BASE + idx2))
            PEERS="$PEERS --peer $HOST_DEFAULT:$OTHER_PEER_PORT"
        fi
    done

    ALL_KEYS=""
    for other in "${PARTICIPANTS[@]}"; do
        if [ "$other" != "$NAME" ]; then
            OTHER_HYDRA_VK="$ROOT_DIR/$KEYS_DIR/$HYDRA_SUBDIR/$other/hydra.vk"
            OTHER_CARDANO_VK="$ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/$other/payment.vkey"
            ALL_KEYS="$ALL_KEYS --hydra-verification-key $OTHER_HYDRA_VK"
            ALL_KEYS="$ALL_KEYS --cardano-verification-key $OTHER_CARDANO_VK"
        fi
    done

    nohup "$HYDRA_NODE_PATH" \
        --node-id "$NAME" \
        --api-host 0.0.0.0 \
        --api-port $API_PORT \
        --listen 0.0.0.0:$PEER_PORT \
        --advertise "${ADVERTISED_HOST}:$PEER_PORT" \
        --monitoring-port $MONITORING_PORT \
        --hydra-signing-key "$HYDRA_SK" \
        --cardano-signing-key "$CARDANO_SK" \
        $ALL_KEYS \
        --ledger-protocol-parameters "$PROTOCOL_PARAMS" \
        --testnet-magic "$TESTNET_MAGIC" \
        --node-socket "$YACI_NODE_SOCK_LOCAL_PATH" \
        --hydra-scripts-tx-id "$HYDRA_SCRIPTS_TX_ID" \
        --persistence-dir "$NODE_DIR/persistence" \
        $PEERS \
        > "$LOG_FILE" 2>&1 &

    local NODE_PID=$!
    echo $NODE_PID > "$PID_FILE"
    echo " Started (PID: $NODE_PID)"
    echo " API: http://localhost:$API_PORT"
    echo " Peer: $ADVERTISED_HOST:$PEER_PORT"
    echo " Logs: $LOG_FILE"
    echo ""
}

API_BASE=4000
PEER_BASE=5000
MON_BASE=6000
HOST_DEFAULT="127.0.0.1"

for idx in "${!PARTICIPANTS[@]}"; do
    NAME="${PARTICIPANTS[$idx]}"
    API_PORT=$((API_BASE + idx))
    PEER_PORT=$((PEER_BASE + idx))
    MON_PORT=$((MON_BASE + idx))
    HOST="$HOST_DEFAULT"
    start_hydra_node "$NAME" "$API_PORT" "$PEER_PORT" "$MON_PORT" "$HOST"
    if [ "$NAME" == "alice" ]; then
        echo "Waiting for Alice to initialize cluster..."
        sleep 5
    else
        sleep 5
    fi
    
    # Optionally, check if node started
    if [ -f "$ROOT_DIR/hydra-nodes/$NAME/hydra-node.pid" ]; then
        PID=$(cat "$ROOT_DIR/hydra-nodes/$NAME/hydra-node.pid")
        if ! ps -p $PID > /dev/null 2>&1; then
            echo "Hydra node for $NAME failed to start. Check logs: $ROOT_DIR/hydra-nodes/$NAME/logs/hydra-node.log"
        fi
    fi

done

echo "waiting for Hydra nodes to start..."
sleep 5

echo "Hydra nodes started successfully!"
echo "Verifying node status..."
echo ""
ALL_RUNNING=true

for idx in "${!PARTICIPANTS[@]}"; do
    NAME="${PARTICIPANTS[$idx]}"
    API_PORT=$((API_BASE + idx))
    if curl -s http://localhost:$API_PORT > /dev/null 2>&1; then
        echo "   $NAME is responding on port $API_PORT"
    else
        echo "   $NAME is NOT responding on port $API_PORT"
        echo "   Check logs: hydra-nodes/$NAME/logs/hydra-node.log"
        cat "$ROOT_DIR/hydra-nodes/$NAME/logs/hydra-node.log"
        ALL_RUNNING=false
    fi

done

echo ""
echo "--------------------------------------------"
if [ "$ALL_RUNNING" = true ]; then
    echo "✓ All Hydra nodes are running!"
    echo "--------------------------------------------"
    echo ""
    echo "API Endpoints:"
    for idx in "${!PARTICIPANTS[@]}"; do
        NAME="${PARTICIPANTS[$idx]}"
        API_PORT=$((API_BASE + idx))
        echo "  $NAME:  http://localhost:$API_PORT"
    done
    echo ""
    echo "To stop nodes: npm run hydra:stop"
else
    echo " Some nodes failed to start"
    echo "--------------------------------------------"
    echo ""
    echo "Check logs in hydra-nodes/*/logs/ for details"
    exit 1
fi
