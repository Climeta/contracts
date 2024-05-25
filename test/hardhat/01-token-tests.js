const { ethers, upgrades } = require("hardhat")
var chai = require("chai")
var  chaiAsPromised = require("chai-as-promised")
const expect = chai.expect
const { LazyMinter } = require( "../../script/Voucher")
const {toNumber} = require("ethers");
chai.use(chaiAsPromised)


async function deploy() {
    const [custodian, member1, member2, member3, member4] = await ethers.getSigners()

    let factory = await ethers.getContractFactory("DelMundo")
    const contract = await factory.deploy(await custodian.getAddress())
    await contract.waitForDeployment();

    let repFactory = await ethers.getContractFactory("Rayputation")
    const repcontract = await repFactory.deploy(await custodian.getAddress())
    await repcontract.waitForDeployment();

    return {
        custodian,
        member1,
        member2,
        member3,
        member4,
        contract,
        repcontract
    }
}

describe("Token Testing suite", function (accounts) {

    before(async () => {
    })

    it("Should deploy", async function() {
        const [custodian] = await ethers.getSigners()
        const LazyNFT = await ethers.getContractFactory("DelMundo");
        const lazynft = await LazyNFT.deploy(await custodian.getAddress());
        await lazynft.waitForDeployment();
        console.log("Deployed")
    });

    it("Should redeem an NFT from a signed voucher", async function() {
        const { custodian,contract,  member1 } = await deploy()

        console.log("minter created with address : " + await custodian.getAddress())
        const lazyMinter = new LazyMinter({ contract: contract, signer: custodian })

        const voucher = await lazyMinter.createVoucher( 1, "ipfs://bafybeigdyrzt5sfp7udm7hu76suh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1").toString())

        console.log("Voucher details - tokenId: " + await voucher.tokenId + ", uri: " + await voucher.uri + ", signature: " + await voucher.signature)

        await expect(contract.connect(member1).redeem(voucher, {value: ethers.parseEther("0.01")} )).to.be.eventually.be.rejected

        await contract.connect(member1).redeem(voucher, {value: ethers.parseEther("0.1")} )

        expect(toNumber(await contract.balanceOf(member1.getAddress()))).to.equal(1)
    });

    it("Multiple voucher generation and minting tests", async function () {
        const { contract, member1, custodian, member2, member3, member4 } = await deploy()
        const lazyMinter = new LazyMinter({ contract, signer: custodian })

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )

        await contract.connect(custodian).redeem(voucher0)
        expect(toNumber(await contract.balanceOf(custodian.getAddress()))).to.equal(1)

        expect(toNumber(await contract.balanceOf(member1.getAddress()))).to.equal(0)
        await contract.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")} )
        expect(toNumber(await contract.balanceOf(member1.getAddress()))).to.equal(1)

        await expect(contract.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")} )).to.be.rejectedWith('ERC721InvalidSender')
        await expect(contract.connect(member2).redeem(voucher1, {value: ethers.parseEther("0.1")} )).to.be.rejectedWith('ERC721InvalidSender')
        await expect(contract.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.01")} )).to.be.rejectedWith('InsufficientFunds')

        await contract.connect(member1).redeem(voucher2, {value: ethers.parseEther("0.1")} )
        expect(toNumber(await contract.balanceOf(member1.getAddress()))).to.equal(2)

        await contract.connect(member2).redeem(voucher3, {value: ethers.parseEther("0.1")} )
        expect(toNumber(await contract.balanceOf(member2.getAddress()))).to.equal(1)

        await contract.connect(member2).redeem(voucher4, {value: ethers.parseEther("0.2").toString()} )
    })


    it("Max supply testing", async function () {
        const { contract, member1, custodian, member2, member3, member4 } = await deploy()
        const lazyMinter = new LazyMinter({ contract, signer: custodian })

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )

        await contract.updateMaxSupply(2)
        await contract.connect(custodian).redeem(voucher0)
        await contract.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")} )
        await contract.connect(member3).redeem(voucher3, {value: ethers.parseEther("0.1")} )

        await expect(contract.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")} )).to.be.rejectedWith("SoldOut")

        await contract.updateMaxSupply(20)
        await contract.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")} )
        expect(toNumber(await contract.balanceOf(member2.getAddress()))).to.equal(1)


    })

    it("Pausing testing", async function () {
        const { contract, member1, custodian, member2, member3, member4 } = await deploy()
        const lazyMinter = new LazyMinter({ contract, signer: custodian })

        const voucher0 = await lazyMinter.createVoucher(0, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher3 = await lazyMinter.createVoucher(3, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher4 = await lazyMinter.createVoucher(4, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )

        await contract.connect(custodian).redeem(voucher0)
        await contract.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")} )
        await contract.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")} )

        await expect(contract.connect(member1).pause()).to.be.rejected
        await contract.pause()
        await expect(contract.connect(member3).redeem(voucher3, {value: ethers.parseEther("0.1")} )).to.be.rejectedWith("EnforcedPause")
        await contract.unpause()
        await expect(contract.connect(member1).unpause()).to.be.rejected
        contract.connect(member3).redeem(voucher3, {value: ethers.parseEther("0.1")} )

    })

    it("RAYputation token testing", async function () {
        const { repcontract,contract, member1, custodian, member2, member3, member4 } = await deploy()
        const lazyMinter = new LazyMinter({ contract, signer: custodian })

        const voucher1 = await lazyMinter.createVoucher(1, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        const voucher2 = await lazyMinter.createVoucher(2, "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", ethers.parseEther("0.1") )
        await contract.connect(member1).redeem(voucher1, {value: ethers.parseEther("0.1")} )
        await contract.connect(member2).redeem(voucher2, {value: ethers.parseEther("0.1")} )

        await repcontract.mint(await member1.getAddress(), 10);
        await repcontract.mint(await member2.getAddress(), 10);

        await expect(repcontract.connect(member1).transfer(await member2.getAddress(), 5)).to.be.rejectedWith("Rayputation__NotMinter()")

    })
})
