import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const Auth = await hre.ethers.getContractFactory("AuthorizationManager");
  const auth = await Auth.deploy(deployer.address);
  await auth.waitForDeployment();

  const Vault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await Vault.deploy(await auth.getAddress());
  await vault.waitForDeployment();

  console.log("AuthorizationManager:", await auth.getAddress());
  console.log("SecureVault:", await vault.getAddress());

  // ✅ REGISTER VAULT EVERY TIME
  const tx = await auth.registerVault(await vault.getAddress(), true);
  await tx.wait();
  console.log("Vault registered successfully.");
}

main().catch(console.error);
