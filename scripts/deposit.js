async function main() {
  const [user] = await ethers.getSigners();

  const vault = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

  const tx = await user.sendTransaction({
    to: vault,
    value: ethers.parseEther("3"),
    gasLimit: 1000000
  });

  await tx.wait();
  console.log("3 ETH deposited into SecureVault");
}

main().catch(console.error);
