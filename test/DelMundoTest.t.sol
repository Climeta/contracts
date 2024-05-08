// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {VmSafe} from "../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../src/token/DelMundo.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

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
        // creating a signed digest for testing
        VmSafe.Wallet memory climeta = vm.createWallet("climeta");
        bytes32 hash = keccak256("Signed by Climeta");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(climeta, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // can't create a voucher in foundry yet as can't do signTypedData yet. This is done in hardhat tests.
        // we can test invalid vouchers though.
        DelMundo.NFTVoucher memory testVoucher = DelMundo.NFTVoucher({tokenId: 1, uri: "Invalid URI", minPrice: 100000, signature: signature});
        vm.expectRevert(DelMundo.DelMundo__IncorrectSigner.selector);
        delMundo.redeem(testVoucher);
    }

    function test_SafeMint() public {
        vm.expectEmit();
        emit DelMundo.minted(0, tokenUriToTest, address(this));
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

    function test_MaxSupply() public {
        // Set to low value so it will fail when trying to mint new one
        delMundo.updateMaxSupply(1);
        delMundo.safeMint(address(this), "uri-0");
        delMundo.safeMint(address(this), "uri-1");
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);

        // Increase by 1 and confirm
        delMundo.safeMint(address(this), "uri-2");
        delMundo.updateMaxSupply(2);
        delMundo.safeMint(address(this), "uri-2");
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), "uri-3");

        // Increase by lots and confirm all good
        delMundo.updateMaxSupply(10);
        delMundo.safeMint(address(this), "uri-3");
        delMundo.safeMint(address(this), "uri-4");
        delMundo.safeMint(address(this), "uri-5");

        // Set to value lower than current supply and test
        delMundo.updateMaxSupply(1);
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), "uri-6");
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

    function test_SetContractURI() public {
        delMundo.setContractURI("http:testURI");
        string memory uri = delMundo.contractURI();
        assertEq(uri, "http:testURI");
        delMundo.setContractURI("http:testURI2");
        uri = delMundo.contractURI();
        assertEq(uri, "http:testURI2");
    }

    function test_SetContractURIFail() public {
        vm.prank(address(1));
        vm.expectRevert();
        delMundo.setContractURI("http:testURI");
    }

    function test_TokensOfOwner() public {
        uint256[] memory tokens = delMundo.tokensOfOwner(address(1));
        assertEq(tokens.length, 0);
    }

    function test_Pause() public {
        // creating a signed digest for testing
        delMundo.safeMint(address(this), "uri-0");
        delMundo.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        delMundo.safeMint(address(this), "uri-1");
        delMundo.unpause();
        delMundo.safeMint(address(this), "uri-1");
    }

    function test_SetTreasury() public {
        address payable old_treasury = delMundo._treasury();
        address payable new_treasury = payable(makeAddr("new-treasury"));
        delMundo.setTreasuryAddress(new_treasury);
        assertEq(delMundo._treasury(), new_treasury);

        // ensure only owner can update!
        address payable naughtyOne = payable(makeAddr("naughtyboy"));
        vm.prank(naughtyOne);
        vm.expectRevert(abi.encodeWithSelector(DelMundo.DelMundo__NotRay.selector, naughtyOne));
        delMundo.setTreasuryAddress(naughtyOne);
    }
}