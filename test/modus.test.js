const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const { ZERO_ADDRESS } = constants;

const Modus = artifacts.require("Modus");

contract("Modus", function (accounts) {
  const [treasury, founder1, founder2] = accounts;
  let modusToken;

  beforeEach(async () => {
    modusToken = await Modus.new(treasury, founder1, founder2);
  });

  const name = "Modus";
  const symbol = "MODUS";

  it("has a name", async function () {
    expect(await modusToken.name()).to.equal(name);
  });

  it("has a symbol", async function () {
    expect(await modusToken.symbol()).to.equal(symbol);
  });

  it("has 18 decimals", async function () {
    expect(await modusToken.decimals()).to.be.bignumber.equal("5");
  });
});
