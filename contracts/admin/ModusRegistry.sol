// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
/*
contract ModusRegistry is Ownable {
    constructor() Ownable() {}

    mapping(address => bool) public isVerified;
    mapping(address => mapping(address => bool)) public approvals;

    // Verifies that an address is a real estate property owner
    function verify(address _address) public {
        require(msg.sender == owner, "Only the owner can verify addresses.");
        isVerified[_address] = true;
    }

    // Transfers ownership of a property
    function transfer(address _from, address _to, uint256 _tokenId) public {
        require(isVerified[_from], "Sender must be verified.");
        require(isVerified[_to], "Receiver must be verified.");
        require(
            approvals[_from][msg.sender],
            "Only approved addresses can transfer properties."
        );
        require(
            ownerOf(_tokenId) == _from,
            "Token ID does not belong to sender."
        );
        transferFrom(_from, _to, _tokenId);
    }

    // Approves a third party to transfer a property on behalf of the owner
    function approve(address _from, address _to) public {
        require(isVerified[_from], "Sender must be verified.");
        approvals[_from][_to] = true;
    }
}*/
