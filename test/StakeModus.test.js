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
  BigNumber,
  expectInvalidArgument,
  getEventProperty,
  timeTravel,
} = require("@openzeppelin/test-helpers");

// CONTRACTS
const ModusStakingContract = artifacts.require("StakeModus");
const Token = artifacts.require("Modus");

const totalSupply = ether(BigNumber(1e6));
const depositAmount = ether(BigNumber(500));

const unstakingPeriod = BigNumber(7); //7 Days

const from = (account) => ({ from: account });

contract(
  "ModusStakingContract",
  function ([owner, account1, account2, account3]) {
    describe("1. Before deployment", async function () {
      before(async function () {
        this.token = await Token.new();
        this.token.initialize(
          "Modus",
          "MODUS",
          BigNumber(18),
          totalSupply.toString()
        );
        this.stakingContract = await ModusStakingContract.new();
      });
    });
  }
);
