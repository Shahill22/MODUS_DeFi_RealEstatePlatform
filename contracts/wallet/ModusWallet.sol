// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    using SafeMath for uint256;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    IERC20 internal MODUS;

    // Modus token balances
    mapping(address => uint256) public balances;

    // users that deposited Modus tokens into their balances
    address[] internal usersArray;
    mapping(address => bool) internal users;

    constructor(address _modusTokenAddress) {
        MODUS = IERC20(_modusTokenAddress);
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Deposit amount should not be 0");
        require(
            MODUS.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );

        balances[msg.sender] = balances[msg.sender].add(amount);

        // addresses that deposited tokens
        if (!users[msg.sender]) {
            users[msg.sender] = true;
            usersArray.push(msg.sender);
        }

        MODUS.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient token balance");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        MODUS.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }
}
