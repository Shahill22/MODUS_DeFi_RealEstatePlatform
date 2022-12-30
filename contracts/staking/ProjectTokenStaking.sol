// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ProjectTokenStakingContract {
    /*CONTRACT STATE VARIABLES*/
    IERC20 public projectToken;
    IERC20 public modusToken;
    IERC20 public rewardToken;
    address public owner;
    address public rewardsAddress;
    uint256 public currentTotalStake;
    uint256 public minstakingPeriod;
    uint256 public maxStakingPeriod;

    /* STRUCT DECLARATIONS*/
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
    /*MAPPINGS*/
    mapping(address => StakeDeposit) private _stakeDeposits;
    mapping(address => WithdrawalState) private _withdrawStates;

    // EVENTS
    event StakeDeposited(address indexed account, uint256 amount);
    event WithdrawInitiated(
        address indexed account,
        uint256 amount,
        uint256 initiateDate
    );
    event WithdrawExecuted(
        address indexed account,
        uint256 amount,
        uint256 reward
    );
    event RewardsWithdrawn(address indexed account, uint256 reward);
    event RewardsDistributed(uint256 amount);

    //reward calculations

    uint256 public rewardsDistributed;
    uint256 public rewardsWithdrawnInModus;
    uint256 public rewardsWithdrawnInRewardToken;
    uint256 public totalRewardsDistributed;

    // MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == owner, "ModusStaking: Address unauthorized");
        _;
    }

    /* Constructor */
    constructor(
        address _projectToken,
        address _rewardToken,
        address _modusToken
    ) {
        owner = msg.sender;
        require(_projectToken != address(0), " Invalid token address");

        projectToken = IERC20(_projectToken);

        require(
            _rewardToken != address(0),
            "[Validation] _rewardsAddress is the zero address"
        );
        rewardToken = IERC20(_rewardToken);
        require(
            _modusToken != address(0),
            "[Validation] _modusAddress is the zero address"
        );
        modusToken = IERC20(_modusToken);
    }

    // PUBLIC FUNCTIONS
    function setMaxStakePeriod(uint _months) external onlyOwner {
        if (_months == 12) {
            maxStakingPeriod = 365; //12 months
        } else {
            maxStakingPeriod = 548; //18months
        }
    }

    function setMinStakePeriod(uint _days) external onlyOwner {
        minstakingPeriod = _days;
    }

    function deposit(uint256 amount) external {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        require(
            stakeDeposit.endDate == 0,
            "[Deposit] You have already initiated the withdrawal"
        );

        stakeDeposit.amount += amount;
        stakeDeposit.startDate = block.timestamp;
        stakeDeposit.exists = true;

        currentTotalStake += currentTotalStake;

        // Transfer the Tokens to this contract
        require(
            projectToken.transferFrom(msg.sender, address(this), amount),
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
        uint256 daysPassed = (stakeDeposit.endDate - stakeDeposit.startDate) /
            1 days;
        require(
            daysPassed >= minstakingPeriod,
            "[Withdraw] Min staking period did not pass"
        );

        uint256 amount = withdrawState.amount != 0
            ? withdrawState.amount
            : stakeDeposit.amount;
        uint256 reward = _computeReward(amount, daysPassed);

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
            projectToken.transfer(msg.sender, amount),
            "[Withdraw] Something went wrong while transferring your initial deposit"
        );

        if (reward > 0) {
            //calculate withdrawed rewards in single distribution cycle
            uint256 rewardsToTransfer = (reward * 75) / uint256(100);
            reward -= rewardsToTransfer;
            if (daysPassed < maxStakingPeriod) {
                rewardsWithdrawnInModus += rewardsToTransfer;
                require(
                    modusToken.transferFrom(
                        owner,
                        msg.sender,
                        rewardsToTransfer
                    ),
                    "[Withdraw] Something went wrong while transferring your reward"
                );
            } else {
                rewardsWithdrawnInRewardToken += rewardsToTransfer;
                require(
                    rewardToken.transfer(owner, reward),
                    "[Withdraw] Something went wrong while transferring your reward"
                );
                require(
                    rewardToken.transfer(msg.sender, rewardsToTransfer),
                    "[Withdraw] Something went wrong while transferring your reward"
                );
            }
        }

        _withdrawStates[msg.sender].amount = 0;
        _withdrawStates[msg.sender].initiateDate = 0;

        emit WithdrawExecuted(msg.sender, amount, reward);
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

    function _computeReward(
        uint256 _amount,
        uint256 _daysStaked
    ) private pure returns (uint256) {
        uint256 emissionRate = (((1.259921 * 1000000) / uint256(1000000)) ^
            (_daysStaked)) - 1;
        return (((_amount * emissionRate) * 15) / 100);
    }
}
