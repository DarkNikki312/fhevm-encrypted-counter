# fhEVM Encrypted Counter (Sepolia)

A minimal confidential counter dApp built on Zama fhEVM. The contract stores a `euint32`, supports homomorphic addition of encrypted inputs, and demonstrates public reveal via the Decryption Oracle. The frontend (single HTML file) encrypts inputs in the browser via the Relayer SDK and calls the contract on Sepolia.

- **Contract**: `0xC5B8f66e56D41d067D88C06413AbCe7b99727E44` (Sepolia)
- **Stack**: Solidity 0.8.24, `@fhevm/solidity` v0.7.x, ethers v6, Relayer SDK (CDN)

## Smart contract

See `EncryptedCounter.sol`. It:
- stores an `euint32` counter;
- `add(externalEuint32, bytes inputProof)` validates and adds encrypted input;
- `getEncryptedHandle()` returns a ciphertext handle for public decrypt (HTTP);
- `requestReveal()` / `onReveal()` performs on-chain reveal with KMS signatures.

The contract imports `FHE.sol` and `SepoliaConfig` from `@fhevm/solidity`, which provides the required addresses for Sepolia. See docs (Relayer SDK & Solidity guides).  
> Docs: Web apps CDN + init flow; Sepolia config and decryption patterns. :contentReference[oaicite:3]{index=3}

## Frontend

Open `index.html` in a static server (recommended) and:
1. Click **Connect MetaMask** (network: **Sepolia**).
2. Enter a number and click **Add (encrypted)** — SDK encrypts input and calls `add(...)`.
3. Click **Show via HTTP Public Decrypt** — SDK returns plaintext via relayer HTTP public decryption.
4. Optionally click **On-chain Reveal (Oracle)**, then read `lastPlain` after the oracle callback.

### Serve locally
Any static server works, e.g.:
```sh
npx http-server . -p 8080
# or
python -m http.server 8080
