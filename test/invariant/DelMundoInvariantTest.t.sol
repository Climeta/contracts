// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {DelMundoHandler} from "./DelMundoInvariantHandler.t.sol";
import {RayWallet} from "../../src/RayWallet.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DelMundoInvariantTest is Test, IERC721Receiver {

    event DelMundo__Minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);
    event Transfer(address from,address to ,uint256 tokenId);

    DelMundo private delMundo;
    DelMundoHandler handler;
    address payable private treasury;
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 20;
    address private admin;
    uint256 private adminPk;

     function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        (admin, adminPk) = makeAddrAndKey("admin");
        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));

        handler = new DelMundoHandler (delMundo);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = handler.redeem.selector;
        targetContract(address(handler));
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function statefulFuzz_DelMundo() public {
        assert(delMundo.totalSupply() <= handler.VOUCHER_NUMBER());
    }

}