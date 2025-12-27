# Secure Vault System
- A secure Ethereum smart-contract system that enables authorization-based withdrawals from a vault.
- The system uses a dedicated authorization manager to validate signed approvals before releasing funds.
- This project is designed to run locally using Hardhat and Docker, making it easy for evaluators to deploy, inspect, and validate functionality.

## Project Overview
### The Secure Vault System consists of two main smart contracts:
- AuthorizationManager
  - Verifies cryptographic authorization for withdrawals
  - Prevents replay attacks using nonces and authorization IDs

- SecureVault
  - Holds ETH deposits
  - Allows withdrawals only when authorization is valid

- The contracts are deployed and tested on a local Hardhat blockchain.

## Architecture
```
┌──────────────────────────┐
│      Hardhat Node        │
│   (Local Blockchain)     │
│   http://localhost:8545  │
└───────────▲──────────────┘
            │
┌───────────┴──────────────┐
│    AuthorizationManager  │
│  (Signature Verification)│
└───────────▲──────────────┘
            │
┌───────────┴──────────────┐
│       SecureVault        │
│   (ETH Deposits &        │
│    Authorized Withdraws) │
└──────────────────────────┘
```

## Tech Stack
- Solidity ^0.8.x
- Hardhat
- ethers.js
- Docker & Docker Compose
- Node.js 18 (LTS)

##  Repository Structure
```
secure-vault-system/
├── contracts/
│   ├── AuthorizationManager.sol
│   └── SecureVault.sol
├── scripts/
│   └── deploy.js
├── docker/
│   └── entrypoint.sh
├── docker-compose.yml
├── hardhat.config.js
├── package.json
└── README.md
```

## Setup Instructions
- Clone the Repository
```
git clone https://github.com/ramalokeshreddyp/secure-vault-system.git
cd secure-vault-system
```

## Start the Local Blockchain & Deployer
- This will:
  - Start a Hardhat local blockchain
  - Compile contracts
  - Deploy contracts automatically
```
docker-compose up --build
```

## Step 6: Deployment Script Expectations (Completed)
- The deployment script performs the following:

- Connects to the Local Blockchain
  - RPC Endpoint: http://localhost:8545
  - Network: localhost
  - Chain ID: 31337

- Deploys Contracts in Correct Order
  - AuthorizationManager
  - SecureVault (receives AuthorizationManager address)

- Outputs Clear Deployment Information
  - Example output:
```
 Deploying with account: 0xf39F...2266
 Network name: localhost
 Network chainId: 31337

 AuthorizationManager deployed at:
0x5FbDB2315678afecb367f032d93F642f64180aa3

 SecureVault deployed at:
0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

 Deployment completed successfully
```
- This output is easy to locate and verify for evaluators.

## Step 7: Local Validation (Manual Flow)
- Manual Validation via JSON-RPC
- Verify Network
```
curl -X POST http://localhost:8545 \
-H "Content-Type: application/json" \
--data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```
- Expected:
```
0x7a69   // chainId 31337
```

## Verify Contract Deployment
```
curl -X POST http://localhost:8545 \
-H "Content-Type: application/json" \
--data '{
  "jsonrpc":"2.0",
  "method":"eth_getCode",
  "params":["<SECURE_VAULT_ADDRESS>","latest"],
  "id":1
}'
```
- A non-empty bytecode response confirms successful deployment.

## Deposit ETH into SecureVault
```
curl -X POST http://localhost:8545 \
-H "Content-Type: application/json" \
--data '{
  "jsonrpc":"2.0",
  "method":"eth_sendTransaction",
  "params":[{
    "from":"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "to":"<SECURE_VAULT_ADDRESS>",
    "value":"0x16345785D8A0000"
  }],
  "id":1
}'
```

## Confirm Vault Balance
```
curl -X POST http://localhost:8545 \
-H "Content-Type: application/json" \
--data '{
  "jsonrpc":"2.0",
  "method":"eth_getBalance",
  "params":["<SECURE_VAULT_ADDRESS>","latest"],
  "id":1
}'
```
- Confirms ETH was successfully deposited.

## Authorization-Based Withdrawal Flow
- Authorization is generated off-chain
- Signed payload includes:
  - vault address
  - recipient
  - amount
  - nonce
  - authorization ID
- Signature is validated via AuthorizationManager
- SecureVault executes withdrawal only if:
  - Signature is valid
  - Authorization has not been used
  - Vault has sufficient balance
- Unauthorized or replayed withdrawals fail safely.

## Security Considerations
- Replay protection using nonces
- Signature verification using ecrecover
- Strict input validation
- ETH transfer success validation

## 🔁 Replay Protection

- Replay attacks are prevented using a nonce and authorization ID.
- Each authorization can only be used once.
- The AuthorizationManager tracks used authorizations and rejects any reused nonce or authId,
ensuring signatures cannot be replayed.

## Assumptions & Known Limitations

- Authorization signatures are generated off-chain by a trusted signer.
- Private keys used in the local Hardhat network are publicly known and must never be used on mainnet.
- This system is intended for demonstration and local validation only.
- No gas optimization or production hardening has been applied.

## Repository Link
``` https://github.com/ramalokeshreddyp/secure-vault-system ```
