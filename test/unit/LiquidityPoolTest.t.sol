// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {Rayward} from "../../src/token/Rayward.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";

import '@uniswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';
import {IQuoterV2} from "../../lib/v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract TestUniswapV3 is Test {
    using SafeERC20 for IERC20;
    uint256 constant ONE_MILLION = 1_000_000 * 1e18;
    uint256 constant ONE_BILLION = 1_000_000_000 * 1e18;
    uint24 public constant POOL_FEE = 3000;
    // Addresses on Base
    address constant USDT = 0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant uniswapSwapRouter = 0x2626664c2603336E57B271c5C0b26F421741e481;
    address constant uniswapUniversalRouterAddress = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address constant uniswapFactoryAddress = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
    address constant uniswapNonFungManager = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    address constant uniswapQuoterV2Address = 0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a;

    // the identifiers of the forks
    uint256 private mainnetFork;
    INonfungiblePositionManager public nonfungiblePositionManager;
    IUniswapV3Factory public uniswapFactory;
    IUniswapV3Pool public pool;
    ISwapRouter02 public uniswapRouter;
    IQuoterV2 public uniswapQuoter;


    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    Rayward public rayward;
    ERC20Mock public usdx;
    address admin;

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    mapping(uint256 => Deposit) public deposits;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("BASE_MAINNET_RPC"));
        vm.selectFork(mainnetFork);

        nonfungiblePositionManager = INonfungiblePositionManager(uniswapNonFungManager);
        uniswapFactory = IUniswapV3Factory(uniswapFactoryAddress);
        uniswapRouter = ISwapRouter02(uniswapSwapRouter);
        uniswapQuoter = IQuoterV2(uniswapQuoterV2Address);

        admin = makeAddr("admin");
        rayward = new Rayward(admin);
        usdx = new ERC20Mock();

        vm.prank(address(usdx));
        usdx.mint(admin, ONE_MILLION);

        vm.prank(admin);
        rayward.mint(admin, ONE_BILLION);

        vm.deal(admin, 10 ether);
        address poolAddress = uniswapFactory.createPool(address(rayward), address(usdx), POOL_FEE);
        require(poolAddress != address(0), "Pool creation failed");
        pool = IUniswapV3Pool(poolAddress);
        uint160 sqrtPriceX96 = 79228162514264337593543950336;

        pool.initialize(sqrtPriceX96);

        vm.startPrank(admin);
        TransferHelper.safeApprove(address(rayward), address(nonfungiblePositionManager), 1_000 * 1e18);
        TransferHelper.safeApprove(address(usdx), address(nonfungiblePositionManager), 1_000 * 1e18);
        vm.stopPrank();
        console.log("Rayward allowance for nonfungiblePositionManager:", rayward.allowance(admin, address(nonfungiblePositionManager)));
        console.log("USDX allowance for nonfungiblePositionManager:", usdx.allowance(admin, address(nonfungiblePositionManager)));

        console.log("Pool amount of USDX:", IERC20(pool.token0()).balanceOf(poolAddress));
        console.log("Pool amount of Rayward:", IERC20(pool.token1()).balanceOf(poolAddress));

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(usdx),
            token1: address(rayward),
            fee: POOL_FEE,
            tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
            tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
            amount0Desired: 1_000 * 1e18,
            amount1Desired: 1_000 * 1e18,
            amount0Min: 0,
            amount1Min: 0,
            recipient: admin,
            deadline: block.timestamp
        });

        vm.prank(admin);
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = nonfungiblePositionManager.mint(params);

        // Store the deposit details
        deposits[tokenId] = Deposit({
            owner: admin,
            liquidity: liquidity,
            token0: address(usdx),
            token1: address(rayward)
        });

        console.log("Liquidity added to the pool:", liquidity);
        console.log("Pool amount of USDX:", IERC20(IUniswapV3Pool(pool).token0()).balanceOf(poolAddress));
        console.log("Pool amount of Rayward:", IERC20(IUniswapV3Pool(pool).token1()).balanceOf(poolAddress));

    }

    function test_swap() public {
        address user1 = makeAddr("user1");

        address poolAddr = uniswapFactory.getPool(address(rayward), address(usdx), POOL_FEE);
        assertNotEq(poolAddr, address(0));

        vm.prank(admin);
        rayward.transfer(user1, 100 ether);

        console.log("User1 rayward balance:", rayward.balanceOf(user1));

        vm.deal(user1, 1 ether);

        vm.startPrank(user1);
        rayward.approve(address(uniswapRouter), 10 ether);
        usdx.approve(address(uniswapRouter), 10 ether);

        require(rayward.allowance(user1, address(uniswapRouter)) >= 10 ether, "Insufficient allowance");

        IQuoterV2.QuoteExactInputSingleParams memory quoteParams = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: address(rayward),
            tokenOut: address(usdx),
            amountIn: 10 ether,
            fee: POOL_FEE,
            sqrtPriceLimitX96: 0
        });

        (uint256 estimatedOut,,,) = uniswapQuoter.quoteExactInputSingle(quoteParams);
        console.log("Estimated amount out:", estimatedOut);

        uint128 liquidity = pool.liquidity();
        console.log("Liquidity in the pool:", liquidity);

        console.log("User balance of rayward:", rayward.balanceOf(user1));
        console.log("Allowance for router:", rayward.allowance(user1, address(uniswapRouter)));
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        require(sqrtPriceX96 > 0, "Pool not initialized");
        console.log("sqrtPriceX96:", sqrtPriceX96);

        IV3SwapRouter.ExactInputSingleParams memory swapParams = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: address(rayward),
            tokenOut: address(usdx),
            fee: POOL_FEE,
            recipient: user1,
            amountIn: 10 ether,
            amountOutMinimum: estimatedOut * 9 / 10,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = uniswapRouter.exactInputSingle(swapParams);
        console.log("Amount out:", amountOut);
        vm.stopPrank();
    }
}