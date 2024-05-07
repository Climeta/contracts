const { ethers, upgrades } = require("hardhat")
var chai = require("chai")
var  chaiAsPromised = require("chai-as-promised")
const expect = chai.expect
const { LazyMinter } = require( "../nft/nft-generator/lib/LazyMinter")
const {toNumber} = require("ethers");
chai.use(chaiAsPromised)

const CHAINID = process.env.BLOCKCHAIN_ID

async function deploy() {
    const [custodian, member1, member2] = await ethers.getSigners()

    let RAYWARD = await ethers.getContractFactory("Rayward")
    const rayward = await RAYWARD.deploy()
    await rayward.waitForDeployment();

    let RAYDELMUNDO = await ethers.getContractFactory("DelMundo")
    const rayNFT = await RAYDELMUNDO.deploy()
    await rayNFT.waitForDeployment()

    let nftFactory = await ethers.getContractFactory("TestNFT")
    const nftContract = await nftFactory.deploy()
    await nftContract.waitForDeployment();

    let Registry = await ethers.getContractFactory("ERC6551Registry")
    const erc6551registry = await Registry.deploy()
    await erc6551registry.waitForDeployment()
    let Account = await ethers.getContractFactory("RayWallet")
    const erc6551account = await Account.deploy()
    await erc6551account.waitForDeployment()

    const account0 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0, "0x")
    const account1 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0, "0x")
    const account2 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0, "0x")
    const account3 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0, "0x")
    const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)

    let shopFactory = await ethers.getContractFactory("ShopLedger")
    const shopContract = await upgrades.deployProxy(shopFactory, [await rayward.getAddress(), account0address])
    await shopContract.waitForDeployment();
    return {
        custodian,
        member1,
        member2,
        rayNFT,
        nftContract,
        shopContract,
        rayward,
        erc6551registry,
        erc6551account
    }
}

describe("Token Testing suite", function (accounts) {

    before(async () => {
    })

    it("Multiple voucher generation and minting tests", async function () {
        const { shopContract, rayNFT, erc6551registry, erc6551account, nftContract, rayward, member1, member2, custodian} = await deploy()
        const lazyMinter = new LazyMinter({ contract: rayNFT, signer: custodian })

        console.log("Create the Del Mundos")
        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )

        await rayNFT.connect(custodian).redeem(voucher0)
        await rayNFT.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member1).redeem(voucher3, {value: ethers.parseEther("0.1")})

        const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)
        const account1address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0)
        const account2address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0)
        const account3address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0)

        const account1contract = await ethers.getContractAt("RayWallet", account1address, custodian)
        const account2contract = await ethers.getContractAt("RayWallet", account2address, custodian)
        const account3contract = await ethers.getContractAt("RayWallet", account3address, custodian)


        console.log("Granting initial raywards for testing")
        await rayward.mint(account0address, 1000);
        await rayward.mint(account1address, 10);
        await rayward.mint(account2address, 10);
        await rayward.mint(account3address, 10);

        // Create Exclusive NFTs
        console.log("Minting Exclusive NFTs")
        await nftContract.connect(custodian).mintNFT(custodian, 0)
        await nftContract.connect(custodian).mintNFT(custodian, 1)
        await nftContract.connect(custodian).mintNFT(custodian, 2)
        await nftContract.connect(custodian).mintNFT(custodian, 3)

        console.log("transfer the tokens to the contract")
        await nftContract.connect(custodian).transferFrom(await custodian.getAddress(), await shopContract.getAddress(), 0);
        await nftContract.connect(custodian).transferFrom(await custodian.getAddress(), await shopContract.getAddress(), 1);
        await nftContract.connect(custodian).transferFrom(await custodian.getAddress(), await shopContract.getAddress(), 2);
        await nftContract.connect(custodian).transferFrom(await custodian.getAddress(), await shopContract.getAddress(), 3);

        console.log("Adding NFTs to the shop")
        await shopContract.connect(custodian).addToken(await nftContract.getAddress(), 0, 1, 1);
        await shopContract.connect(custodian).addToken(await nftContract.getAddress(), 1, 2, 2);
        await shopContract.connect(custodian).addToken(await nftContract.getAddress(), 2, 3, 3);
        await shopContract.connect(custodian).addToken(await nftContract.getAddress(), 3, 3, 3);

        // To buy an exclusive a user has to approve a rayward move from their NFT account wallet to the Ray wallet.
        // This is done by calling approve for the shopcontract where the transfer happens
        console.log("THE ACTORS")
        console.log("custodian :" + await custodian.getAddress())
        console.log("ray wallet :" + account0address)
        console.log("member1 address :" + await member1.getAddress())
        console.log("member1 nft wallet address :" + account1address)
        console.log("rayward contract :" + await rayward.getAddress())
        console.log("shop contract :" + await shopContract.getAddress())

        ABI = ["function approve(address,uint256)"]
        iface = new ethers.Interface(ABI)
        calldata = iface.encodeFunctionData("approve", [await shopContract.getAddress(), 1])
        await account1contract.connect(member1).executeCall(await rayward.getAddress(), 0, calldata)
        console.log("Approved the move of tokens")
        await shopContract.connect(member1).buyTokenWithBoth(1, account1address, {value: ethers.parseEther("1")})

        expect (await rayward.balanceOf(account1address)).to.equal(9)
        expect (await rayward.balanceOf(account0address)).to.equal(1001)
    })
})
