// LIBRARIES
const { expect } = require("chai");

const {
  expectEvent,
  expectRevert,
  constants,
  time,
  ether,
} = require("@openzeppelin/test-helpers");
const {
  BN,
  expectInvalidArgument,
  getEventProperty,
  timeTravel,
} = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { ZERO_ADDRESS } = constants;

// CONTRACTS
const ModusStakingContract = artifacts.require("ModusStakingContract");
const Token = artifacts.require("Modus");

const totalSupply = ether(BN(1e6));
const depositAmount = ether(BN(500));

const unstakingPeriod = BN(7); //7 Days

const from = (account) => ({ from: account });

contract(
  "ModusStakingContract",
  function ([
    owner,
    treasury,
    founder1,
    founder2,
    account1,
    account2,
    account3,
  ]) {
    let modus, stakingContract;
    beforeEach(async () => {
      modus = await Token.new(treasury, founder1, founder2);
      stakingContract = await ModusStakingContract.new(
        modus.address,
        unstakingPeriod
      );
    });

    describe("1. On deployment", async function () {
      it("1.2. should set deployer as default owner", async function () {
        expect(await stakingContract.owner()).to.equal(owner);
      });
      it("1.1. should set the token correctly", async function () {
        expect(await stakingContract.token()).to.equal(modus.address);
      });
      it("1.3. should revert if token address is zero", async function () {
        await expectRevert(
          stakingContract.setTokenAddress(ZERO_ADDRESS),
          "ModusStaking: Invalid token address"
        );
      });
    });

    describe("2. Tier Determination", async function () {
      it("2.1. should set tiers", async function () {
        const tierID = BN("1");
        const tierAmount = BN("500");
        const setTiersReceipt = await stakingContract.setTiers(tierAmount);
        expectEvent(setTiersReceipt, "TierAdded", {
          IDtier: tierID,
          tierStakeAmount: tierAmount,
        });

        expect(
          await stakingContract.stakeTokensInTier(tierID)
        ).to.bignumber.equal(tierAmount);
      });

      it("2.2. should revert if tiers not set in sorted order", async function () {
        const tierID1 = BN("1");
        const tierAmount1 = BN("500");
        const setTiersReceipt1 = await stakingContract.setTiers(tierAmount1);
        expectEvent(setTiersReceipt1, "TierAdded", {
          IDtier: tierID1,
          tierStakeAmount: tierAmount1,
        });
        const tierID2 = BN("2");
        const tierAmount2 = BN("100");
        await expectRevert(
          stakingContract.setTiers(tierAmount2),
          "ModusStaking: Token for this tier must be in sorted order "
        );
      });
      /*
      it("2.1. deposit: should throw if called with wrong argument types", async function () {
        await expectInvalidArgument.uint256(
          this.stakingContract.deposit("none"),
          "amount"
        );
      });

      it("2.2. deposit: should revert if deposit is called with an amount of 0", async function () {
        const message =
          "[Validation] The stake deposit has to be larger than 0";
        await expectRevert(this.stakingContract.deposit("0"), message);
      });

      it("2.3. deposit: should revert if the transfer fails because of insufficient funds", async function () {
        const exceedsBalanceMessage = "ERC20: transfer amount exceeds balance.";
        await expectRevert(
          this.stakingContract.deposit(depositAmount, from(account2)),
          exceedsBalanceMessage
        );
        await this.token.transfer(account2, depositAmount);
        const exceedsAllowanceMessage =
          "ERC20: transfer amount exceeds allowance.";
        await expectRevert(
          this.stakingContract.deposit(depositAmount, from(account2)),
          exceedsAllowanceMessage
        );
      });

      it("2.4. deposit: should create a new deposit for the depositing account and emit StakeDeposited(msg.sender, amount)", async function () {
        const eventData = {
          account: account2,
          amount: depositAmount,
        };

        const initialBalance = await this.token.balanceOf(
          this.stakingContract.address
        );
        await this.token.approve(
          this.stakingContract.address,
          depositAmount,
          from(account2)
        );
        const { logs } = await this.stakingContract.deposit(
          depositAmount,
          from(account2)
        );
        const currentBalance = await this.token.balanceOf(
          this.stakingContract.address
        );

        expectEvent.inLogs(logs, "StakeDeposited", eventData);
        expect(initialBalance.add(depositAmount)).to.be.bignumber.equal(
          currentBalance
        );
      });

      it("2.5. deposit: should have current total stake less than current maximum staking limit", async function () {
        const totalStake = await this.stakingContract.currentTotalStake();
        const currentMaxLimit = await this.stakingContract.maxStakingAmount();

        expect(totalStake).to.be.bignumber.below(currentMaxLimit);
        expect(currentMaxLimit).to.be.bignumber.equal(maxStakingAmount);
      });

      it("2.6. deposit: should revert if trying to deposit more than staking limit", async function () {
        const revertMessage =
          "[Deposit] Your deposit would exceed the current staking limit";
        await this.token.transfer(account3, maxStakingAmount);
        await this.token.approve(account3, maxStakingAmount, from(account3));

        await expectRevert(
          this.stakingContract.deposit(maxStakingAmount, from(account3)),
          revertMessage
        );
      });

      it("2.7. initiateWithdrawal: should revert if the account has no stake deposit", async function () {
        const revertMessage =
          "[Initiate Withdrawal] There is no stake deposit for this account";
        await expectRevert(
          this.stakingContract.initiateWithdrawal(from(unauthorized)),
          revertMessage
        );
      });

      it("2.8. initiateWithdrawal: should emit the WithdrawInitiated(msg.sender, stakeDeposit.amount) event", async function () {
        const eventData = {
          account: account1,
          amount: depositAmount,
        };

        await this.token.transfer(rewardsAddress, rewardsAmount);
        await this.stakingContract.distributeRewards();

        const { logs } = await this.stakingContract.initiateWithdrawal(
          from(account1)
        );
        expectEvent.inLogs(logs, "WithdrawInitiated", eventData);
      });

      it("2.9. initiateWithdrawal: should revert if account has already initiated the withdrawal", async function () {
        const revertMessage =
          "[Initiate Withdrawal] You already initiated the withdrawal";
        await expectRevert(
          this.stakingContract.initiateWithdrawal(from(account1)),
          revertMessage
        );
      });

      it("2.10. executeWithdrawal: should revert if there is no deposit on the account", async function () {
        const revertMessage =
          "[Withdraw] There is no stake deposit for this account";
        await expectRevert(
          this.stakingContract.executeWithdrawal(),
          revertMessage
        );
      });

      it("2.11. executeWithdrawal: should revert if the withdraw was not initialized", async function () {
        const revertMessage = "[Withdraw] Withdraw is not initialized";
        await expectRevert(
          this.stakingContract.executeWithdrawal(from(account2)),
          revertMessage
        );
      });

      it("2.12. executeWithdrawal: should revert if unstaking period did not pass", async function () {
        const revertMessage = "[Withdraw] The unstaking period did not pass";
        await expectRevert(
          this.stakingContract.executeWithdrawal(from(account1)),
          revertMessage
        );
      });

      it("2.13. getStakeDetails: should return the stake deposit ", async function () {
        const stakeDeposit = await this.stakingContract.getStakeDetails(
          account1
        );

        expect(stakeDeposit[0]).to.be.bignumber.equal(depositAmount);
        expect(stakeDeposit[3]).to.be.bignumber.above(BigNumber(0));
      });

      it("2.14. executeWithdrawal: should transfer the initial staking deposit  and emit WithdrawExecuted", async function () {
        const { logs } = await this.stakingContract.executeWithdrawal(
          from(account1)
        );

        const eventData = {
          account: account1,
          amount: depositAmount,
        };

        expectEvent.inLogs(logs, "WithdrawExecuted", eventData);
      });
      */
    });
  }
);
