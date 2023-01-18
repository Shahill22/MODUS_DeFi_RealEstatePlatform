// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../tokens/ProjectToken.sol";

import "./Modus.sol";

contract ModusFactory is Modus {
    event PropertyListed(uint256 propertyId, uint256 price);

    function listProperty(uint _price) public returns (uint256) {
        Modus.propertyID = Modus.propertyID + 1;
        Modus.properties[Modus.propertyID] = Modus.Property({
            originalPrice: _price,
            availableRaiseAmount: 0,
            raisedAmount: 0,
            exists: true
        });

        // Create a new instance of the token contract
        ProjectToken newProjectTokenAddress = new ProjectToken(
            msg.sender,
            _price
        );
        // Mint the new token
        //newProjectTokenAddress.mint(msg.sender, _price);
        emit PropertyListed(Modus.propertyID, _price);
        return Modus.propertyID;
    }
}
