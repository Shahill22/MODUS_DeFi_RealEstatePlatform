// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingContract {
    // EVENTS
    event StakeDeposited(address indexed account, uint256 amount);
    event WithdrawInitiated(
        address indexed account,
        uint256 amount,
        uint256 initiateDate
    );
    event WithdrawExecuted(address indexed account, uint256 amount);

    // STRUCT DECLARATIONS
    struct StakeDeposit {
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        bool exists;
    }

    // STRUCT WITHDRAWAL
    struct WithdrawalState {
        uint256 initiateDate;
        uint256 amount;
    }

    // CONTRACT STATE VARIABLES
    IERC20 public token;
    address public owner;
    uint256 public currentTotalStake;
    uint256 public unstakingPeriod;

    mapping(address => StakeDeposit) private _stakeDeposits;
    mapping(address => WithdrawalState) private _withdrawStates;

    // MODIFIERS

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "[Validation] The address is not authorized"
        );
        _;
    }

    constructor(address _stakingToken, uint256 _unstakingPeriod) {
        owner = msg.sender;
        _StakingContract_init(_stakingToken, _unstakingPeriod);
    }

    // PUBLIC FUNCTIONS

    function _StakingContract_init(
        address _token,
        uint256 _unstakingPeriod
    ) internal {
        require(
            _token != address(0),
            "[Validation] Invalid swap token address"
        );

        token = IERC20(_token);
        unstakingPeriod = _unstakingPeriod;
    }

    function setTokenAddress(address _token) external onlyOwner {
        require(
            _token != address(0),
            "[Validation] Invalid swap token address"
        );
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        require(
            stakeDeposit.endDate == 0,
            "[Deposit] You have already initiated the withdrawal"
        );

        stakeDeposit.amount = amount;
        stakeDeposit.startDate = block.timestamp;
        stakeDeposit.exists = true;

        currentTotalStake += amount;

        // Transfer the Tokens to this contract
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "[Deposit] Something went wrong during the token transfer"
        );

        emit StakeDeposited(msg.sender, amount);
    }

    function initiateWithdrawal(uint256 withdrawAmount) external {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        WithdrawalState storage withdrawState = _withdrawStates[msg.sender];
        require(
            withdrawAmount > 0,
            "[Initiate Withdrawal] Invalid withdrawal amount"
        );
        require(
            withdrawAmount <= stakeDeposit.amount,
            "[Initiate Withdrawal] Withdraw amount exceed the stake amount"
        );
        require(
            stakeDeposit.exists && stakeDeposit.amount != 0,
            "[Initiate Withdrawal] There is no stake deposit for this account"
        );
        require(
            stakeDeposit.endDate == 0,
            "[Initiate Withdrawal] You have already initiated the withdrawal"
        );
        require(
            withdrawState.amount == 0,
            "[Initiate Withdrawal] You have already initiated the withdrawal"
        );

        stakeDeposit.endDate = block.timestamp;
        withdrawState.amount = withdrawAmount;
        withdrawState.initiateDate = block.timestamp;

        currentTotalStake = currentTotalStake - withdrawAmount;

        emit WithdrawInitiated(msg.sender, withdrawAmount, block.timestamp);
    }

    function executeWithdrawal() external {
        StakeDeposit memory stakeDeposit = _stakeDeposits[msg.sender];
        WithdrawalState memory withdrawState = _withdrawStates[msg.sender];

        require(
            stakeDeposit.endDate != 0 || withdrawState.amount != 0,
            "[Withdraw] Withdraw amount is not initialized"
        );
        require(
            stakeDeposit.exists && stakeDeposit.amount != 0,
            "[Withdraw] There is no stake deposit for this account"
        );

        // validate enough days have passed from initiating the withdrawal
        uint256 daysPassed = (block.timestamp - stakeDeposit.endDate) / 1 days;
        require(
            unstakingPeriod <= daysPassed,
            "[Withdraw] The unstaking period did not pass"
        );

        uint256 amount = withdrawState.amount != 0
            ? withdrawState.amount
            : stakeDeposit.amount;

        require(
            stakeDeposit.amount >= amount,
            "[withdraw] Remaining stakedeposit amount must be higher than withdraw amount"
        );
        if (stakeDeposit.amount > amount) {
            _stakeDeposits[msg.sender].amount =
                (_stakeDeposits[msg.sender].amount) -
                (amount);
            _stakeDeposits[msg.sender].endDate = 0;
        } else {
            delete _stakeDeposits[msg.sender];
        }

        require(
            token.transfer(msg.sender, amount),
            "[Withdraw] Something went wrong while transferring your initial deposit"
        );

        _withdrawStates[msg.sender].amount = 0;
        _withdrawStates[msg.sender].initiateDate = 0;

        emit WithdrawExecuted(msg.sender, amount);
    }

    // VIEW FUNCTIONS FOR HELPING THE USER AND CLIENT INTERFACE
    function getStakeDetails(
        address account
    )
        external
        view
        returns (uint256 initialDeposit, uint256 startDate, uint256 endDate)
    {
        require(
            _stakeDeposits[account].exists &&
                _stakeDeposits[account].amount != 0,
            "[Validation] This account doesn't have a stake deposit"
        );

        StakeDeposit memory s = _stakeDeposits[account];

        return (s.amount, s.startDate, s.endDate);
    }
}
