// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "../wallet/ModusWallet.sol";
import "../interfaces/ITier.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StakingPool is Wallet {
    using SafeMath for uint256;
    enum Tier {
        tier1,
        tier2,
        tier3,
        tier4,
        NONE
    }

    event Staked(address indexed user, uint amount);
    event UnStaked(address indexed user, uint256 amount);
    ITier public tierDetermine;
    address[] public stakers; // addresses that have active stakes
    mapping(address => uint) public stakes;
    mapping(Tier => uint256) public tierAllocation;
    uint public totalStakes;
    uint256 public threshold;
    uint unstackPeriodCount = 7;

    constructor(
        address _modusTokenAddress,
        uint256 _threshold
    ) Wallet(_modusTokenAddress) {
        threshold = _threshold;
        _setTierAllocations();
    }

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

    //Tier allocation
    function _setTierAllocations() internal {
        tierAllocation[Tier.tier1] = threshold.mul(100).div(100);
        tierAllocation[Tier.tier2] = threshold.mul(200).div(100);
        tierAllocation[Tier.tier3] = threshold.mul(400).div(100);
        tierAllocation[Tier.tier4] = threshold.mul(600).div(100);
        tierAllocation[Tier.tier4] = threshold.mul(800).div(100);
    }

    /**
     * @notice Determines the tier of a user based on the amount staked 
    
     * @param _staker The user who's tier needs to be determined
     */
    function _determineTier(address _staker) internal view returns (Tier) {
        // Return tiers based on amount staked
        if (stakes[_staker] >= tierDetermine.tier1()) {
            return Tier.tier1;
        } else if (stakes[_staker] >= tierDetermine.tier2()) {
            return Tier.tier2;
        } else if (stakes[_staker] >= tierDetermine.tier3()) {
            return Tier.tier3;
        } else if (stakes[_staker] >= tierDetermine.tier4()) {
            return Tier.tier4;
        } else {
            return Tier.NONE;
        }
    }
}
