// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DelMundo} from "../src/token/DelMundo.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract DelMundoTest is Test, IERC721Receiver {
    DelMundo private delMundo;
    uint256 private tokenIdToTest = 0;
    address payable private treasury;
    string private tokenUriToTest = "https://token.uri/";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 20;

    struct SigningDomain {
        string name;
        string version;
        address verifyingContract;
        uint256 chainid;
    }

    SigningDomain private domain;

    struct NFTVoucher {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
        bytes signature;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        delMundo = new DelMundo();
        treasury = payable(makeAddr("treasury"));
        delMundo.setTreasuryAddress(treasury);

        // Create some vouchers
        domain = SigningDomain("RayNFT-Voucher", "1", address(delMundo), block.chainid);


    }

    function test_CurrentMaxSupply() public view {
        assertEq(delMundo.currentMaxSupply(), MAX_SUPPLY);
    }

    function test_Redeem() public {

    }

    function test_SafeMint() public {
        delMundo.safeMint(address(this), tokenUriToTest);
        assertEq(delMundo.ownerOf(tokenIdToTest), address(this));
        assertEq(delMundo.tokenURI(tokenIdToTest), tokenUriToTest);
    }

    function test_SafeMintWithoutPermision() public {
        vm.expectRevert();
        delMundo.safeMint(address(0), tokenUriToTest);
    }

    function test_UpdateMaxSupply() public {
        delMundo.updateMaxSupply(MAX_SUPPLY*2);
        assertEq(delMundo.currentMaxSupply(), MAX_SUPPLY*2);
    }

    function test_UpdateMaxSupplyWithoutPermission() public {
        delMundo.renounceRole(delMundo.RAY_ROLE(), address(this));
        vm.expectRevert();
        delMundo.updateMaxSupply(MAX_SUPPLY*2);
    }

    function testUpdateMaxPerWalletAmount() public {
        delMundo.updateMaxPerWalletAmount(MAX_PER_WALLET+10);
        assertEq(delMundo.maxPerWalletAmount(), MAX_PER_WALLET+10);
    }

    function test_UpdateMaxPerWalletAmountWithoutPermission() public {
        delMundo.renounceRole(delMundo.RAY_ROLE(), address(this));
        vm.expectRevert();
        delMundo.updateMaxPerWalletAmount(MAX_PER_WALLET+10);
    }

    function test_Withdraw() public {
        // Put 10 ETH in DelMundo and check that the withdraw function moves it to the treasury address
        deal(address(delMundo), 10 ether);
        delMundo.withdraw();
        uint256 balanceAfter = treasury.balance;
        assertEq(balanceAfter, 10 ether);
    }

    function test_WithdrawWithoutPermission() public {
        delMundo.renounceRole(delMundo.RAY_ROLE(), address(this));
        vm.expectRevert();
        delMundo.withdraw();
    }

}