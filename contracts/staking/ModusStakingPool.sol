// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "../wallet/ModusWallet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StakingPool is Wallet {
    using SafeMath for uint256;
    uint unstackPeriodCount = 7;

    event Staked(address indexed user, uint amount);
    event UnStaked(address indexed user, uint256 amount);

    address[] public stakers; // addresses that have active stakes
    mapping(address => uint) public stakes;
    uint public totalStakes;

    constructor(address _modusTokenAddress) Wallet(_modusTokenAddress) {}

    function depositAndStartStake(uint256 amount) public {
        deposit(amount);
        startStake(amount);
    }

    function endStakeAndWithdraw(uint amount) public {
        endStake(amount);
        withdraw(amount);
    }

    function startStake(uint amount) public virtual {
        require(amount > 0, "Stake must be a positive amount greater than 0");
        require(balances[msg.sender] >= amount, "Not enough tokens to stake");

        // move tokens from modus token balance to the staked balance
        balances[msg.sender] = balances[msg.sender].sub(amount);
        stakes[msg.sender] = stakes[msg.sender].add(amount);

        totalStakes = totalStakes.add(amount);

        emit Staked(msg.sender, amount);
    }

    function endStake(uint amount) public virtual {
        require(stakes[msg.sender] >= amount, "Not enough tokens staked");
        //require(unstackPeriodCount=0,"Unstaking requires 1 week waiting duration");

        // return modus tokens to modus token balance
        balances[msg.sender] = balances[msg.sender].add(amount);
        stakes[msg.sender] = stakes[msg.sender].sub(amount);

        totalStakes = totalStakes.sub(amount);

        emit UnStaked(msg.sender, amount);
    }

    function getStakedBalance() public view returns (uint) {
        return stakes[msg.sender];
    }

    function reset() public virtual onlyOwner {
        // reset user balances and stakes
        for (uint i = 0; i < usersArray.length; i++) {
            balances[usersArray[i]] = 0;
            stakes[usersArray[i]] = 0;
        }
        totalStakes = 0;
    }
}
