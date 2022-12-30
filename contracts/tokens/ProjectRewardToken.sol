// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./ERC1594.sol";
import "./ERC20Detailed.sol";

contract ProjectRewardToken is ERC1594, ERC20Detailed {
    constructor(
        address treasury
    ) ERC20Detailed("Project Reward Token", "PRT", 18) {
        _mint(treasury, 1000000 * 10 ** 18);
    }

    event IssuanceFinalized();

    function finalizeIssuance() external onlyOwner {
        require(issuance, "Issuance already closed");
        issuance = false;
        emit IssuanceFinalized();
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
