//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract abcMask is Ownable {
    IERC20 token;
    struct userTransaction {
        uint256 amount;
        uint256 time;
        uint256 lockedUntil;
        bool stakingOver;
    }

    struct staking {
        uint256 txNo;
        uint256 totalAmount;
        mapping(uint256 => userTransaction) stakingPerTx;
    }

    error timeNotSpecified(uint256 _time);
    event StakeDeposit(
        uint256 _amount,
        uint256 _lockPeriod,
        uint256 _lockedUntil
    );
    event RewardWithdraw(uint256 _amount, uint256 _reward);

    mapping(address => staking) public stakingTx;
    mapping(uint256 => uint256) public rewardPercent;

    constructor(IERC20 _token) {
        token = _token;
    }

    function addStake(uint256 _time, uint256 _amount) internal {
        token.transferFrom(msg.sender, address(this), _amount);
        stakingTx[msg.sender].txNo++;
        stakingTx[msg.sender].totalAmount += _amount;
        stakingTx[msg.sender]
            .stakingPerTx[stakingTx[msg.sender].txNo]
            .amount = _amount;
        stakingTx[msg.sender]
            .stakingPerTx[stakingTx[msg.sender].txNo]
            .time = _time;
        stakingTx[msg.sender]
            .stakingPerTx[stakingTx[msg.sender].txNo]
            .lockedUntil = block.timestamp + _time;
    }

    function stake(uint256 _time, uint256 _amount) public {
        require(_amount != 0, "Null amount!");
        require(_time != 0, "Null time!");
        require(
            rewardPercent[_time] != 0,
            "Time not specified."
        );
        addStake(_time, _amount);
        emit StakeDeposit(
            _amount,
            _time,
            stakingTx[msg.sender]
                .stakingPerTx[stakingTx[msg.sender].txNo]
                .lockedUntil
        );
    }

    function claimableReward(uint256 _txNo)
        internal
        returns (uint256)
    {
        uint256 amount = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .amount;
        uint256 lockTime = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .lockedUntil;
        uint256 time = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .time;
        uint256 rewardBalance;

        rewardBalance = (amount * rewardPercent[time]) / 100;
        return rewardBalance;
    }

    function claimReward(uint256 _txNo) public {
        require(
            stakingTx[msg.sender]
                .stakingPerTx[_txNo]
                .stakingOver != true,
            "The rewards for this staking is already claimed."
        );
        require(
            block.timestamp >
                stakingTx[msg.sender]
                    .stakingPerTx[_txNo]
                    .lockedUntil,
            "Stake period is not over."
        );
        uint256 reward = claimableReward(_txNo);
        require(reward != 0, "Not eligible for reward!");
        uint256 amount = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .amount;
        uint256 totalAmount = amount + reward;
        stakingTx[msg.sender].totalAmount -= amount;
        token.transfer(msg.sender, totalAmount);
        stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .stakingOver = true;
        emit RewardWithdraw(amount, reward);
    }

    function setRewardPercent(uint256 _days, uint256 _percent)
        public
        onlyOwner
    {
        rewardPercent[_days] = _percent;
    }

    function claimAllRewards() public {
        uint256 totalTxs = stakingTx[msg.sender].txNo;
        uint256 totalRewards;
        uint256 amounts;
        for (uint256 i = 1; i <= totalTxs; i++) {
            if (
                stakingTx[msg.sender]
                    .stakingPerTx[i]
                    .stakingOver ==
                false &&
                block.timestamp >
                stakingTx[msg.sender].stakingPerTx[i].lockedUntil
            ) {
                totalRewards +=
                    (stakingTx[msg.sender]
                        .stakingPerTx[i]
                        .amount *
                        rewardPercent[
                            stakingTx[msg.sender]
                                .stakingPerTx[i]
                                .time
                        ]) /
                    100;
                amounts += stakingTx[msg.sender]
                    .stakingPerTx[i]
                    .amount;
                stakingTx[msg.sender]
                    .stakingPerTx[i]
                    .stakingOver = true;
            }
        }
        stakingTx[msg.sender].totalAmount -= amounts;
        token.transfer(msg.sender, totalRewards + amounts);
    }

    function redeemTokens(uint256 _amount) public onlyOwner {
        token.transfer(msg.sender, _amount);
    }
}
