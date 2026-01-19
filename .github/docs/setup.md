# ⏩ Getting Started / Setup

Follow these steps to launch your own Hydra Head devnet:

1. **Install prerequisites**  
   [Installation Guide](installation.md)  
   _Node.js, Docker, git, curl, Yaci DevKit_

2. **Start Cardano Devnet**  
   - `npm run start:devnet`
   - In Yaci CLI: `create-node -o --start`

3. **Bridge the node.socket**  
   - In a separate terminal: `npm run bridge:node-socket`
   - _Leave this running!_

4. **Setup directories**  
   - `npm run setup:directories`
   - _Creates all structure needed._

5. **Choose your workflow**  
   - **Native**:  
     `npm run setup:cardano-cli`  
     `npm run setup:hydra-node`  
     `npm run setup:hydra-tui`
   - **Docker**:  
     `npm run setup:docker:cardano-cli`  
     `npm run setup:docker:hydra-node`  
     `npm run setup:docker:hydra-tui`

6. **Generate keys**  
   - `npm run generate-keys`
   - _Check `keys/payment/{participant}/payment.addr` files for addresses._

7. **Top-up wallets with Yaci CLI**  
   - Example: `topup <address> 100`

8. **Publish Hydra scripts**  
   - `npm run publish-hydra-scripts`

9. **Start HYDRA node & TUI**  
   - Node: `npm run hydra:start` or `npm run hydra:start:docker`
   - TUI: `npm run tui:start -- 0` (or Docker)

---

> Trouble? Check our [Troubleshooting Guide](troubleshooting.md)

---

## Visual Example (Style with emoji, TOC bullets, fenced steps)

```
Terminal 1: $ npm run start:devnet
Terminal 2: $ create-node -o --start (Yaci CLI)
Terminal 3: $ npm run bridge:node-socket
Then: $ npm run setup:directories
Choose path: Native or Docker
...
```