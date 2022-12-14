//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ITier {
    /**
     * @notice The total number of tokens required to be staked to be in tier1
     * Tier
     * @return uint256 The number of tokens
     */
    function tier1() external view returns (uint256);

    /**
     * @notice The total number of tokens required to be staked to be in tier2
     * Tier
     * @return uint256 The number of tokens
     */
    function tier2() external view returns (uint256);

    /**
     * @notice The total number of tokens required to be staked to be in tier3
     * Tier
     * @return uint256 The number of tokens
     */
    function tier3() external view returns (uint256);

    /**
     * @notice The total number of tokens required to be staked to be in tier4
     * Tier
     * @return uint256 The number of tokens
     */
    function tier4() external view returns (uint256);
}
