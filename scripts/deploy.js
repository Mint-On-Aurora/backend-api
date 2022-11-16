async function main() {

	const [deployer] = await ethers.getSigners();

	console.log(
	"Deploying contracts with the account:",
	deployer.address
	);
	console.log("Account balance:", (await deployer.getBalance()).toString());

	const MintOnAurora = await ethers.getContractFactory("MintOnAurora");
    const _minter = "0x0eFDd872fD945cdFCE8C8d8Db5Aa7a337e267c5b";
	const contract = await MintOnAurora.deploy(_minter);

	console.log("Contract deployed at:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });