# Getting Started

Ready for a local Cardano Hydra playground with multi-user automation?

Follow this step-by-step guide:

---

### 1. Install Dependencies

- [See installation guide](installation.md) for all platforms.
- Confirm Docker, Node.js, npm, and Yaci DevKit are ready.

### 2. Start Yaci DevNet

```sh
npm run start:devnet
```
In another terminal inside Yaci CLI:
```sh
create-node -o --start
```

### 3. Bridge the node.socket

Open a third terminal:
```sh
npm run bridge:node-socket
```
_Leave this process running._

---

### 4. Setup Directories

```sh
npm run setup:directories
```
Creates all required folders and base scripts.

---

### 5. Native or Docker? Choose Your Path

**A) Native/Binary:**  
```sh
npm run setup:cardano-cli
npm run setup:hydra-node
```
- Downloads Cardano/Hydra binaries.

**B) Docker:**  
```sh
npm run setup:docker:cardano-cli
npm run setup:docker:hydra-node
```
- Generates wrappers for Docker runs.

> _Do **not** mix scripts! Native wrappers do not use Docker, Docker scripts only launch containers._

---

### 6. Generate Participant Keys

```sh
npm run generate-keys
```
Check `keys/payment/{participant}/payment.addr` files for wallet addresses.

---

### 7. Top-up Wallets

For each participant, in the Yaci CLI, run:

```sh
topup <address> 100
```

Do this for all users.  
(If you run low on ADA, top up again—no issues!)

---

### 8. Publish Hydra Scripts

This initializes on-chain scripts for your workflow and generates the correct `.env`.

```sh
npm run publish-scripts

Or

npm run publish-scripts:docker
```
(Choose the docker or native script according to your setup.)

---

### 9. Start Hydra Head and TUI

**Start node:**
- Native: `npm run hydra:start`
- Docker: `npm run hydra:start:docker`

**Start TUI:**
- Native: `npm run tui:start -- 0`
- Docker: `npm run tui:start:docker -- 0`
- Use participant indices (0=alice, 1=bob, 2=carol...)

---

Now you can explore Hydra Head workflows—open, commit, fund, transact, validate L2 ops.
> Caveat: There’s a known close-head bug (see [Troubleshooting](troubleshooting.md)).  