---
---

# Usage

## A. Native (Binary) Workflow
1. Set up Cardano CLI and Hydra Node binaries:
   ```sh
   npm run setup:cardano-cli
   npm run setup:hydra-node
   ```
2. Start the devnet:
   ```sh
   npm run start:devnet
   ```
3. Start Hydra nodes:
   ```sh
   npm run hydra:start
   ```
4. (Optional) Start Hydra TUI for a participant:
   ```sh
   npm run tui:start -- <participant_index>
   # Example: npm run tui:start -- 0
   ```
5. Stop Hydra nodes:
   ```sh
   npm run hydra:stop
   ```
6. Stop the devnet:
   ```sh
   npm run stop:devnet
   ```

## B. Docker Workflow
1. Set up Cardano CLI and Hydra Node Docker wrappers:
   ```sh
   npm run setup:docker:cardano-cli
   npm run setup:docker:hydra-node
   ```
2. Start the devnet:
   ```sh
   npm run start:devnet
   ```
3. Start Hydra nodes (Docker):
   ```sh
   npm run hydra:start:docker
   ```
4. (Optional) Start Hydra TUI (Docker) for a participant:
   ```sh
   npm run tui:start:docker -- <participant_index>
   # Example: npm run tui:start:docker -- 0
   ```
5. Stop Hydra nodes (Docker):
   ```sh
   npm run hydra:stop:docker
   ```
6. Stop the devnet:
   ```sh
   npm run stop:devnet
   ```