const { ethers, upgrades } = require("hardhat")
var chai = require("chai")
var  chaiAsPromised = require("chai-as-promised")
const expect = chai.expect
const { LazyMinter } = require( "../../script/Voucher")
const {toNumber} = require("ethers");
chai.use(chaiAsPromised)

const CHAINID = process.env.BLOCKCHAIN_ID
const NOT_AN_ADMIN = "ClimetaCore__NotAdmin"
const NOT_WALLET_OWNER = "ClimetaCore__NotRayWallet"

async function deploy() {
    const [custodian, rayOwner, founder1, founder2, founder3, beneficiary1, beneficiary2, member1, member2, member3, member4, benefactor1, benefactor2, treasury] = await ethers.getSigners()

    let RAYWARD = await ethers.getContractFactory("Rayward")
    const rayward = await RAYWARD.deploy()
    await rayward.waitForDeployment();

    let RAYDELMUNDO = await ethers.getContractFactory("DelMundo")
    const rayNFT = await RAYDELMUNDO.deploy()
    await rayNFT.waitForDeployment()

    console.log("Deploying Registry/Account contracts")
    let Registry = await ethers.getContractFactory("ERC6551Registry")
    const erc6551registry = await Registry.deploy()
    await erc6551registry.waitForDeployment()
    let Account = await ethers.getContractFactory("RayWallet")
    const erc6551account = await Account.deploy()
    await erc6551account.waitForDeployment()

    const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0, )

    console.log("Deploying climeta core")
    let ClimetaCore = await ethers.getContractFactory("ClimetaCore");
    const climetaCore = await upgrades.deployProxy(ClimetaCore, [await custodian.getAddress(), await rayNFT.getAddress(), await rayward.getAddress(), await erc6551registry.getAddress(), await erc6551account.getAddress()])
    await climetaCore.waitForDeployment()

    console.log("Deploying auth contract")
    let AuthContract = await ethers.getContractFactory("Authorization");
    const  authContract = await upgrades.deployProxy(AuthContract, [await custodian.getAddress(), await treasury.getAddress(), await climetaCore.getAddress()])
    await authContract.waitForDeployment()
    await climetaCore.updateAuthContract(await authContract.getAddress())



    let TestRewardContract = await ethers.getContractFactory("TestReward")
    const testContract = await TestRewardContract.deploy(await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0), await rayward.getAddress())
    await testContract.waitForDeployment()

    return {
        custodian,
        rayOwner,
        founder1,
        founder2,
        member1,
        member2,
        member3,
        member4,
        treasury,
        rayward,
        rayNFT,
        climetaCore,
        authContract,
        erc6551registry,
        erc6551account,
        testContract,
    }
}

describe("Token Bound Testing suite", function (accounts) {
    let provider

    before(async () => {
    });

    it ("Voucher creation tests ", async function () {
        const {rayNFT, custodian} = await deploy()
        const lazyMinter = new LazyMinter({contract: rayNFT, signer: custodian})
        console.log("Created Minter")

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))

        expect(await voucher0.minPrice).to.equal("0")
        expect(await voucher1.minPrice).to.equal(ethers.parseEther("0.1"))
        expect(await voucher1.tokenId).to.equal(1)
        expect(await voucher2.minPrice).to.equal(ethers.parseEther("0.1"))
        expect(await voucher2.tokenId).to.equal(2)
        expect(await voucher3.minPrice).to.equal(ethers.parseEther("0.1"))
        expect(await voucher4.minPrice).to.equal(ethers.parseEther("0.1"))
    })

    it ("Redeeming testing", async function () {
        const {rayNFT, custodian, rayOwner, member1, member2, member3, member4} = await deploy()
        const lazyMinter = new LazyMinter({contract: rayNFT, signer: custodian})
        console.log("Created Minter")

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))

        await rayNFT.connect(rayOwner).redeem(voucher0)
        await rayNFT.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher3, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member4).redeem(voucher4, {value: ethers.parseEther("0.1")})
        expect(toNumber(await rayNFT.balanceOf(await rayOwner.getAddress()))).to.equal(1)
        expect(toNumber(await rayNFT.balanceOf(member1.address))).to.equal(1)
        expect(toNumber(await rayNFT.balanceOf(member2.address))).to.equal(2)
        expect(toNumber(await rayNFT.balanceOf(member3.address))).to.equal(0)
        expect(toNumber(await rayNFT.balanceOf(member4.address))).to.equal(1)

    })

    it ("Smart Wallet testing", async function () {
        provider = hre.ethers.provider

        const {
            rayNFT,
            rayward,
            custodian,
            rayOwner,
            member1,
            member2,
            member3,
            member4,
            erc6551account,
            erc6551registry
        } = await deploy()
        const lazyMinter = new LazyMinter({contract: rayNFT, signer: custodian})
        console.log("Created Minter")

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))

        console.log("Created vouchers")

        await rayNFT.connect(rayOwner).redeem(voucher0)
        await rayNFT.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher3, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member3).redeem(voucher4, {value: ethers.parseEther("0.1")})

        console.log("Creating smart accounts for NFTs")
        const erc6551accountAddress = await erc6551account.getAddress()
        const rayNFTAddress = await rayNFT.getAddress()
        const emptyArray = new Uint8Array([])
        let account0 = await erc6551registry.createAccount(erc6551accountAddress, CHAINID, rayNFTAddress, 0, 0, "0x")
        let account1 = await erc6551registry.createAccount(erc6551accountAddress, CHAINID, rayNFTAddress, 1, 0, "0x")
        let account2 = await erc6551registry.createAccount(erc6551accountAddress, CHAINID, rayNFTAddress, 2, 0, "0x")
        let account3 = await erc6551registry.createAccount(erc6551accountAddress, CHAINID, rayNFTAddress, 3, 0, "0x")
        let account4 = await erc6551registry.createAccount(erc6551accountAddress, CHAINID, rayNFTAddress, 4, 0, "0x")

        let account3address = await erc6551registry.account(erc6551accountAddress, CHAINID, rayNFTAddress, 3, 0)


        console.log("Created smart accounts for NFTs")
        const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0, )
        const account0contract = await ethers.getContractAt("RayWallet", account0address, custodian)
        const account1address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0)
        const account1contract = await ethers.getContractAt("RayWallet", account1address, custodian)

        console.log("Sending some ETH to Ray from custodian")
        await custodian.sendTransaction({to: account0address, value: ethers.parseEther("20.0"),})
        console.log("Balance of " + account0address + " is " + await provider.getBalance(account0address))

        console.log("Sending some ETH back to custodian from Ray")
        await account0contract.connect(rayOwner).executeCall(await custodian.getAddress(), ethers.parseEther("1.0"), "0x")

        // Check that no-one other than owner can access the tokenbound account
        await expect(account0contract.connect(member4).executeCall(await custodian.getAddress(), ethers.parseEther("1.0"), "0x")).to.be.eventually.be.rejected
        await expect(account0contract.connect(custodian).executeCall(await custodian.getAddress(), ethers.parseEther("1.0"), "0x")).to.be.eventually.be.rejected
        console.log("Balance of " + account0address + " is " + await provider.getBalance(account0address))

        console.log("Minting some PDBs and giving them to Ray")
        const rayWalletAddress = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)
        await rayward.mint(rayWalletAddress, 1000)
        expect(toNumber(await rayward.balanceOf(account0address))).to.equal(1000)

        console.log("Test Ray giving out rewards")
        let ABI = ["function transfer(address, uint256)"]
        let iface = new ethers.Interface(ABI)
        calldata = iface.encodeFunctionData("transfer", [await member1.getAddress(), 250])

        // Test to ensure only Ray owner can move Rays from Ray wallet.
        await expect(account0contract.connect(member1).executeCall(await rayward.getAddress(), 0, calldata)).to.be.eventually.be.rejected
        await expect(account0contract.connect(custodian).executeCall(await rayward.getAddress(), 0, calldata)).to.be.eventually.be.rejected
        await account0contract.connect(rayOwner).executeCall(await rayward.getAddress(), 0, calldata)

        expect(toNumber(await rayward.balanceOf(account0address))).to.equal(750)
        expect(toNumber(await rayward.balanceOf(await member1.getAddress()))).to.equal(250)
    })

    it ("Contract/Ray wallet interaction testing", async function () {
        provider = hre.ethers.provider

        const {
            rayNFT,
            rayward,
            testContract,
            custodian,
            rayOwner,
            member1,
            member2,
            member3,
            member4,
            founder1,
            erc6551account,
            erc6551registry
        } = await deploy()
        const lazyMinter = new LazyMinter({contract: rayNFT, signer: custodian})
        console.log("Created Minter")

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))

        console.log("Created vouchers")

        await rayNFT.connect(rayOwner).redeem(voucher0)
        await rayNFT.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher3, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member4).redeem(voucher4, {value: ethers.parseEther("0.1")})

        console.log("Creating smart accounts for NFTs")
        const account0 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0, "0x")
        const account1 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0, "0x")
        const account2 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0, "0x")
        const account3 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0, "0x")
        const account4 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 4, 0, "0x")
        const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)
        const account0contract = await ethers.getContractAt("RayWallet", account0address, custodian)
        const account1address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0)
        const account1contract = await ethers.getContractAt("RayWallet", account1address, custodian)

        console.log("Minting some Raywards and giving them to Ray")
        await rayward.mint(founder1, 1000)
        await rayward.mint(account0address, 1000)
        expect(toNumber(await rayward.balanceOf(account0address))).to.equal(1000)

        console.log("Ray wallet address :" + account0address)
        console.log("RayNFT owner address :" + await rayOwner.getAddress())
        console.log("Test contract address :" + await testContract.getAddress())

        await rayward.connect(founder1).approve(await member1.getAddress(), 15)
        await rayward.connect(member1).transferFrom(await founder1.getAddress(), await member1.getAddress(), 15)

        console.log("Setting up allowances")
        ABI = ["function approve(address, uint256)"]
        iface = new ethers.Interface(ABI)
        calldata = iface.encodeFunctionData("approve", [await testContract.getAddress(), 1000])
        await account0contract.connect(rayOwner).executeCall(await rayward.getAddress(), 0, calldata)

        console.log("Showing the approvals for testcontract " + await rayward.allowance(account0address, await testContract.getAddress()))
        console.log("Calling the sendReward function")
        await expect(testContract.connect(member1).sendReward(await member3.getAddress(), 10)).to.be.eventually.be.rejected
        await expect(testContract.connect(rayOwner).sendReward(await member3.getAddress(), 10)).to.be.eventually.be.rejected
        await testContract.sendReward(await member3.getAddress(), 10)
        expect(toNumber(await rayward.balanceOf(account0address))).to.equal(990)

        expect(toNumber(await rayward.balanceOf(await member3.getAddress()))).to.equal(10)

        await expect(testContract.sendReward(await member3.getAddress(), 10000)).to.be.eventually.be.rejected

    })

    it ("NFT changing ownership tests", async function () {
        provider = hre.ethers.provider

        const {
            rayNFT,
            rayward,
            testContract,
            custodian,
            rayOwner,
            member1,
            member2,
            member3,
            member4,
            founder1,
            erc6551account,
            erc6551registry
        } = await deploy()

        const lazyMinter = new LazyMinter({contract: rayNFT, signer: custodian})
        console.log("Created Minter")

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1"))

        console.log("Created vouchers")

        await rayNFT.connect(rayOwner).redeem(voucher0)
        await rayNFT.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member2).redeem(voucher3, {value: ethers.parseEther("0.1")})
        await rayNFT.connect(member4).redeem(voucher4, {value: ethers.parseEther("0.1")})

        console.log("Creating smart accounts for NFTs")
        const account0 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0, "0x")
        const account1 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0, "0x")
        const account2 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0, "0x")
        const account3 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0, "0x")
        const account4 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 4, 0, "0x")
        const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)
        const account0contract = await ethers.getContractAt("RayWallet", account0address, custodian)
        const account1address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0)
        const account1contract = await ethers.getContractAt("RayWallet", account1address, custodian)
        const account2address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0)
        const account2contract = await ethers.getContractAt("RayWallet", account2address, custodian)
        const account3address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0)
        const account3contract = await ethers.getContractAt("RayWallet", account3address, custodian)

        console.log("Try moving ray to various raywallets.")
        await expect(rayNFT.connect(member1).transferFrom(await member1.getAddress(), account1address, 1)).to.be.rejectedWith('Cannot transfer to a Del Mundo wallet');
        await expect(rayNFT.connect(member2).transferFrom(await member2.getAddress(), account0address, 2)).to.be.rejectedWith('Cannot transfer to a Del Mundo wallet');
        await expect(rayNFT.connect(member2).transferFrom(await member2.getAddress(), account2address, 2)).to.be.rejectedWith('Cannot transfer to a Del Mundo wallet');
        await expect(rayNFT.connect(member2).transferFrom(await member2.getAddress(), account3address, 2)).to.be.rejectedWith('Cannot transfer to a Del Mundo wallet');
        await expect(rayNFT.connect(member2).transferFrom(await member2.getAddress(), account3address, 3)).to.be.rejectedWith('Cannot transfer to a Del Mundo wallet');
    })
})
