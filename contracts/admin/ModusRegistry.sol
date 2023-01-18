// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ModusRegistry is Ownable {
    address modusContract;

    constructor(address _modusContractAddress) Ownable() {
        require(
            _modusContractAddress != address(0),
            "ModusRegistry: Invalid token address"
        );

        modusContract = _modusContractAddress;
    }
}
