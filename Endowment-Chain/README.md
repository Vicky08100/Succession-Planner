# EternalLegacy: Multi-Tiered Endowment Fund with Succession Planning

## Overview

EternalLegacy is a robust smart contract built on the Stacks blockchain designed to create and manage endowment funds with sophisticated succession planning capabilities. This contract enables users to secure their digital assets with configurable multi-tier succession plans, ensuring wealth transfer based on customizable inactivity periods.

## Key Features

### Fund Management
- **Deposit System**: Users can deposit STX into the contract
- **Returns Management**: Simulation of fund growth (5% return calculation)
- **Transparency**: Comprehensive read-only functions to check fund status

### Endowment System
- **Beneficiary Registration**: Create endowments with designated beneficiaries
- **Democratic Support**: Users can vote to support specific endowments
- **Returns Distribution**: Mechanism to distribute returns to endowments

### Multi-Tiered Succession Planning
- **Three-Tier System**: Configure up to three levels of heirs with different parameters
- **Time-Lock Mechanism**: Successors can only claim funds after predetermined inactivity periods
- **Percentage-Based Allocation**: Specify what percentage of funds each successor receives
- **Alert System**: Notification structure for heirs about their eligibility status

## Technical Details

### Constants
- `ERR-UNAUTHORIZED-ACCESS`: Error returned when unauthorized access is attempted
- `ERR-INSUFFICIENT-FUNDS`: Error when transaction lacks sufficient funds
- `ERR-INVALID-ENDOWMENT-DATA`: Error for invalid endowment record access
- `ERR-ALREADY-VOTED`: Error when voter attempts to vote twice
- `ERR-TRANSACTION-FAILED`: Error when STX transfer fails
- `ERR-INVALID-TIER-LEVEL`: Error for invalid succession tier configuration
- `ERR-SUCCESSOR-NOT-REGISTERED`: Error when accessing nonexistent successor record
- `ERR-NOT-DESIGNATED-SUCCESSOR`: Error when non-successor attempts to access succession data
- `ERR-TIMELOCK-ACTIVE`: Error when attempting to access time-locked funds

### Data Structures

#### Maps
- `user-deposits`: Tracks user deposits in the fund
- `registered-endowments`: Stores endowment information including beneficiary and vote count
- `endowment-voter-registry`: Records voters for each endowment to prevent duplicate voting
- `inheritance-configuration`: Stores succession tier settings for each user
- `heir-notification-registry`: Tracks notification status for heirs

#### Variables
- `fund-total-balance`: Tracks total STX deposited in the contract
- `fund-generated-returns`: Stores undistributed returns
- `fund-last-activity-timestamp`: Records timestamp of last contract interaction

## Function Reference

### Fund Management Functions

#### `deposit-funds()`
Allows users to deposit STX into the contract.
- **Returns**: Amount deposited

#### `compute-fund-returns()`
Calculates the returns for the fund (simulated at 5%).
- **Returns**: Amount of returns generated

#### `send-returns-to-endowment(endowment-name)`
Distributes accumulated returns to a specific endowment.
- **Parameters**:
  - `endowment-name`: Name of the endowment to receive returns
- **Returns**: Amount distributed

### Endowment Management Functions

#### `create-endowment(endowment-name, beneficiary-address)`
Creates a new endowment with specified beneficiary.
- **Parameters**:
  - `endowment-name`: Name for the endowment (limited to 64 ASCII characters)
  - `beneficiary-address`: Principal address of the beneficiary
- **Access**: Admin only
- **Returns**: Boolean success value

#### `vote-for-endowment(endowment-name)`
Allows users to vote in support of an endowment.
- **Parameters**:
  - `endowment-name`: Name of the endowment to support
- **Returns**: Boolean success value

### Succession Planning Functions

#### `configure-succession-tier(tier-level, inactivity-period, heir-address, allocation-percentage)`
Sets up a succession tier with specific parameters.
- **Parameters**:
  - `tier-level`: Tier level (1-3)
  - `inactivity-period`: Number of blocks of inactivity before heir can claim
  - `heir-address`: Principal address of the heir
  - `allocation-percentage`: Percentage of funds to allocate (0-100)
- **Returns**: Boolean success value

#### `delete-succession-tier(tier-level)`
Removes a succession tier configuration.
- **Parameters**:
  - `tier-level`: Tier level to remove (1-3)
- **Returns**: Boolean success value

#### `verify-succession-eligibility()`
Checks and updates the status of caller's succession eligibility.
- **Returns**: Boolean success value

### Read-Only Functions

#### `get-fund-status()`
Returns the current fund status.
- **Returns**: Object containing total assets and undistributed returns

#### `view-succession-tier(owner-address, tier-level)`
Retrieves information about a specific succession tier.
- **Parameters**:
  - `owner-address`: Principal address of the fund owner
  - `tier-level`: Tier level to query (1-3)
- **Returns**: Succession tier details

#### `get-user-deposit(user-address)`
Gets the deposit amount for a specific user.
- **Parameters**:
  - `user-address`: Principal address of the user
- **Returns**: Deposit amount

#### `get-endowment-details(endowment-name)`
Retrieves details about a specific endowment.
- **Parameters**:
  - `endowment-name`: Name of the endowment
- **Returns**: Endowment details including beneficiary and vote count

#### `get-total-fund-assets()`
Returns the total assets in the fund.
- **Returns**: Total fund balance

#### `get-undistributed-returns()`
Returns the accumulated returns not yet distributed.
- **Returns**: Undistributed returns amount

#### `get-last-activity-timestamp()`
Returns the timestamp of the last contract interaction.
- **Returns**: Last activity timestamp in block height

#### `get-heir-notification-status(heir-address, owner-address)`
Gets the notification status for a specific heir.
- **Parameters**:
  - `heir-address`: Principal address of the heir
  - `owner-address`: Principal address of the fund owner
- **Returns**: Notification status details

## Usage Examples

### Setting Up a Basic Succession Plan

```clarity
;; Deposit funds into the contract
(contract-call? .eternal-legacy deposit-funds)

;; Set up first tier successor - 30 day waiting period, 50% allocation
(contract-call? .eternal-legacy configure-succession-tier u1 u4320 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u50)

;; Set up second tier successor - 90 day waiting period, 30% allocation
(contract-call? .eternal-legacy configure-succession-tier u2 u12960 'SPNWZ5V2V5RB9MP66SW86PYKKJ6ZY48GV1EZNRV9 u30)

;; Set up third tier successor - 180 day waiting period, 20% allocation
(contract-call? .eternal-legacy configure-succession-tier u3 u25920 'SP6SW86PYKKJ6ZY48GV1EZNRV9NWZ5V2V5RB9MP u20)
```

### Creating and Supporting an Endowment

```clarity
;; Admin creates an endowment
(contract-call? .eternal-legacy create-endowment "Education Fund" 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Users vote to support the endowment
(contract-call? .eternal-legacy vote-for-endowment "Education Fund")

;; Calculate returns
(contract-call? .eternal-legacy compute-fund-returns)

;; Distribute returns to the endowment
(contract-call? .eternal-legacy send-returns-to-endowment "Education Fund")
```

### Checking Succession Status (as an heir)

```clarity
;; Heir checks their succession status
(contract-call? .eternal-legacy verify-succession-eligibility)

;; Heir views their notification status
(contract-call? .eternal-legacy get-heir-notification-status tx-sender 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## Security Considerations

1. **Time-Based Security**: The contract uses block height for timing mechanisms, which is secure but approximate
2. **Admin Privileges**: Contract admin has authority to create endowments
3. **Successor Privacy**: Succession information is publicly visible on the blockchain
4. **No Emergency Withdrawal**: No emergency fund withdrawal mechanism exists by design

## Deployment Guide

1. **Compilation**: Compile the contract using Clarity tools
2. **Deployment**: Deploy to the Stacks blockchain
3. **Initialization**: As contract admin, initialize any necessary endowments
4. **User Setup**: Users should deposit funds and configure succession tiers