# Troubleshooting

## 🟥 Known Critical Bug: Hydra Head Close Fails on Conway/Protocol 10.x

**Summary:**  
After opening and funding a Hydra Head with latest Hydra (1.2.0) and Cardano node (10.1.4, Conway/protocol 10.x), the head cannot be closed. Attempting to close (`{"tag":"Close"}`) triggers a PlutusV3 script validation error.

**Symptoms:**
- Hydra head opens successfully (Init → Commit → CollectCom → Open)
- Any *Close* action (TUI/API) fails
- Node returns `ValidationTagMismatch` and Plutus error, e.g.:
  ```
  ShelleyTxValidationError ShelleyBasedEraConway (ApplyTxError (ConwayUtxowFailure (UtxoFailure (UtxosFailure (ValidationTagMismatch (IsValid True) (FailedUnexpectedly (PlutusFailure "..."))))))
  ```
**Hypothesis:**  
Protocol compatibility—Hydra 1.2.0 is NOT YET compatible with Cardano protocol 10.x (Conway) on Yaci DevKit.

**Workarounds:**
- Use Cardano node protocol version 9.x (downgrade your node)
- Check for new Hydra releases
- Export protocol parameters from the node and replace `config/hydra/protocol-parameters.json`
- See [Hydra repo issues](https://github.com/input-output-hk/hydra/issues)

---

## Other Issues & Resolutions

### Cannot Start Node/Bridge

- Ensure `npm run start:devnet` and the Yaci socket bridge are BOTH running in separate terminals.

### Port Conflict

- Use `lsof -i :<port>` to find and kill process OR change port in config.

### "Invalid participant index"

- Ensure you run head/TUI scripts with an index in range (i.e., for 3 participants use 0, 1, or 2).

### Permission Issues

- If files in `keys/` or `bin/` are root-owned, run `sudo chown -R $USER:$USER keys/ bin/ logs/`

---

## When in Doubt

- Review shell output!
- Open a [GitHub Issue](https://github.com/Arpit-K-Sharma/hydra-cardano-yaci/issues) with error log and your protocol version info.