// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {ClimetaFarcasterNFTs} from "../../src/token/ClimetaFarcasterNFTs.sol";

contract ClimetaFarcasterNFTsTest is Test {

    ClimetaFarcasterNFTs nfts;
    address admin;
    uint256 adminPk;

    function setUp() public {
        (admin, adminPk) = makeAddrAndKey("admin");
        nfts = new ClimetaFarcasterNFTs(admin, "URI");
    }

    function test_minting() public {
        address user1 = makeAddr("user1");

        vm.startPrank(user1);
        vm.expectRevert();
        nfts.mint(1,  1);
        vm.expectRevert();
        nfts.mint(1,  2);
        vm.stopPrank();
        vm.startPrank(admin);
        nfts.updateURI(1, "URI1");
        nfts.updateURI(2, "URI2");
        vm.stopPrank();

        vm.startPrank(user1);
        nfts.mint(1, 1);
        nfts.mint(1,  2);

        vm.expectRevert();
        nfts.mint(1, 1);
        vm.expectRevert();
        nfts.mint(1, 3);
        vm.stopPrank();
    }

}