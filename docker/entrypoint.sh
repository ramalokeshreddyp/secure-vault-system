#!/bin/sh
set -e

echo "⏳ Waiting for blockchain RPC..."
until nc -z blockchain 8545; do
  sleep 1
done

echo "📦 Compiling smart contracts..."
npx hardhat compile

echo "📤 Deploying contracts to shared Hardhat node..."
npx hardhat run scripts/deploy.js --network localhost

echo "🎉 Deployment completed successfully"

# Keep container alive for logs / inspection
tail -f /dev/null

