// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {MarketplaceStorage} from "../storage/MarketplaceStorage.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import '@uniswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';


contract MarketplaceFacet is ERC1155Holder, ERC721Holder, IMarketplace {
    ClimetaStorage internal s;

    constructor(){
    }


    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function marketplaceFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    uint256 public constant ERC721 = 721;
    uint256 public constant ERC1155 = 1155;

    ////////////////////////////////////////////////////////////////
    // ERC721
    ////////////////////////////////////////////////////////////////

    function addERC721Item(address _collection, uint256 _tokenId, address _creator, uint256 _creatorRoyalty, uint256 _priceRaywards, uint256 _priceEth) external {
        LibDiamond.enforceIsContractOwner();
        MarketplaceStorage.MarketplaceStruct storage bs = MarketplaceStorage.marketplaceStorage();
        if (bs.erc721Items[_collection][_tokenId]) {
            revert Climeta__AlreadyInMarketplace();
        }

        emit Climeta__ERC721ItemAdded(_collection, _tokenId, _priceRaywards, _priceEth);

        bs.itemPriceRaywards[_collection][_tokenId] = _priceRaywards;
        bs.itemPriceEth[_collection][_tokenId] = _priceEth;
        bs.itemCreator[_collection][_tokenId] = _creator;
        bs.itemRoyalties[_collection][_tokenId] = _creatorRoyalty;
        bs.erc721Items[_collection][_tokenId] = true;
        IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenId, "");
    }

    function removeERC721Item(address _collection, uint256 _tokenId) external {
        LibDiamond.enforceIsContractOwner();
        MarketplaceStorage.MarketplaceStruct storage bs = MarketplaceStorage.marketplaceStorage();
        if (!bs.erc721Items[_collection][_tokenId]) {
            revert Climeta__NotInMarketplace();
        }
        emit Climeta__ERC721ItemRemoved(_collection, _tokenId);
        bs.itemPriceRaywards[_collection][_tokenId] = 0;
        bs.itemPriceEth[_collection][_tokenId] = 0;
        bs.itemCreator[_collection][_tokenId] = address(0);
        bs.itemRoyalties[_collection][_tokenId] = 0;
        bs.erc721Items[_collection][_tokenId] = false;
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, "");
    }

    function buyERC721Item(address _collection, uint256 _tokenId) external payable {
        MarketplaceStorage.MarketplaceStruct storage bs = MarketplaceStorage.marketplaceStorage();
        if (!bs.erc721Items[_collection][_tokenId]) {
            revert Climeta__NotInMarketplace();
        }
        uint256 priceInRaywards = bs.itemPriceRaywards[_collection][_tokenId];
        uint256 priceInEth = bs.itemPriceEth[_collection][_tokenId];

        if (priceInEth > msg.value) {
            revert Climeta__MarketplaceNotEnoughEth();
        }

        emit Climeta__ERC721ItemSold(_collection, _tokenId, msg.sender);
        bs.erc721Items[_collection][_tokenId] = false;

        // Process ETH payments
        uint256 amountToCreator = priceInEth * bs.itemRoyalties[_collection][_tokenId] / 10000;
        uint256 amountToClimeta = (priceInEth - amountToCreator) * 1 / 10;
        uint256 amountToTreasury = (priceInEth - amountToCreator) * 9 / 10;
        bool success;

        if (amountToCreator > 0) {
            (success,) = payable(bs.itemCreator[_collection][_tokenId]).call{value:amountToCreator}("");
            if (!success) {
                revert Climeta__MarketplaceEthTransferFailed();
            }
        }
        if (amountToClimeta > 0) {
            (success,) = payable(s.opsTreasuryAddress).call{value:amountToClimeta}("");
            if (!success) {
                revert Climeta__MarketplaceEthTransferFailed();
            }
        }

        // Process Rayward payments
        amountToCreator = priceInRaywards * bs.itemRoyalties[_collection][_tokenId] / 10000;
        amountToClimeta = (priceInRaywards - amountToCreator) * 1 / 10;
        amountToTreasury = priceInRaywards - amountToCreator - amountToClimeta;

        if( (amountToCreator > 0) && !IERC20(s.raywardAddress).transferFrom(msg.sender, bs.itemCreator[_collection][_tokenId], amountToCreator)) {
            revert Climeta__MarketplaceRaywardsTransferFailed();
        }
        if( !IERC20(s.raywardAddress).transferFrom(msg.sender, s.opsTreasuryAddress, amountToClimeta)) {
            revert Climeta__MarketplaceRaywardsTransferFailed();
        }
        // Convert remaining Raywards to StableCoin for funding treasury
        uint256 amountStableToTreasury = swapExactInputSingle(amountToTreasury);
        emit Climeta__MarketplaceTreasuryDonation(msg.sender, _collection, _tokenId, amountStableToTreasury);

        // Finally send over bought item
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, "");
    }

    function swapExactInputSingle(uint128 raywardsAmount) internal returns (uint256 amountOut) {
        // Approve the router to spend the Raywards
        TransferHelper.safeApprove(s.raywardAddress, s.uniswapRouter, raywardsAmount);

        // TODO Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: s.raywardAddress,
                tokenOut: s.treasuryStablecoin,
                fee: s.uniswapPoolFee,
                recipient: address(this),
                amountIn: raywardsAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = IV3SwapRouter(s.uniswapRouter).exactInputSingle(params);
        return amountOut;
    }

    ////////////////////////////////////////////////////////////////
    // ERC1155
    ////////////////////////////////////////////////////////////////

    function addERC1155Item(address _collection, uint256 _tokenId, uint256 _amount, uint256 _priceRaywards, uint256 _priceEth) external {
        LibDiamond.enforceIsContractOwner();
        MarketplaceStorage.MarketplaceStruct storage bs = MarketplaceStorage.marketplaceStorage();
        bs.itemPriceRaywards[_collection][_tokenId] = _priceRaywards;
        bs.itemPriceEth[_collection][_tokenId] = _priceEth;
        IERC1155(_collection).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
    }

    function removeERC1155Item(address _collection, uint256 _tokenId, uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        MarketplaceStorage.MarketplaceStruct storage bs = MarketplaceStorage.marketplaceStorage();
        bs.itemPriceRaywards[_collection][_tokenId] = 0;
        bs.itemPriceEth[_collection][_tokenId] = 0;
        IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
    }

    function buyERC1155Item(address _collection, uint256 _tokenId) external payable {
        MarketplaceStorage.MarketplaceStruct storage bs = MarketplaceStorage.marketplaceStorage();
        uint256 priceInRaywards = bs.itemPriceRaywards[_collection][_tokenId];
        uint256 priceInEth = bs.itemPriceEth[_collection][_tokenId];

        require(bs.erc1155Items[_collection][_tokenId] > 0, "Sold");

        if (priceInEth > msg.value) {
            revert();
        }
        require( IERC20(s.raywardAddress).transferFrom(msg.sender, s.opsTreasuryAddress, priceInRaywards), "Payment failed");

        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, "");
    }


}
