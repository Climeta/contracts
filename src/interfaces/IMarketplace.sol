// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/// @title IMarketplace Climeta Marketplace Facet Standard
///  Note: the ERC-165 identifier for this interface is
interface IMarketplace {
    /// @notice Emitted when a donation is made
    /// @param _buyer The address of the buyer of the item
    /// @param _collection The address of the token
    /// @param _tokenId The id of the token
    /// @param _amount The amount convert to treasury
    event Climeta__MarketplaceTreasuryDonation(address _buyer, address _collection, uint256 _tokenId, uint256 _amount);

    /// @notice Emitted when an ERC721 is added to the Store
    /// @param _collection The address of the token added
    /// @param _tokenId The id of the token added
    /// @param _priceRaywards The ERC20 token price in Raywards
    /// @param _priceEth ETH price of token
    event Climeta__ERC721ItemAdded(address _collection, uint256 _tokenId, uint256 _priceRaywards, uint256 _priceEth);

    /// @notice Emitted when an ERC1144 is added to the Store
    /// @param _collection The address of the token added
    /// @param _tokenId The id of the token added
    /// @param _amount The amount of the token added
    /// @param _priceRaywards The token price in Raywards
    /// @param _priceEth ETH price of token
    event Climeta__ERC1155ItemAdded(address _collection, uint256 _tokenId, uint256 _amount, uint256 _priceRaywards, uint256 _priceEth);

    /// @notice Emitted when an ERC721 is removed from the store
    /// @param _collection The address of the token removed
    /// @param _tokenId The id of the token removed
    event Climeta__ERC721ItemRemoved(address _collection, uint256 _tokenId);

    /// @notice Emitted when an ERC1155 is removed from the store
    /// @param _collection The address of the token removed
    /// @param _tokenId The id of the token removed
    event Climeta__ERC1155ItemRemoved(address _collection, uint256 _tokenId);

    /// @notice Emitted when any item is sold from the store
    /// @param _collection The address of the token
    /// @param _tokenId The id of the token
    /// @param _recipient address of the buyer
    event Climeta__ItemSold(address _collection, uint256 _tokenId, address _recipient);

    error Climeta__AlreadyInMarketplace();
    error Climeta__NotInMarketplace();
    error Climeta__MarketplaceInvalidAmount();
    error Climeta__MarketplaceRaywardsTransferFailed();
    error Climeta__MarketplaceNotEnoughEth();
    error Climeta__MarketplaceEthTransferFailed();
    error Climeta__MarketplaceSaleFailed(address _collection, uint256 _tokenId);

    function marketplaceFacetVersion() external pure returns (string memory);

    function addERC721Item(address _collection, uint256 _tokenId, address _creator, uint256 _creatorRoyalty, uint256 _priceRaywards, uint256 _priceEth) external;
    function buyERC721Item(address _collection, uint256 _tokenId) external payable;
    function removeERC721Item(address _collection, uint256 _tokenId) external;
    function addERC1155Item(address _collection, uint256 _tokenId, uint256 _amount,  address _creator, uint256 _creatorRoyalty, uint256 _priceRaywards, uint256 _priceEth) external;
}