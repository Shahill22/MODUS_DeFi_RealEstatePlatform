// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract KYC {
    mapping(address => bool) public approved;
    event Approval(address indexed approvedAddress);

    function approve(address user) public {
        require(msg.sender == msg.sender);
        approved[user] = true;
        emit Approval(user);
    }

    function isApproved(address user) public view returns (bool) {
        return approved[user];
    }

    function checkKYC(address user) public view returns (string memory) {
        if (approved[user]) {
            return "Approved";
        } else {
            return "Not Approved";
        }
    }
}
