// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";

contract realEstateTransaction is Ownable {
    constructor() Ownable() {}

    uint16 propertyID = 0;
    mapping(uint16 => address) internal idToOwner;
    mapping(uint16 => string) public idToProperty;
    mapping(uint16 => Property) public properties;

    struct Property {
        string propertyName;
        uint price;
        address payable seller;
    }

    function listProperty(
        string calldata _propertyName,
        uint _price
    ) public returns (uint16) {
        propertyID = propertyID + 1;
        require(idToOwner[propertyID] == msg.sender, "is not the owner!");
        properties[propertyID] = Property({
            propertyName: _propertyName,
            price: _price,
            seller: payable(msg.sender)
        });

        return propertyID;
    }
}
