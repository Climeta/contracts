// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DelMundoHandler is Test, EIP712 {
    string private constant SIGNING_DOMAIN = "RayNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    DelMundo private delMundo;

    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 20;
    uint256 public constant VOUCHER_NUMBER = 1000;
    address private admin;
    uint256 private adminPk;

    uint256 private constant MIN_PRICE = 1 ether;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");

    struct VoucherData {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
    }

    DelMundo.NFTVoucher[VOUCHER_NUMBER] public vouchers;

    constructor(DelMundo _delMundo) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        delMundo = _delMundo;
        (admin, adminPk) = makeAddrAndKey("admin");
        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));
        VoucherData memory voucherData;
        bytes32 dataEncoded;
        bytes32 digest;
        DelMundo.NFTVoucher memory voucher;
        //create all the vouchers
        for (uint64 i=0; i< VOUCHER_NUMBER; i++) {
            voucherData = VoucherData(i, string.concat("uri", Strings.toString(i)), MIN_PRICE);
            dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH, voucherData.tokenId, keccak256(bytes(voucherData.uri)), voucherData.minPrice));
            digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
            // this rsv combo is correct
            bytes memory voucherSignature = abi.encodePacked(r,s,v);
            voucher = DelMundo.NFTVoucher(voucherData.tokenId, voucherData.uri, voucherData.minPrice, voucherSignature);

            vouchers[i] = voucher;
        }
    }

    function setUp() public {
    }

    function redeem (uint256 voucherid, address user, uint256 amount) public {
        voucherid = bound(voucherid, 0, VOUCHER_NUMBER-1);
        vm.deal(user, amount);
        vm.startPrank(user);
        delMundo.redeem{value: amount}(vouchers[voucherid]);
        vm.stopPrank();
    }

}