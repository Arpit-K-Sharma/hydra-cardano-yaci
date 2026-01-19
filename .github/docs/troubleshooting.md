---
---

# Troubleshooting & Known Issues

## PlutusV3 ValidationTagMismatch on Close (Conway/Protocol 10.x)
**Issue:**
When using Hydra 1.2.0 with Cardano node 10.1.4 (Conway era, Protocol 10.2) on a Yaci DevKit devnet, closing the Hydra head fails with a PlutusV3 ValidationTagMismatch error. The head opens successfully (Init → Commit → CollectCom → Open), but any attempt to close the head (via TUI or API) is rejected by the cardano-node with a script validation error.

**Workarounds & Recommendations:**
- Consider downgrading cardano-node to a version using Protocol 9.x if possible.
- Monitor for Hydra releases with explicit support for Protocol 10.x/Conway.
- Ensure protocol parameters in `config/hydra/protocol-parameters.json` match those exported from your running cardano-node.
- For updates and discussion, see the [Hydra GitHub issues](https://github.com/input-output-hk/hydra/issues) and [Yaci DevKit documentation](https://github.com/txpipe/yaci-devkit).