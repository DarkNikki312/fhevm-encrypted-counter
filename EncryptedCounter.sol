// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

// FHE library and Sepolia network configuration (fhEVM)
import "https://cdn.jsdelivr.net/npm/@fhevm/solidity@0.7.0/lib/FHE.sol";
import { SepoliaConfig } from "https://cdn.jsdelivr.net/npm/@fhevm/solidity@0.7.0/config/ZamaConfig.sol";

/// @title EncryptedCounter — minimal confidential counter on fhEVM (Sepolia)
/// @notice Stores an euint32, supports homomorphic addition of encrypted inputs,
///         and demonstrates public reveal via the Decryption Oracle.
contract EncryptedCounter is SepoliaConfig {
    // Encrypted counter
    euint32 private _count;

    // Demo fields for public reveal via oracle
    uint32 public lastPlain;
    bool public pending;
    uint256 private lastRequestId;

    constructor() {
        // Initialize the counter with encrypted zero
        _count = FHE.asEuint32(0);
        // Allow this contract to access its own encrypted state
        FHE.allowThis(_count);
    }

    /// @notice Add an encrypted value to the counter.
    /// @dev The Relayer SDK / Remix plugin provides `externalEuint32` + `inputProof`.
    /// @param encryptedAmount External encrypted handle (type externalEuint32)
    /// @param inputProof Zero-knowledge proof validating the encrypted input
    function add(externalEuint32 encryptedAmount, bytes calldata inputProof) external {
        // Validate and convert external encrypted input into an euint32
        euint32 amount = FHE.fromExternal(encryptedAmount, inputProof);
        // Homomorphic addition on encrypted values
        _count = FHE.add(_count, amount);
        // Re-authorize this contract on the updated encrypted state
        FHE.allowThis(_count);
    }

    /// @notice Return the ciphertext handle of the counter
    /// @dev Useful for off-chain public decryption via the Relayer SDK
    function getEncryptedHandle() external view returns (bytes32) {
        return FHE.toBytes32(_count);
    }

    /// @notice Request a public decryption via the Decryption Oracle (async)
    /// @dev The oracle will call back `onReveal(...)` with the plaintext and KMS signatures
    function requestReveal() external {
        require(!pending, "Decryption pending");
        // Declare and initialize the array of ciphertext handles
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(_count);
        // Send the decryption request and store the requestId for callback verification
        lastRequestId = FHE.requestDecryption(cts, this.onReveal.selector);
        pending = true;
    }

    /// @notice Oracle callback: verifies KMS signatures and stores the plaintext.
    /// @param requestId Must match the previously stored `lastRequestId`
    /// @param plain The decrypted uint32 value
    /// @param signatures KMS signatures to be verified by the library
    /// @return The plaintext value for convenience / tracing
    function onReveal(uint256 requestId, uint32 plain, bytes[] memory signatures)
        external
        returns (uint32)
    {
        require(requestId == lastRequestId, "Bad requestId");
        // Verify KMS signatures from the oracle
        FHE.checkSignatures(requestId, signatures);
        lastPlain = plain;
        pending = false;
        return plain;
    }
}
