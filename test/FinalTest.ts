import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { sign } from "crypto";
import { ethers, network } from "hardhat";
import { abcStaking, abcStaking__factory, Token, Token__factory } from "../typechain";
import { addressFromNumber, expandTo18Decimals } from "./utilities/utilities";
import chai, { expect } from "chai";

describe("abcma Test",()=>{
    let signers: SignerWithAddress[];
    let owner : SignerWithAddress;
    let abc : abcStaking;
    let token : Token;
    
    beforeEach(async()=>{
        signers = await ethers.getSigners();
        owner = signers[0];
        token = await new Token__factory(owner).deploy();
        abc = await new abcStaking__factory(owner).deploy();
        await abc.connect(owner).initialize(token.address);
        await token.connect(owner).transfer(signers[1].address,expandTo18Decimals(1000));
        await token.connect(owner).transfer(signers[2].address,expandTo18Decimals(1000));
        await token.connect(owner).transfer(abc.address,expandTo18Decimals(10000));
    })

    it.only("abc Test", async()=>{
        await token.connect(signers[1]).approve(abc.address,expandTo18Decimals(1000));
        await token.connect(signers[2]).approve(abc.address,expandTo18Decimals(1000));
        await expect(abc.connect(owner).setRewardPercent(30,200)).to.be.revertedWith("Minimum time not met!");
        await abc.connect(signers[1]).stake(30*86400,expandTo18Decimals(100));
        console.log("User Transaction: "+await abc.userTransactions(signers[1].address,1));
        console.log("User Data: "+await abc.stakingTx(signers[1].address));
        await network.provider.send("evm_increaseTime", [65*86400]);
        await network.provider.send("evm_mine");
        console.log("Reward: "+await abc.connect(signers[1]).rewards(1));
        await abc.connect(signers[1]).claim(1);
        console.log("User Balance: "+await token.balanceOf(signers[1].address));
        console.log("User Transactions: "+await abc.userTransactions(signers[1].address,1))
        console.log("User Data: "+await abc.stakingTx(signers[1].address));
    })

    it("Multiple Staking by multiple users",async()=>{
        await token.connect(signers[1]).approve(abc.address,expandTo18Decimals(1000));
        await token.connect(signers[2]).approve(abc.address,expandTo18Decimals(1000));
        await abc.connect(signers[1]).stake(30*86400,expandTo18Decimals(50));
        await abc.connect(signers[1]).stake(60*86400,expandTo18Decimals(80));
        console.log("User Data: "+await abc.stakingTx(signers[1].address));
        console.log("User Transaction 1: "+await abc.userTransactions(signers[1].address,1));
        console.log("User Transactions 2: "+await abc.userTransactions(signers[1].address,2));
    })

})