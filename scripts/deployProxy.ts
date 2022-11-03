import { SignerWithAddress } from "../node_modules/@nomiclabs/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import {
  expandTo18Decimals,
  expandTo6Decimals,
} from "../test/utilities/utilities";
import {
  OwnedUpgradeabilityProxy, Staking, Staking__factory,
} from "../typechain";

function sleep(ms: any) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
async function main() {
  // We get the contract to deploy
  const owner = "0x8008985282aCa5835F09c3ffE09C9B380b2cEFd0";

  const proxy1 = await ethers.getContractFactory("OwnedUpgradeabilityProxy");
  const proxy = await proxy1.deploy();
  await sleep(4000);
  console.log("Proxy Deployed", proxy.address);
  await proxy.upgradeTo("0x6430dDbEF3511b18D933BF4f29E25D62Bb35b715");
  console.log("Upgraded implementation");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

