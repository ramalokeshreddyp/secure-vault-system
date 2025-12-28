# Secure Vault System

## Architecture Overview

This system separates custody and authorization across two on-chain contracts:

* SecureVault: holds ETH and executes withdrawals.
* AuthorizationManager: validates off-chain withdrawal authorizations and tracks replay protection.

The vault never verifies cryptographic signatures directly and relies exclusively on AuthorizationManager.

---

## Authorization Design

Authorization hash is constructed deterministically as:

keccak256(vault, recipient, amount, chainId, nonce)

The hash is signed off-chain by the AuthorizationManager owner and verified on-chain.

---

## Replay Protection

AuthorizationManager tracks consumed authorization hashes in a mapping(bytes32 => bool).
Once a hash is consumed, any further use will revert with "Authorization already used".

---

## Security Invariants

1. Authorization is valid for exactly one withdrawal.
2. Vault never validates signatures itself.
3. State updates occur before ETH transfer.
4. Authorization is bound to vault, chainId, recipient, amount, nonce.
5. Only registered vaults may request authorization validation.
6. Unauthorized callers cannot influence privileged state transitions.

---

## Local Setup & Deployment

### Prerequisites

* Docker
* Docker Compose

### Start the System

From the project root:

```bash
docker-compose up --build
```

This will:

* Start a local Hardhat blockchain
* Deploy AuthorizationManager
* Deploy SecureVault
* Output deployed contract addresses
* Expose JSON-RPC at [http://localhost:8545](http://localhost:8545)

---

## Authorization Flow (Manual)

1. Construct authorization hash:

keccak256(vault, recipient, amount, chainId, nonce)

2. Sign the hash off-chain using the AuthorizationManager owner account.

3. Call:

vault.withdraw(recipient, amount, nonce, signature)

4. AuthorizationManager verifies signature and consumes authorization.

5. ETH is transferred to the recipient.

---

## Test Suite

Run invariant tests:

```bash
npx hardhat test
```

Expected:

```
SecureVault System Invariants
  ✓ Prevents replay attack
  ✓ Fails on wrong amount
```

---

## Known Limitations

* Only native ETH is supported.
* Single admin signer model.
* No ERC20 or ERC721 support.

---

## Project Structure

```
contracts/
  ├─ SecureVault.sol
  └─ AuthorizationManager.sol
scripts/
  └─ deploy.js
docker/
  ├─ Dockerfile
  └─ entrypoint.sh
test/
  └─ system.spec.cjs
docker-compose.yml
README.md
```

---

## Deployment Output

When docker-compose starts, the following information is printed to logs:

* Network name (localhost / chainId 31337)
* AuthorizationManager deployed address
* SecureVault deployed address

These values are required to construct off-chain authorizations.

---

## Gas & Reentrancy Notes

The vault follows the Checks-Effects-Interactions pattern and updates authorization
state before transferring ETH, preventing reentrancy-based double-withdrawals.

---

## Failure Behavior

* Any attempt to reuse an authorization will revert with "Authorization already used".
* Withdrawals with mismatched amount, recipient, or nonce will revert.
* Withdrawals requested by unregistered vaults will revert.
* Unauthorized callers cannot trigger privileged state transitions.
