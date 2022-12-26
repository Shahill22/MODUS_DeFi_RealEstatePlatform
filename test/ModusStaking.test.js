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
const depositAmount = ether(BN(1520));

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

    describe("Tier", async function () {
      describe("2. Set and Update Tiers", async function () {
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

        it("2.3. should update tier of given tier ID ", async function () {
          const tierID1 = BN("1");
          const tierAmount1 = BN("500");
          const setTiersReceipt1 = await stakingContract.setTiers(tierAmount1);
          expectEvent(setTiersReceipt1, "TierAdded", {
            IDtier: tierID1,
            tierStakeAmount: tierAmount1,
          });
          const tierID2 = BN("2");
          const tierAmount2 = BN("700");
          const setTiersReceipt2 = await stakingContract.setTiers(tierAmount2);
          expectEvent(setTiersReceipt2, "TierAdded", {
            IDtier: tierID2,
            tierStakeAmount: tierAmount2,
          });
          const updateAmount = BN("100"); //update tier amount for tier 1
          const updateTiersReceipt1 = await stakingContract.updateTiers(
            tierID1,
            updateAmount
          );
          expectEvent(updateTiersReceipt1, "TierUpdated", {
            IDtier: tierID1,
            tierStakeAmount: updateAmount,
          });
          expect(
            await stakingContract.stakeTokensInTier(tierID1)
          ).to.bignumber.equal(updateAmount);
        });

        it("2.4. should revert if update tier amount of given tier ID breaks sorted order", async function () {
          const tierID1 = BN("1");
          const tierAmount1 = BN("500");
          const setTiersReceipt1 = await stakingContract.setTiers(tierAmount1);
          expectEvent(setTiersReceipt1, "TierAdded", {
            IDtier: tierID1,
            tierStakeAmount: tierAmount1,
          });
          const tierID2 = BN("2");
          const tierAmount2 = BN("700");
          const setTiersReceipt2 = await stakingContract.setTiers(tierAmount2);
          expectEvent(setTiersReceipt2, "TierAdded", {
            IDtier: tierID2,
            tierStakeAmount: tierAmount2,
          });
          const updateAmount = BN("800"); //update tier amount for tier 1
          await expectRevert(
            stakingContract.updateTiers(tierID1, updateAmount),
            "ModusStaking: Token for this tier must be less than tier after "
          );
        });
      });
      describe("3. Determine Tier", async function () {
        it("3.1. determine tiers for staked amount", async function () {
          await stakingContract.setTiers(BN("500"));
          await stakingContract.setTiers(BN("1000"));
          await stakingContract.setTiers(BN("1500"));
          await stakingContract.setTiers(BN("2000"));
          await stakingContract.setTiers(BN("2500"));
          const stakedAmount = BN("1200");
          expect(
            await stakingContract.determineTiers(stakedAmount)
          ).to.bignumber.equal(BN("2"));
        });
        it("3.2. determine tier for staked amount greater than last tier value ", async function () {
          await stakingContract.setTiers(BN("500"));
          await stakingContract.setTiers(BN("1000"));
          await stakingContract.setTiers(BN("1500"));
          await stakingContract.setTiers(BN("2000"));
          await stakingContract.setTiers(BN("2500"));
          const stakedAmount = BN("12000");
          expect(
            await stakingContract.determineTiers(stakedAmount)
          ).to.bignumber.equal(BN("5"));
        });
        it("3.3. should revert if staked amount less than tier one value ", async function () {
          await stakingContract.setTiers(BN("500"));
          await stakingContract.setTiers(BN("1000"));
          await stakingContract.setTiers(BN("1500"));
          await stakingContract.setTiers(BN("2000"));
          await stakingContract.setTiers(BN("2500"));
          const stakedAmount = BN("120");
          await expectRevert(
            stakingContract.determineTiers(stakedAmount),
            "ModusStaking: Stake deposit lower for any tier "
          );
        });
      });
    });

    //--------------------
    describe("Staking & Unstaking", async function () {
      describe("4. Deposit & Stake ", async function () {
        it("4.1. deposit should revert if deposit is called with an amount of 0", async function () {
          const message =
            "ModusStaking: The stake deposit has to be larger than 0";
          await expectRevert(stakingContract.deposit("0"), message);
        });
        it("4.2. should create a new deposit for the depositing account and emit StakeDeposited(msg.sender, amount)", async function () {
          await stakingContract.setTokenAddress(modus.address, from(owner));
          await modus.transfer(account1, depositAmount, from(treasury));

          const eventData = {
            account: account1,
            amount: depositAmount,
          };

          const initialBalance = await modus.balanceOf(stakingContract.address);
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          const { logs } = await stakingContract.deposit(
            depositAmount,
            from(account1)
          );
          const currentBalance = await modus.balanceOf(stakingContract.address);

          expectEvent.inLogs(logs, "StakeDeposited", eventData);
          expect(initialBalance.add(depositAmount)).to.be.bignumber.equal(
            currentBalance
          );
        });
        it("4.3. should create a new deposit and determine tier level", async function () {
          await stakingContract.setTokenAddress(modus.address, from(owner));
          await modus.transfer(account1, depositAmount, from(treasury));

          await stakingContract.setTiers(BN("500"));
          await stakingContract.setTiers(BN("1000"));
          await stakingContract.setTiers(BN("1500"));
          await stakingContract.setTiers(BN("2000"));
          await stakingContract.setTiers(BN("2500"));
          const eventData = {
            account: account1,
            amount: depositAmount,
          };

          const initialBalance = await modus.balanceOf(stakingContract.address);
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          const { logs } = await stakingContract.deposit(
            depositAmount,
            from(account1)
          );
          const tierLevel = BN(await stakingContract.getTierDetails(account1));
          const currentBalance = await modus.balanceOf(stakingContract.address);
          //expect(BN("tierLevel")).to.bignumber.equal(BN("3"));
          //console.log(tierLevel);
          expect(
            await stakingContract.getTierDetails(account1)
          ).to.be.bignumber.equal(BN("3"));
          expectEvent.inLogs(logs, "StakeDeposited", eventData);
          expect(initialBalance.add(depositAmount)).to.be.bignumber.equal(
            currentBalance
          );
        });
      });

      describe("5. Withdrawal & Execution", async function () {
        it("5.1. initiateWithdrawal: should revert if the account has no stake deposit", async function () {
          await modus.transfer(account1, depositAmount, from(treasury));
          const withdrawAmount = BN("100");
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          await stakingContract.deposit(depositAmount, from(account1));
          const revertMessage =
            "ModusStaking: There is no stake deposit for this account";
          await expectRevert(
            stakingContract.initiateWithdrawal(withdrawAmount, from(account2)),
            revertMessage
          );
        });
        it("5.2. initiateWithdrawal: should emit the WithdrawInitiated(msg.sender, stakeDeposit.amount) event", async function () {
          await stakingContract.setTokenAddress(modus.address, from(owner));
          await modus.transfer(account1, depositAmount, from(treasury));
          const eventData = {
            account: account1,
            amount: depositAmount,
          };
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          await stakingContract.deposit(depositAmount, from(account1));

          const { logs } = await stakingContract.initiateWithdrawal(
            depositAmount,
            from(account1)
          );
          expectEvent.inLogs(logs, "WithdrawInitiated", eventData);
        });
        it("5.3. should revert if account has already initiated the withdrawal", async function () {
          await modus.transfer(account1, depositAmount, from(treasury));
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          await stakingContract.deposit(depositAmount, from(account1));
          const { logs } = await stakingContract.initiateWithdrawal(
            depositAmount,
            from(account1)
          );
          const revertMessage =
            "ModusStaking: You have already initiated the withdrawal";
          await expectRevert(
            stakingContract.initiateWithdrawal(depositAmount, from(account1)),
            revertMessage
          );
        });

        it("5.4. executeWithdrawal: should revert if the withdraw was not initialized", async function () {
          await modus.transfer(account1, depositAmount, from(treasury));
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          await stakingContract.deposit(depositAmount, from(account1));
          const revertMessage = "ModusStaking: Withdraw is not initialized";
          await expectRevert(
            stakingContract.executeWithdrawal(from(account1)),
            revertMessage
          );
        });
        it("5.5. executeWithdrawal: should revert if unstaking period did not pass", async function () {
          await modus.transfer(account1, depositAmount, from(treasury));
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          await stakingContract.deposit(depositAmount, from(account1));
          const { logs } = await stakingContract.initiateWithdrawal(
            depositAmount,
            from(account1)
          );
          const revertMessage =
            "ModusStaking: The unstaking period did not pass";
          await expectRevert(
            stakingContract.executeWithdrawal(from(account1)),
            revertMessage
          );
        });
        it("5.6. executeWithdrawal: should transfer the initial staking deposit and emit WithdrawExecuted", async function () {
          await modus.transfer(account1, depositAmount, from(treasury));
          await modus.approve(
            stakingContract.address,
            depositAmount,
            from(account1)
          );
          const withdrawalAmount = depositAmount;
          await stakingContract.deposit(depositAmount, from(account1));
          await stakingContract.initiateWithdrawal(
            withdrawalAmount,
            from(account1)
          );
          await time.increase(time.duration.days(unstakingPeriod));
          const { logs } = await stakingContract.executeWithdrawal(
            from(account1)
          );

          const eventData = {
            account: account1,
            amount: depositAmount,
          };

          expectEvent.inLogs(logs, "WithdrawExecuted", eventData);
        });
      });
    });
  }
);
