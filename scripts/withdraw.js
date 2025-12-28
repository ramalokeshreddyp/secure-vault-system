async function main() {
  const [owner, receiver] = await ethers.getSigners();

  const vaultAddr = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const authAddr  = "0x5FbDB2315678afecb367f032d93F642f64180aa3";


  const vault = await ethers.getContractAt("SecureVault", vaultAddr);
  const auth = await ethers.getContractAt("AuthorizationManager", authAddr);

  const amount = ethers.parseEther("1");
  const nonce = ethers.keccak256(ethers.randomBytes(32));
  const chainId = (await ethers.provider.getNetwork()).chainId;

  const hash = await auth.getAuthorizationHash(vaultAddr, receiver.address, amount, chainId, nonce);
  const signature = await owner.signMessage(ethers.getBytes(hash));

  const tx = await vault.withdraw(receiver.address, amount, nonce, signature, { gasLimit: 1000000 });
  await tx.wait();

  console.log("1 ETH withdrawn to", receiver.address);
}

main().catch(console.error);
