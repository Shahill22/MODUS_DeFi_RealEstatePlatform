// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract USDC is ERC20, ERC20Burnable, Ownable {
    constructor(
        address user1,
        address user2,
        address user3,
        address user4
    ) ERC20("USDC", "USDC") {
        _mint(user1, 10000 * (10 ** uint256(decimals())));
        _mint(user2, 10000 * (10 ** uint256(decimals())));
        _mint(user3, 10000 * (10 ** uint256(decimals())));
        _mint(user4, 10000 * (10 ** uint256(decimals())));
    }

    function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }
}
