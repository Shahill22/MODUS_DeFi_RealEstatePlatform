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
const ProjectTokenStakingContract = artifacts.require(
  "ProjectTokenStakingContract"
);
const Modus = artifacts.require("Modus");
const PTToken = artifacts.require("ProjectToken");
const PRTToken = artifacts.require("ProjectRewardToken");

const totalSupply = ether(BN(1e6));
const depositAmount = BN(1520);
const minstakingPeriod = BN(30); //30 Days
const maxstakingPeriod1 = BN(365); //12 months
const maxstakingPeriod2 = BN(548); //15 months

const from = (account) => ({ from: account });

contract(
  "ProjectTokenStakingContract",
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
      modus = await Modus.new(treasury, founder1, founder2);
      projectToken = await PTToken.new(treasury);
      projectRewardToken = await PRTToken.new(treasury);
      stakingContract = await ProjectTokenStakingContract.new(
        projectToken.address,
        projectRewardToken.address,
        modus.address
      );
    });
    describe("1. On deployment", async function () {
      it("1.1. should set deployer as default owner", async function () {
        expect(await stakingContract.owner()).to.equal(owner);
      });
      it("1.2. should set the token correctly", async function () {
        expect(await stakingContract.projectToken()).to.equal(
          projectToken.address
        );
      });
      it("1.3. should revert if any token address is zero", async function () {
        await expectRevert(
          ProjectTokenStakingContract.new(
            ZERO_ADDRESS,
            projectRewardToken.address,
            modus.address
          ),
          " Invalid token address"
        );
      });
    });
  }
);
