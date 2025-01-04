// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DelMundoTest is Test, IERC721Receiver, EIP712 {

    event minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);

    DelMundo private delMundo;
    uint256 private tokenIdToTest = 0;
    address payable private treasury;
    string private tokenUriToTest = "https://token.uri/";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 20;
    address private admin;
    uint256 private adminPk;

    string private constant SIGNING_DOMAIN = "RayNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    uint256 private constant MIN_PRICE = 100000000000;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    struct VoucherData {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

     function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        (admin, adminPk) = makeAddrAndKey("admin");
        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));
        address current = address(this);

        vm.prank(admin);
        delMundo.addAdmin(current);

        treasury = payable(makeAddr("treasury"));
    }
}
