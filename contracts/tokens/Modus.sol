// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Modus is ERC20 {
    constructor(
        address treasury,
        address founder1,
        address founder2
    ) ERC20("Modus", "MODUS") {
        _mint(treasury, 500000 * 10 ** decimals());
        _mint(founder1, 250000 * 10 ** decimals());
        _mint(founder2, 250000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
