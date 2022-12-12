// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./ERC1594.sol";
import "./ERC20Detailed.sol";

contract ProjectToken is ERC1594, ERC20Detailed {
    //added ERC1594 for token transfer restrictions
    constructor(address treasury) ERC20Detailed("Project Token", "PT", 18) {
        _mint(treasury, maxSupply());
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

    function maxSupply() public pure returns (uint256) {
        return 1000000 * 10 ** 18;
    }
}
