const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SecureVault System Invariants", function () {

  let vault, authManager, owner, user;

  beforeEach(async () => {
  [owner, user] = await ethers.getSigners();

  const Auth = await ethers.getContractFactory("AuthorizationManager");
  authManager = await Auth.deploy();
  await authManager.waitForDeployment();

  const Vault = await ethers.getContractFactory("SecureVault");
  vault = await Vault.deploy(await authManager.getAddress());
  await vault.waitForDeployment();

  // 🔥 THIS WAS MISSING
  await authManager.registerVault(await vault.getAddress());

  await owner.sendTransaction({
    to: await vault.getAddress(),
    value: ethers.parseEther("2")
  });
});


  function buildAuth(amount, nonce) {
    return ethers.keccak256(
      ethers.solidityPacked(
        ["address","address","uint256","uint256","bytes32"],
        [vault.target, user.address, amount, 31337, nonce]
      )
    );
  }

  it("Prevents replay attack", async () => {
    const amount = ethers.parseEther("1");
    const nonce = ethers.keccak256(ethers.toUtf8Bytes("replay"));

    const hash = buildAuth(amount, nonce);
    const signature = await owner.signMessage(ethers.getBytes(hash));

    await vault.withdraw(user.address, amount, nonce, signature);

    await expect(
      vault.withdraw(user.address, amount, nonce, signature)
    ).to.be.revertedWith("Authorization already used");
  });

  it("Fails on wrong amount", async () => {
    const amount = ethers.parseEther("1");
    const wrong = ethers.parseEther("2");
    const nonce = ethers.keccak256(ethers.toUtf8Bytes("wrong"));

    const hash = buildAuth(amount, nonce);
    const signature = await owner.signMessage(ethers.getBytes(hash));

    await expect(
      vault.withdraw(user.address, wrong, nonce, signature)
    ).to.be.reverted;
  });

});
