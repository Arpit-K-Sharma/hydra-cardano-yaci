# Setup
## Prerequisites
## Installation
# Setup & Usage

## Prerequisites

- Linux (recommended)
- [Node.js](https://nodejs.org/) >= 20.8.0
- [Docker](https://www.docker.com/) (for Docker-based workflow)
- curl, unzip, and git installed

## 1. Clone the Repository

```sh
git clone https://github.com/your-username/hydra-cardano-yaci.git
cd hydra-cardano-yaci
```

## 2. Install Prerequisites

```sh
npm run install:prerequisites
```

## 3. Configure Participants and Network

Edit `scripts/utils/config.sh` to set participant names, network magic, and versions as needed.

## 4. Key Generation

Generate all required Cardano and Hydra keys:

```sh
npm run generate-keys
```

## 5. Choose Your Workflow

### A. Native (Binary) Workflow

1. **Set up Cardano CLI and Hydra Node binaries:**
	```sh
	npm run setup:cardano-cli
	npm run setup:hydra-node
	```
2. **Start the devnet:**
	```sh
	npm run start:devnet
	```
3. **Start Hydra nodes:**
	```sh
	npm run hydra:start
	```
4. **(Optional) Start Hydra TUI:**
	```sh
	npm run tui:start -- <participant_index>
	# Example: npm run tui:start -- 0
	```
5. **Stop Hydra nodes:**
	```sh
	npm run hydra:stop
	```
6. **Stop the devnet:**
	```sh
	npm run stop:devnet
	```

### B. Docker Workflow

1. **Set up Cardano CLI and Hydra Node Docker wrappers:**
	```sh
	npm run setup:docker:cardano-cli
	npm run setup:docker:hydra-node
	```
2. **Start the devnet:**
	```sh
	npm run start:devnet
	```
3. **Start Hydra nodes (Docker):**
	```sh
	npm run hydra:start:docker
	```
4. **(Optional) Start Hydra TUI (Docker):**
	```sh
	npm run tui:start:docker -- <participant_index>
	# Example: npm run tui:start:docker -- 0
	```
5. **Stop Hydra nodes (Docker):**
	```sh
	npm run hydra:stop:docker
	```
6. **Stop the devnet:**
	```sh
	npm run stop:devnet
	```

## 6. Configuration Files


## 7. Useful Scripts & Commands


## 9. Troubleshooting & Known Issues

### PlutusV3 ValidationTagMismatch on Close (Conway/Protocol 10.x)

**Issue:**
When using Hydra 1.2.0 with Cardano node 10.1.4 (Conway era, Protocol 10.2) on a Yaci DevKit devnet, closing the Hydra head fails with a PlutusV3 ValidationTagMismatch error. The head opens successfully (Init → Commit → CollectCom → Open), but any attempt to close the head (via TUI or API) is rejected by the cardano-node with a script validation error.

**Error Example:**
```
TxValidationErrorInCardanoMode (ShelleyTxValidationError ShelleyBasedEraConway (ApplyTxError (ConwayUtxowFailure (UtxoFailure (UtxosFailure (ValidationTagMismatch (IsValid True) (FailedUnexpectedly (PlutusFailure ...
```

**Environment:**
- Hydra version: 1.2.0
- Cardano node version: 10.1.4 (Conway era)
- Protocol version: 10.2
- Network: Yaci DevKit (private devnet)

**Steps to Reproduce:**
1. Initialize a Hydra head with 3+ parties
2. Commit funds from all parties
3. Open the head (CollectCom transaction confirms, head reaches HeadIsOpen)
4. Attempt to close the head (TUI/API)
5. Observe Close transaction rejected with PlutusV3 script validation error

**Expected:** Close transaction should succeed and head should transition to HeadIsClosed.

**Actual:** Close transaction is rejected with ValidationTagMismatch or PPViewHashesDontMatch.

**Possible Cause:**
Protocol compatibility issue between Hydra 1.2.0 and Cardano Protocol 10.x (Conway). Yaci DevKit may use protocol parameters or behaviors that differ from official devnets.

**Workarounds & Recommendations:**
- Consider downgrading cardano-node to a version using Protocol 9.x if possible.
- Monitor for Hydra releases with explicit support for Protocol 10.x/Conway.
- Ensure protocol parameters in `config/hydra/protocol-parameters.json` match those exported from your running cardano-node.
- For updates and discussion, see the [Hydra GitHub issues](https://github.com/input-output-hk/hydra/issues) and [Yaci DevKit documentation](https://github.com/txpipe/yaci-devkit).

**Logs & Details:**
Check `hydra-nodes/<participant>/logs/hydra-node.log` and transaction CBOR for more information.

---
**General Tips:**
- Check logs in the `logs/` directory for errors.
- Ensure Docker is running and you have permission to use it.
- If binaries or wrappers are missing, rerun the setup scripts.
- For advanced configuration, review and edit `config.sh` and protocol parameters.
For troubleshooting, logs, and advanced usage, see the scripts in the `scripts/` directory and comments in `config.sh`.
