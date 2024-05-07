const { ethers, upgrades } = require("hardhat")
var chai = require("chai")
var  chaiAsPromised = require("chai-as-promised")
const expect = chai.expect
const { LazyMinter } = require( "../nft/nft-generator/lib/LazyMinter")
const {toNumber} = require("ethers");
chai.use(chaiAsPromised)

const CHAINID = process.env.BLOCKCHAIN_ID


async function deploy() {
    const [custodian, member1] = await ethers.getSigners()

    let nftFactory = await ethers.getContractFactory("DelMundo")
    const delMundo = await nftFactory.deploy()
    await delMundo.waitForDeployment();

    let Registry = await ethers.getContractFactory("ERC6551Registry")
    const erc6551registry = await Registry.deploy()
    await erc6551registry.waitForDeployment()

    let Account = await ethers.getContractFactory("WardrobeAccount")
    const wardrobe = await Account.deploy()
    await wardrobe.waitForDeployment()

    let WalletAccount = await ethers.getContractFactory("RayWallet")
    const wallet = await WalletAccount.deploy()
    await wallet.waitForDeployment()

    let TRAITS = await ethers.getContractFactory("DelMundoTraits")
    const traits = await TRAITS.deploy(await custodian.getAddress())
    await traits.waitForDeployment()

    console.log("Wardrobe impl address :" + await wardrobe.getAddress())

    const wallet0 = await erc6551registry.createAccount(await wallet.getAddress(), CHAINID, await delMundo.getAddress(), 0, 0, "0x")
    const wardrobe0 = await erc6551registry.createAccount(await wardrobe.getAddress(), CHAINID, await delMundo.getAddress(), 0, 1, "0x")
    const wallet0Address = await erc6551registry.account(await wallet.getAddress(), CHAINID, await delMundo.getAddress(), 0, 0)
    const wardrobe0Address = await erc6551registry.account(await wardrobe.getAddress(), CHAINID, await delMundo.getAddress(), 0, 1)

    return {
        custodian,
        member1,
        delMundo,
        wallet0Address,
        wardrobe0Address,
        wardrobe,
        traits,
    }
}

describe("Token Testing suite", function (accounts) {

    before(async () => {
    })

    it("Multiple voucher generation and minting tests", async function () {
        const { wardrobe, wallet0Address, wardrobe0Address, delMundo, member1, custodian, traits } = await deploy()
        const lazyMinter = new LazyMinter({ contract: delMundo, signer: custodian })

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")

        await delMundo.connect(custodian).redeem(voucher0)
        await delMundo.connect(custodian).redeem(voucher1)

        console.log("ensuring wardrobe returns right interface value")
        /*expect (await wardrobe.)
        */
        console.log("Transferring DelMundo NFT to the member")
        await delMundo.connect(custodian).safeTransferFrom(await custodian.getAddress(), await member1.getAddress(), 0);
        console.log("Transferring DelMundo NFT to the wallet should work - maybe it shouldn't. safe")
        await expect(delMundo.connect(custodian).transferFrom(await custodian.getAddress(), wallet0Address, 1)).to.be.rejectedWith('Cannot transfer to a Del Mundo wallet');;
        await expect(delMundo.connect(custodian).safeTransferFrom(await custodian.getAddress(), wallet0Address, 1)).to.be.eventually.be.rejected;
        console.log("Transferring DelMundo NFT to the wardrobe should fail with safe and standard transfers")
        await expect(delMundo.connect(custodian).safeTransferFrom(await custodian.getAddress(), wardrobe0Address, 1)).to.be.eventually.be.rejected;
        await expect(delMundo.connect(custodian).transferFrom(await custodian.getAddress(), wardrobe0Address, 1)).to.be.eventually.be.rejected;

        console.log("Create the traits")
        await traits.configureTrait(1, 100, "uri for trait 1");

        const idArray = [2,3,4]
        const supplyArray = [10000, 10000, 1]
        const uriArray = ["Uri for trait 2", "Uri for trait 3", "Uri for trait 4"]

        await expect( traits.configureTraitBatch([2,3], supplyArray, uriArray)).to.be.rejectedWith("All arrays need to be the same length")
        await expect( traits.configureTraitBatch([2,3,4,5], supplyArray, uriArray)).to.be.rejectedWith("All arrays need to be the same length")
        await expect( traits.configureTraitBatch(idArray, [1,1], uriArray)).to.be.rejectedWith("All arrays need to be the same length")
        await expect( traits.configureTraitBatch(idArray, [1,1,10000, 1], uriArray)).to.be.rejectedWith("All arrays need to be the same length")
        await expect( traits.configureTraitBatch(idArray, supplyArray, ["1", "2", "3", "4"])).to.be.rejectedWith("All arrays need to be the same length")
        await expect( traits.configureTraitBatch(idArray, supplyArray, ["1", "2"])).to.be.rejectedWith("All arrays need to be the same length")

        await traits.configureTraitBatch(idArray, supplyArray, uriArray)

        await traits.mint(await member1.getAddress(), 1, 1, '0x');
        await expect(traits.mint(await member1.getAddress(), 1, 100, '0x')).to.be.rejectedWith("Not enough items left for this request");
        await traits.mint(await member1.getAddress(), 2, 1, '0x');

        expect( await traits.balanceOf(await member1.getAddress(), 1)).to.equal(1);
        expect( await traits.balanceOf(await member1.getAddress(), 2)).to.equal(1);
        console.log("Amount of trait 1 to member1 :" + await traits.balanceOf(await member1.getAddress(), 1))
        console.log("Amount of trait 2 to member1 :" + await traits.balanceOf(await member1.getAddress(), 2))

        console.log("Ensuring a single unique trait cannot be extended.")
        await expect(traits.mint(await member1.getAddress(), 4, 2, '0x')).to.be.rejectedWith("Not enough items left for this request");
        await traits.mint(await member1.getAddress(), 4, 1, '0x');
        await expect(traits.mint(await member1.getAddress(), 4, 1, '0x')).to.be.rejectedWith("Not enough items left for this request");
        await expect(traits.setMaxSupply(4, 2)).to.be.rejectedWith("Item is unique, cannot create more");
    })
})
