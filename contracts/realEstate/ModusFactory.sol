// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../staking/ModusStaking.sol";
import "../tokens/ProjectToken.sol";

contract ModusFactory is Ownable {
    ModusStakingContract MS;
    uint16 propertyID;
    IERC20 public token;

    mapping(uint256 => string) public idToProperty;
    mapping(uint256 => Property) public properties;
    mapping(uint256 => uint256) public tierToEligibleAmount;
    mapping(address => uint256) public investments;

    struct Property {
        string propertyName;
        uint256 originalPrice;
        uint256 availableRaiseAmount;
        uint256 raisedAmount;
        bool exists;
    }

    constructor(address _tokenAddress) Ownable() {
        require(
            _tokenAddress != address(0),
            "ModusStaking: Invalid token address"
        );

        token = IERC20(_tokenAddress);
    }

    function assignTierstoEligibleAmount(
        uint256 _tier,
        uint256 _eligibleAmount
    ) external onlyOwner {
        require(MS.tierID() != 0, "ModusFactory: No tiers Present");
        require(
            _tier > 0 && _tier <= MS.tierID(),
            "ModusFactory: Invalid tier ID"
        );
        tierToEligibleAmount[_tier] = _eligibleAmount;
    }

    function listProperty(
        string calldata _propertyName,
        uint _price
    ) public onlyOwner returns (uint16) {
        propertyID = propertyID + 1;
        properties[propertyID] = Property({
            propertyName: _propertyName,
            originalPrice: _price,
            availableRaiseAmount: 0,
            raisedAmount: 0,
            exists: true
        });

        return propertyID;
    }

    function invest(uint256 _propertyID, uint _amount) public payable {
        require(_amount > 0, "ModusFactory: Amount must be greater than zero");
        require(
            _propertyID > 0 && properties[_propertyID].exists,
            "ModusFactory: Invalid property"
        );
        require(
            _amount <= properties[_propertyID].originalPrice,
            "ModusFactory: Amount greater than required amount"
        );
        require(
            _amount <= properties[propertyID].availableRaiseAmount,
            "ModusFactory: Amount greater than required raise amount"
        );

        require(token.transfer(msg.sender, _amount), "Token transfer failed.");
        properties[propertyID].raisedAmount += _amount;
        properties[propertyID].availableRaiseAmount =
            properties[propertyID].originalPrice -
            properties[propertyID].raisedAmount;

        investments[msg.sender] += _amount;
    }
}
