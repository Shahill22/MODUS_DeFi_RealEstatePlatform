// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ModusStakingContract {
    /* Contract state variables */
    IERC20 public token;
    address public owner;
    uint256 public currentTotalStake;
    uint256 public unstakingPeriod;
    uint256 public tierID = 0;
    uint256 public totalTiers = 0;

    /* Struct Declarations */
    struct StakeDeposit {
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        bool exists;
    }

    struct WithdrawalState {
        uint256 initiateDate;
        uint256 amount;
    }

    struct Tier {
        uint256 tokensToStake;
        uint256 investorsCount;
    }

    /* Mappings */
    mapping(address => StakeDeposit) private _stakeDeposits;
    mapping(address => WithdrawalState) private _withdrawStates;
    mapping(uint256 => Tier) public tierAllocated;

    /* Events */
    event StakeDeposited(address indexed account, uint256 amount);
    event WithdrawInitiated(
        address indexed account,
        uint256 amount,
        uint256 initiateDate
    );
    event WithdrawExecuted(address indexed account, uint256 amount);
    event TierAdded(uint256 IDtier, uint256 tierStakeAmount);
    event TierUpdated(uint256 IDtier, uint256 tierStakeAmount);

    /* Modifiers */
    modifier onlyOwner() {
        require(msg.sender == owner, "ModusStaking: Address unauthorized");
        _;
    }

    /* Constructor */
    constructor(address _stakingToken, uint256 _unstakingPeriod) {
        owner = msg.sender;
        require(
            _stakingToken != address(0),
            "ModusStaking: Invalid token address"
        );

        token = IERC20(_stakingToken);
        unstakingPeriod = _unstakingPeriod;
    }

    /* Owner Functions */

    /**
     * @notice This function is used to set modus token address
     * @dev only the owner can call this function
     * @param _token Address of the modus token
     */
    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "ModusStaking: Invalid token address");
        token = IERC20(_token);
    }

    /**
     * @notice This function is used to set Tiers based on modus staked
     * @dev only the owner can call this function
     * @param _tokensToStake Amount of the modus token for each Tier
     */
    function setTiers(uint256 _tokensToStake) external onlyOwner {
        tierID += 1;
        require(tierID != 0, "ModusStaking: Invalid tier ID");
        require(
            _tokensToStake > tierAllocated[tierID - 1].tokensToStake,
            "ModusStaking: Token for this tier must be in sorted order "
        );
        tierAllocated[tierID] = Tier(_tokensToStake, 0);
        totalTiers++;
        emit TierAdded(tierID, _tokensToStake);
    }

    /**
     * @notice This function is used to set Tiers based on modus staked
     * @dev only the owner can call this function
     * @param _tokensToStake Amount of the modus token for each Tier
     * @param _tierID ID of the tier to be updated
     */
    function updateTiers(
        uint256 _tierID,
        uint256 _tokensToStake
    ) external onlyOwner {
        require(_tierID != 0, "ModusStaking: Invalid tier ID");
        require(
            _tokensToStake > tierAllocated[_tierID - 1].tokensToStake,
            "ModusStaking: Token for this tier must be greater than previous tier "
        );
        require(
            _tokensToStake < tierAllocated[_tierID + 1].tokensToStake,
            "ModusStaking: Token for this tier must be less than tier after "
        );
        tierAllocated[_tierID] = Tier(_tokensToStake, 0);
        emit TierUpdated(_tierID, _tokensToStake);
    }

    /* Tier */
    /**
     * @notice This function is used to determine Tiers based on modus staked
     * @param _stakedAmount Amount of the modus token staked by user
     * @return tier Returns the tier ID
     */
    function determineTiers(
        uint256 _stakedAmount
    ) public view returns (uint256 tier) {
        require(
            _stakedAmount != 0,
            "ModusStaking: This account doesn't have a stake deposit"
        );
        uint256 low = 1;
        uint256 high = totalTiers;
        require(
            _stakedAmount >= tierAllocated[low].tokensToStake,
            "ModusStaking: Stake deposit lower for any tier "
        );
        if (totalTiers == 1) {
            return 1;
        } else if (_stakedAmount >= tierAllocated[totalTiers].tokensToStake) {
            return totalTiers;
        } else {
            while (low < high) {
                uint256 mid = Math.average(low, high);
                if (tierAllocated[mid].tokensToStake > _stakedAmount) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }
            return low - 1;
        }
    }

    /**
     * @notice This function is used to determine total investors in a tier
     * @param _tierID Tier ID of the user
     * @return  Returns the investors count in each tier
     */
    function totalInvestorsInTier(
        uint256 _tierID
    ) external view returns (uint256) {
        return tierAllocated[_tierID].investorsCount;
    }

    /**
     * @notice This function is used to determine stake amount for a tier
     * @param _tierID Tier ID of the user
     * @return  Returns stake amount in each tier
     */
    function stakeTokensInTier(
        uint256 _tierID
    ) external view returns (uint256) {
        return tierAllocated[_tierID].tokensToStake;
    }

    /* Staking */
    /**
     * @notice This function is used to deposit and stake the modus token
     * @param amount Amount of the modus token the user wish to stake
     */
    function deposit(uint256 amount) external {
        require(
            amount != 0,
            "ModusStaking: The stake deposit has to be larger than 0"
        );
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        uint256 currentTierInvestorsCount;
        uint256 currentTierID;
        if (stakeDeposit.exists) {
            currentTierID = determineTiers(stakeDeposit.amount);
            currentTierInvestorsCount = tierAllocated[currentTierID]
                .investorsCount;
        }
        stakeDeposit.amount += amount;
        stakeDeposit.startDate = block.timestamp;
        stakeDeposit.exists = true;

        currentTotalStake += amount;

        // Transfer the Tokens to this contract
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "ModusStaking: Something went wrong during the token transfer"
        );
        uint256 toTier = determineTiers(stakeDeposit.amount);
        tierAllocated[toTier].investorsCount += 1;
        if (currentTierInvestorsCount != 0) {
            tierAllocated[currentTierID].investorsCount -= 1;
        }

        emit StakeDeposited(msg.sender, amount);
    }

    /**
     * @notice This function is used to initiate withdrawal of tokens staked
     * @param withdrawAmount Amount of the modus token user wish to withdraw
     */
    function initiateWithdrawal(uint256 withdrawAmount) external {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        WithdrawalState storage withdrawState = _withdrawStates[msg.sender];
        require(withdrawAmount > 0, "ModusStaking: Invalid withdrawal amount");
        require(
            stakeDeposit.amount != 0,
            "ModusStaking: There is no stake deposit for this account"
        );
        require(
            withdrawAmount <= stakeDeposit.amount,
            "ModusStaking: Withdraw amount exceed the stake amount"
        );

        require(
            stakeDeposit.endDate == 0,
            "ModusStaking: You have already initiated the withdrawal"
        );
        require(
            withdrawState.amount == 0,
            "ModusStaking: You have already initiated the withdrawal"
        );
        // set stakeDeposit end to current block timestamp (for struct StakeDeposit)
        stakeDeposit.endDate = block.timestamp;
        withdrawState.amount = withdrawAmount;
        withdrawState.initiateDate = block.timestamp;

        currentTotalStake = currentTotalStake - withdrawAmount;

        emit WithdrawInitiated(msg.sender, withdrawAmount, block.timestamp);
    }

    /**
     * @notice This function is used to execute withdrawal after its initialized
     */
    function executeWithdrawal() external {
        StakeDeposit memory stakeDeposit = _stakeDeposits[msg.sender];
        //get withdraw state of the user (amount and initiate date)
        WithdrawalState memory withdrawState = _withdrawStates[msg.sender];

        require(
            // stakeDeposit.endDate != 0 as timestamp of block recorded when withdrawal initiated
            stakeDeposit.endDate != 0 || withdrawState.amount != 0,
            "ModusStaking: Withdraw is not initialized"
        );
        require(
            stakeDeposit.amount != 0,
            "ModusStaking: There is no stake deposit for this account"
        );

        // validate enough days have passed from initiating the withdrawal
        uint256 daysPassed = (block.timestamp - stakeDeposit.endDate) / 1 days;
        require(
            unstakingPeriod <= daysPassed,
            "ModusStaking: The unstaking period did not pass"
        );

        //current tier before withdrawal
        uint256 currentTier = determineTiers(stakeDeposit.amount);

        uint256 amount = withdrawState.amount;

        require(
            stakeDeposit.amount >= amount,
            "ModusStaking: Remaining stakedeposit amount must be higher than withdraw amount"
        );
        if (stakeDeposit.amount > amount) {
            _stakeDeposits[msg.sender].amount =
                (_stakeDeposits[msg.sender].amount) -
                (amount);
            _stakeDeposits[msg.sender].endDate = 0;
        }

        require(
            token.transfer(msg.sender, amount),
            "ModusStaking: Something went wrong while transferring your initial deposit"
        );

        _withdrawStates[msg.sender].amount = 0;
        _withdrawStates[msg.sender].initiateDate = 0;

        //update investors tier count with current stake value
        uint256 latestTier = determineTiers(_stakeDeposits[msg.sender].amount);
        tierAllocated[latestTier].investorsCount += 1;
        //emit WithdrawExecuted(msg.sender, amount);
        if (_stakeDeposits[msg.sender].amount == 0) {
            tierAllocated[currentTier].investorsCount -= 1;
            delete _stakeDeposits[msg.sender];
        }
        // reducing the investors count of previous tier
        if (_stakeDeposits[msg.sender].amount != 0) {
            tierAllocated[currentTier].investorsCount -= 1;
        }
        emit WithdrawExecuted(msg.sender, amount);
    }

    // VIEW FUNCTIONS FOR HELPING THE USER AND CLIENT INTERFACE
    /**
     * @notice Helper function to get the stake details of the user
     * @param account Address of the user staked
     * @return initialDeposit Returns the stake deposit of the user
     * @return startDate Returns the start date of staking
     * @return endDate Returns the end date of staking
     */
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
            "ModusStaking: This account doesn't have a stake deposit"
        );

        StakeDeposit memory s = _stakeDeposits[account];

        return (s.amount, s.startDate, s.endDate);
    }
}
