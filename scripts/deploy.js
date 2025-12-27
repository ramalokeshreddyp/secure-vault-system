const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("🚀 Deploying with account:", deployer.address);

  const network = await hre.ethers.provider.getNetwork();
  console.log("🌐 Network name:", hre.network.name);
  console.log("🌐 Network chainId:", network.chainId.toString());

  // 1️⃣ Deploy AuthorizationManager (needs signer address)
  const AuthorizationManager = await hre.ethers.getContractFactory(
    "AuthorizationManager"
  );
  const authManager = await AuthorizationManager.deploy(deployer.address);
  await authManager.waitForDeployment();

  const authManagerAddress = await authManager.getAddress();
  console.log("✅ AuthorizationManager deployed at:", authManagerAddress);

  // 2️⃣ Deploy SecureVault (needs authManager address)
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy(authManagerAddress);
  await vault.waitForDeployment();

  const vaultAddress = await vault.getAddress();
  console.log("✅ SecureVault deployed at:", vaultAddress);

  console.log("🎉 Deployment completed successfully");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});
