// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import {IAdmin} from "../interfaces/IAdmin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdminFacet is IAdmin {
    ClimetaStorage internal s;

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function adminFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    /////////////// GETTERS ////////////////////////////

    /// @notice gets the Ops Treasury address.
    function getOpsTreasuryAddress() external view returns(address)  {
        return s.opsTreasuryAddress;
    }
    /// @notice gets the DelMundo contract address.
    function getDelMundoAddress() external view returns(address)  {
        return s.delMundoAddress;
    }
    /// @notice gets the DelMundoTraits contract address.
    function getDelMundoTraitAddress() external view returns(address)  {
        return s.delMundoTraitAddress;
    }
    /// @notice gets the DelMundoTraits contract address.
    function getDelMundoWalletAddress() external view returns(address)  {
        return s.delMundoWalletAddress;
    }
    /// @notice gets the LP address on Uniswap v4 for the Raywards/USDX pool.
    function getLiquidityPoolAddress() external view returns(address)  {
        return s.liquidityPoolAddress;
    }
    /// @notice gets the Rayward contract address.
    function getRaywardAddress() external view returns(address)  {
        return s.raywardAddress;
    }
    /// @notice gets the Raycognition contract address.
    function getRaycognitionAddress() external view returns(address)  {
        return s.raycognitionAddress;
    }
    /// @notice gets the ERC6551 Registry address.
    function getRegistryAddress() external view returns(address)  {
        return s.registryAddress;
    }
    /// @notice gets the address of Ray Del Mundos Wallet (Reward Pool).
    function getRayWalletAddress() external view returns(address)  {
        return s.rayWalletAddress;
    }

    /// @notice gets the amount of raywards given for the voting round.
    function getVotingRoundReward() external view returns(uint256)  {
        return s.votingRoundReward;
    }
    /// @notice Sets the amount of raywards given for the voting round. Can only be called by Admins
    /// @param _rewardAmount The new reward amount
    function setVotingRoundReward(uint256 _rewardAmount) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__VotingRewardChanged(_rewardAmount);
        s.votingRoundReward = _rewardAmount;
    }

    /// @notice gets the amount of raywards given for a single vote.
    function getVoteReward() external view returns(uint256)  {
        return s.voteReward;
    }
    /// @notice Sets the amount of raywards given for a single vote. Can only be called by Admins
    /// @param _rewardAmount The new reward amount
    function setVoteReward(uint256 _rewardAmount) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__VoteRewardChanged(_rewardAmount);
        s.voteReward = _rewardAmount;
    }

    /// @notice gets the amount of raywards given for a single vote.
    function getVoteRaycognition() external view returns(uint256)  {
        return s.voteRaycognitionAmount;
    }
    /// @notice Sets the amount of raywards given for a single vote. Can only be called by Admins
    /// @param _rewardAmount The new reward amount
    function setVoteRaycognition(uint256 _rewardAmount) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__VoteRaycognitionChanged(_rewardAmount);
        s.voteRaycognitionAmount = _rewardAmount;
    }
    /// @notice Sets the address of Ray's DelMundo Wallet when it is created.
    /// @param _rayWalletAddress The new address
    function setRayWalletAddress(address _rayWalletAddress) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__RayWalletChanged(_rayWalletAddress);
        s.rayWalletAddress = _rayWalletAddress;
    }
    /// @notice Sets the address of traits
    /// @param _traitAddress The new reward amount
    function setDelMundoTraitAddress(address _traitAddress) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__TraitAddressChanged(_traitAddress);
        s.delMundoTraitAddress = _traitAddress;
    }
    /// @notice Sets the amount of raywards given for the voting round. Can only be called by Admins
    /// @param _withdrawRewardOnly The new reward amount
    function setWithdrawalOnly(bool _withdrawRewardOnly) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__RewardWithdrawalTypeChange(_withdrawRewardOnly);
        s.withdrawRewardsOnly = _withdrawRewardOnly;
    }
    /// @notice Sets the amount of raywards given for the voting round. Can only be called by Admins
    /// @param _lp The liquidity pool address of the Rayward/Stablecoin pair
    function setLiquidityPoolAddress(address _lp) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__LiquidityPoolAddressChanged(_lp);
        s.liquidityPoolAddress = _lp;
    }


    /////////////// SETTERS ////////////////////////////

    /**
    * @dev Update the ops address. Should be rarely called, if ever, but need the capability to do so. Covered by the onlyAdmin modifier
    * to ensure only admins can do this, given this is a 10% diversion of funds.
    * @param _ops The address of the new ops treasury.
    */
    function updateOpsTreasuryAddress(address payable _ops) external {
        LibDiamond.enforceIsContractOwner();
        s.opsTreasuryAddress = _ops;
    }

    /// @notice Checks the ERC20 against list of allowed tokens
    /// @param _token The token to check
    function isAllowedToken(address _token) internal view returns(bool) {
        uint256 length = s.allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    /// @notice Get array of allowed tokens
    function getAllowedTokens() external view returns(address[] memory) {
        return s.allowedTokens;
    }

    /// @notice Adds an ERC20 to the list of allowed tokens
    /// @param _token The allowed token to add
    function addAllowedToken(address _token) external {
        LibDiamond.enforceIsContractOwner();
        if (!isAllowedToken(_token)) {
            s.allowedTokens.push() = _token;
            emit Climeta__TokenApproved(_token);
        }
    }

    /// @notice Removes an ERC20 from the list of allowed tokens
    /// Cannot remove if there is still value left in the treasury.
    /// @param _token The allowed token to add
    function removeAllowedToken(address _token) external {
        LibDiamond.enforceIsContractOwner();
        if (IERC20(_token).balanceOf(address(this)) > 0) {
            revert Climeta__ValueStillInContract();
        }

        uint256 numberOfTokens = s.allowedTokens.length;
        for (uint256 i=0; i < numberOfTokens;i++) {
            if (s.allowedTokens[i] == _token) {
                for (uint256 j=i; j + 1 < numberOfTokens ; j++ ) {
                    s.allowedTokens[j] = s.allowedTokens[j+1];
                }
                s.allowedTokens.pop();
                emit Climeta__TokenRevoked(address(_token));
                return;
            }
        }
    }
}
