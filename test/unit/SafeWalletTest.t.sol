// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import { Safe } from "@safe-contracts/contracts/Safe.sol";
import { SafeL2 } from "@safe-contracts/contracts/SafeL2.sol";
import { SafeProxyFactory } from "@safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { CompatibilityFallbackHandler } from "@safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol";
import { SimulateTxAccessor } from "@safe-contracts/contracts/accessors/SimulateTxAccessor.sol";
import { TokenCallbackHandler } from "@safe-contracts/contracts/handler/TokenCallbackHandler.sol";
import { CompatibilityFallbackHandler } from "@safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol";
import { CreateCall } from "@safe-contracts/contracts/libraries/CreateCall.sol";
import { MultiSend } from "@safe-contracts/contracts/libraries/MultiSend.sol";
import { MultiSendCallOnly } from "@safe-contracts/contracts/libraries/MultiSendCallOnly.sol";
import { SignMessageLib } from "@safe-contracts/contracts/libraries/SignMessageLib.sol";
import { SafeProxy } from "@safe-contracts/contracts/proxies/SafeProxy.sol";
import { Enum } from "@safe-contracts/contracts/common/Enum.sol";
import {ClimetaAssets} from "../../src/token/ClimetaAssets.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {AdminFacet} from "../../src/facets/AdminFacet.sol";
import {DonationFacet} from "../../src/facets/DonationFacet.sol";
import {VotingFacet} from "../../src/facets/VotingFacet.sol";
import {MarketplaceFacet} from "../../src/facets/MarketplaceFacet.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IMarketplace} from "../../src/interfaces/IMarketplace.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {IDonation} from "../../src/interfaces/IDonation.sol";
import {IVoting} from "../../src/interfaces/IVoting.sol";
import { LibDiamond } from "../../src/lib/LibDiamond.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "../../src/facets/AdminFacet.sol";
import "../../src/utils/DiamondHelper.sol";
import "../../src/interfaces/IDiamondCut.sol";

contract SafeWalletTest is Test, DiamondHelper {

    address ops;
    address admin;
    DeployAll.Addresses contracts;

    address safeAddress;
    address signer1;
    uint256 signer1PK;
    address signer2;
    uint256 signer2PK;
    address signer3;
    uint256 signer3PK;
    SimulateTxAccessor accessor;
    TokenCallbackHandler tokenCallbackHandler;
    CompatibilityFallbackHandler compatibilityFallbackHandler;
    Safe safe;
    SafeL2 safel2;
    SafeProxyFactory factory;
    CompatibilityFallbackHandler fallbackHandler;
    CreateCall createCall;
    MultiSend multisend;
    MultiSendCallOnly multisendcallconly;
    SignMessageLib signMessageLib;
    SafeProxy adminSafeProxy;
    SafeL2 adminSafe;

    IDiamondCut climeta;
    bytes donateData;

    struct Signers {
        address signer1;
        uint256 signer1PK;
        address signer2;
        uint256 signer2PK;
        address signer3;
        uint256 signer3PK;
    }

    Signers signers;

    function setUp() external {
        donateData = abi.encodeWithSignature("donate()");
        (signers.signer1, signers.signer1PK) = makeAddrAndKey("signer1");
        (signers.signer2, signers.signer2PK) = makeAddrAndKey("signer2");
        (signers.signer3, signers.signer3PK) = makeAddrAndKey("signer3");

        //////////////////// Deploy Safe MultiSig Wallets
        accessor = new SimulateTxAccessor();
        factory = new SafeProxyFactory();
        fallbackHandler = new CompatibilityFallbackHandler();
        tokenCallbackHandler = new TokenCallbackHandler();
        compatibilityFallbackHandler = new CompatibilityFallbackHandler();
        safe = new Safe();
        safel2 = new SafeL2();
        createCall = new CreateCall();
        multisend = new MultiSend();
        multisendcallconly = new MultiSendCallOnly();
        signMessageLib = new SignMessageLib();

        ////////////////////// Deploy Climeta
        admin = makeAddr("Admin");

        vm.startPrank(admin);
        DeployAll deployer = new DeployAll();
        contracts = deployer.run(admin);

        // Deploy Facets
        AdminFacet adminFacet = new AdminFacet();
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(adminFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("AdminFacet")
        });
        climeta = IDiamondCut(contracts.climeta);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IAdmin).interfaceId, true);

        DonationFacet donationFacet = new DonationFacet();
        cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(donationFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DonationFacet")
        });
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IDonation).interfaceId, true);

        VotingFacet votingFacet = new VotingFacet();
        cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(votingFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("VotingFacet")
        });
        bytes memory data = abi.encodeWithSignature("init()");
        climeta.diamondCut(cut, address(votingFacet), data);
        climeta.diamondSetInterface(type(IVoting).interfaceId, true);

        MarketplaceFacet marketplaceFacet = new MarketplaceFacet();
        cut = new FacetCut[](1);
        // remove supportsInterface
        cut[0] = FacetCut ({
            facetAddress: address(marketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MarketplaceFacet")
        });
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IMarketplace).interfaceId, true);
        IAdmin(contracts.climeta).updateOpsTreasuryAddress(payable(ops));
        IAdmin(contracts.climeta).setWithdrawalOnly(false);
        vm.stopPrank();


    }

    function test_Safe() external {
        address[] memory owners = new address[](3);
        owners[0] = signers.signer1;
        owners[1] = signers.signer2;
        owners[2] = signers.signer3;

        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,         // Array of Safe owners.
            2,      // Threshold for transaction approvals.
            address(0),     // Delegate call target (optional).
            "",             // Delegate call data.
            fallbackHandler,// Fallback handler address.
            address(0),     // Payment token (optional).
            0,              // Payment amount (optional).
            payable(address(0)) // Payment receiver (optional).
        );

        adminSafeProxy = factory.createProxyWithNonce(address(safel2), initializer, 0);

        console.log("Admin Safe Proxy: ", address(adminSafeProxy));
        adminSafe = SafeL2(payable(adminSafeProxy));
        assertEq(adminSafe.getThreshold(), 2);

        vm.deal(address(adminSafeProxy), 10 ether);

        // Transfer 1 ETH to one of the signers
        bytes32 txHash = adminSafe.getTransactionHash(
            signers.signer1,
            1 ether,
            "0x",
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(this)),
            adminSafe.nonce()
        );

        bytes memory signatures;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signers.signer2PK, txHash);
        signatures = abi.encodePacked(r, s, v);
        (v, r, s) = vm.sign(signers.signer1PK, txHash);
        signatures = bytes.concat(signatures, abi.encodePacked(r, s, v));

        bool success = adminSafe.execTransaction(
            signers.signer1,
            1 ether,
            "0x",
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(this)),
            signatures
        );

        assertEq( address(signers.signer1).balance, 1 ether);

        // Donate to Climeta from MultiSig
        txHash = adminSafe.getTransactionHash(
            address(climeta),
            1 ether,
            donateData,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(this)),
            adminSafe.nonce()
        );

        (v, r, s) = vm.sign(signers.signer2PK, txHash);
        signatures = abi.encodePacked(r, s, v);
        (v, r, s) = vm.sign(signers.signer1PK, txHash);
        signatures = bytes.concat(signatures, abi.encodePacked(r, s, v));
        success = adminSafe.execTransaction(
            address(climeta),
            1 ether,
            donateData,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(this)),
            signatures
        );



    }
}