// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";

contract realEstateTransaction is Ownable {
    constructor() Ownable() {}

    event Mint(address indexed _to, uint16 tokenProperty, string status);
    event noMint(address indexed _to, string status);
    event LogForSale(string _addressName, uint16 propertyID, uint _price);
    event LogSold(string addressName, uint16 propertyToken);
    event NewOwner(uint16 propertyToken, address _newOwner, string status);
    uint16 propertyID = 0;
    mapping(uint16 => address) internal idToOwner;
    mapping(uint16 => string) public idToProperty;
    mapping(uint16 => Property) public properties;

    struct Property {
        string propertyName;
        uint price;
        address payable seller;
    }

    function listPropertyForSale(
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

        emit LogForSale(_propertyName, propertyID, _price);
        return propertyID;
    }
}
