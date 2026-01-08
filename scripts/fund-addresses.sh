#!/bin/bash

# Fund participant addresses using Yaci CLI

set -e

# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

# Source .env if exists (for YACI_API_URL etc.)
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
fi

# Yaci API URLs from config or defaults
YACI_CLUSTER_API_URL="${YACI_CLUSTER_API:-http://localhost:$YACI_CLUSTER_API_PORT}"
YACI_STORE_API_URL="${YACI_STORE_API:-http://localhost:$YACI_STORE_PORT/api/v1}"

cd "$ROOT_DIR"

echo "--------------------------------------------"
echo "Funding Addresses Using Yaci DevKit API"
echo "--------------------------------------------"
echo ""

# Check if Yaci DevKit Cluster API is reachable (port 10000)
if ! curl -s "$YACI_CLUSTER_API_URL/local-cluster/api/admin/devnet" > /dev/null 2>&1; then
    echo "Error: Yaci DevKit not running."
    echo "  Cluster API not reachable at: $YACI_CLUSTER_API_URL"
    echo ""
    echo "Start the devnet with: npm run start:devnet"
    exit 1
fi

echo "✓ Yaci DevKit is running"
echo "  Cluster API: $YACI_CLUSTER_API_URL"
echo "  Store API:   $YACI_STORE_API_URL"
echo ""

# Use API endpoints from config.sh (Cluster API for topup, can use either for UTXOs)
TOPUP_API="$YACI_TOPUP_API"
UTXOS_API="$YACI_UTXOS_API"

# Function to fund an address using Yaci DevKit REST API
fund_address() {
    local NAME=$1
    local ADDR=$2
    local AMOUNT=$3

    echo "Funding $NAME ($ADDR)..."

    RESPONSE=$(curl -s -X POST "$TOPUP_API" \
        -H "Content-Type: application/json" \
        -d "{\"address\": \"$ADDR\", \"adaAmount\": $AMOUNT}")

    if echo "$RESPONSE" | jq -e '.status == true' >/dev/null 2>&1; then
        echo "  ✓ Topup successful: $AMOUNT ADA"
    else
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message // .error // "Unknown error"' 2>/dev/null || echo "API unavailable")
        echo "  ✗ Topup failed: $ERROR_MSG"
    fi
    echo ""
}

# Default funding amount (in ADA)
FUND_AMOUNT="${FUND_AMOUNT:-10000}"

# Fund all participants
for NAME in "${PARTICIPANTS[@]}"; do
    ADDR_FILE="$KEYS_DIR/$PAYMENT_SUBDIR/$NAME/payment.addr"
    
    if [ ! -f "$ADDR_FILE" ]; then
        echo "Warning: Address file not found for $NAME at $ADDR_FILE"
        echo "  Run ./scripts/generate-keys.sh first."
        continue
    fi
    
    ADDR=$(cat "$ADDR_FILE")
    fund_address "$NAME" "$ADDR" "$FUND_AMOUNT"
    sleep 3
done

echo "Waiting for confirmations (15 seconds)..."
sleep 15

# Verify balances using official Yaci API
echo ""
echo "Verifying balances..."
API_AVAILABLE=false

for NAME in "${PARTICIPANTS[@]}"; do
    ADDR_FILE="$KEYS_DIR/$PAYMENT_SUBDIR/$NAME/payment.addr"
    
    if [ ! -f "$ADDR_FILE" ]; then
        continue
    fi
    
    ADDR=$(cat "$ADDR_FILE")
    
    # Use official Yaci API: /local-cluster/api/addresses/{address}/utxos
    UTXOS=$(curl -s "$UTXOS_API/$ADDR/utxos?page=1" 2>/dev/null)
    
    if [ -n "$UTXOS" ] && [ "$UTXOS" != "[]" ]; then
        BALANCE=$(echo "$UTXOS" | jq '[.[].amount[] | select(.unit == "lovelace") | .quantity] | add' 2>/dev/null || echo "0")
        
        if [ -n "$BALANCE" ] && [ "$BALANCE" != "0" ] && [ "$BALANCE" != "null" ]; then
            ADA=$(echo "scale=2; ${BALANCE} / 1000000" | bc 2>/dev/null || echo "N/A")
            echo "  $NAME: $ADA ADA"
            API_AVAILABLE=true
        else
            echo "  $NAME: 0 ADA (no UTXOs found)"
        fi
    else
        echo "  $NAME: 0 ADA (no UTXOs found)"
    fi
done

if [ "$API_AVAILABLE" = false ]; then
    echo ""
    echo "⚠ No balances found or API unavailable."
    echo "  Check Yaci Viewer at: http://localhost:5173"
fi

echo ""
echo "✓ Done!"
