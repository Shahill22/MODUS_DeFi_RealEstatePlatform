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
  let kyotoController, kyotoV1, kyotoV2, kyotoV1ToV2;

  beforeEach(async () => {
    kyotoController = await KyotoController.new(kyotoAdmin);
    kyotoV1 = await KyotoV1.new(kyotoAdmin, user1, user2);
    await kyotoController.setKyotoV1(kyotoV1.address, { from: kyotoAdmin });
    kyotoV2 = await KyotoV2.new(kyotoController.address);
    await kyotoController.setKyotoV2(kyotoV2.address, { from: kyotoAdmin });
    kyotoV1ToV2 = await KyotoV1ToV2.new(kyotoController.address);
    await kyotoController.setKyotoV1ToV2(kyotoV1ToV2.address, {
      from: kyotoAdmin,
    });
  });

  const name = "KyotoProtocolV2";
  const symbol = "KYOTO V2";

  it("has a name", async function () {
    expect(await kyotoV2.name()).to.equal(name);
  });

  it("has a symbol", async function () {
    expect(await kyotoV2.symbol()).to.equal(symbol);
  });

  it("has 5 decimals", async function () {
    expect(await kyotoV2.decimals()).to.be.bignumber.equal("5");
  });

  describe("should return balances", async function () {
    const migrateAmount = web3.utils.toBN(100);
    it("should return balance of normal account", async function () {
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });
      expect(await kyotoV2.balanceOf(user1)).to.be.bignumber.equal(
        migrateAmount
      );
    });

    it("should return balance of rebase account", async function () {
      await kyotoV2.addRebaseAccount(user1, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });
      expect(await kyotoV2.balanceOf(user1)).to.be.bignumber.equal(
        migrateAmount
      );
    });

    it("should return updated balance of rebase account", async function () {
      const rebaseTimes = web3.utils.toBN(96); // 96 * 15 minutes = 1 Day ≈ 2.54% APY
      await kyotoV2.addRebaseAccount(user1, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });
      await kyotoV2.rebase(rebaseTimes, { from: kyotoAdmin });
      expect(await kyotoV2.balanceOf(user1)).to.be.bignumber.greaterThan(
        migrateAmount
      );
    });
  });

  describe("should transfer tokens", async function () {
    const migrateAmount = web3.utils.toBN(100);
    const transferAmount = web3.utils.toBN(50);
    it("from normal to normal account", async function () {
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      const transferReceipt = await kyotoV2.transfer(user2, transferAmount, {
        from: user1,
      });
      expectEvent(transferReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });

    it("from normal to rebase account", async function () {
      await kyotoV2.addRebaseAccount(user2, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      const transferReceipt = await kyotoV2.transfer(user2, transferAmount, {
        from: user1,
      });
      expectEvent(transferReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });

    it("from rebase to rebase normal", async function () {
      await kyotoV2.addRebaseAccount(user1, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      const transferReceipt = await kyotoV2.transfer(user2, transferAmount, {
        from: user1,
      });
      expectEvent(transferReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });

    it("from rebase to rebase account", async function () {
      await kyotoV2.addRebaseAccount(user1, { from: kyotoAdmin });
      await kyotoV2.addRebaseAccount(user2, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      const transferReceipt = await kyotoV2.transfer(user2, transferAmount, {
        from: user1,
      });
      expectEvent(transferReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });
  });

  describe("should transferFrom tokens", async function () {
    const migrateAmount = web3.utils.toBN(100);
    const transferAmount = web3.utils.toBN(50);
    it("from normal to normal account", async function () {
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      await kyotoV2.approve(user2, transferAmount, { from: user1 });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal(
        transferAmount
      );
      const transferFromReceipt = await kyotoV2.transferFrom(
        user1,
        user2,
        transferAmount,
        { from: user2 }
      );
      expectEvent(transferFromReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal("0");

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });

    it("from normal to rebase account", async function () {
      await kyotoV2.addRebaseAccount(user2, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      await kyotoV2.approve(user2, transferAmount, { from: user1 });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal(
        transferAmount
      );
      const transferFromReceipt = await kyotoV2.transferFrom(
        user1,
        user2,
        transferAmount,
        { from: user2 }
      );
      expectEvent(transferFromReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal("0");

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });

    it("from rebase to rebase normal", async function () {
      await kyotoV2.addRebaseAccount(user1, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      await kyotoV2.approve(user2, transferAmount, { from: user1 });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal(
        transferAmount
      );
      const transferFromReceipt = await kyotoV2.transferFrom(
        user1,
        user2,
        transferAmount,
        { from: user2 }
      );
      expectEvent(transferFromReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal("0");

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });
    it("from rebase to rebase account", async function () {
      await kyotoV2.addRebaseAccount(user1, { from: kyotoAdmin });
      await kyotoV2.addRebaseAccount(user2, { from: kyotoAdmin });
      await kyotoV1.approve(kyotoV1ToV2.address, migrateAmount, {
        from: user1,
      });
      await kyotoV1ToV2.swap(migrateAmount, { from: user1 });

      const user1KyotoV2BalanceBefore = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceBefore = await kyotoV2.balanceOf(user2);

      await kyotoV2.approve(user2, transferAmount, { from: user1 });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal(
        transferAmount
      );
      const transferFromReceipt = await kyotoV2.transferFrom(
        user1,
        user2,
        transferAmount,
        { from: user2 }
      );
      expectEvent(transferFromReceipt, "Transfer", {
        from: user1,
        to: user2,
        value: transferAmount,
      });
      expect(await kyotoV2.allowance(user1, user2)).to.bignumber.equal("0");

      const user1KyotoV2BalanceAfter = await kyotoV2.balanceOf(user1);
      const user2KyotoV2BalanceAfter = await kyotoV2.balanceOf(user2);

      expect(
        user2KyotoV2BalanceAfter.sub(user2KyotoV2BalanceBefore)
      ).to.bignumber.equal(transferAmount);
      expect(
        user1KyotoV2BalanceBefore.sub(user1KyotoV2BalanceAfter)
      ).to.bignumber.equal(transferAmount);
    });
  });
});
