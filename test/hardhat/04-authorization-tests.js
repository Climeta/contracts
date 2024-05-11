const { ethers, upgrades } = require("hardhat")
var chai = require("chai")
var  chaiAsPromised = require("chai-as-promised")
const expect = chai.expect
chai.use(chaiAsPromised)

const CHAINID = process.env.BLOCKCHAIN_ID
const NOT_AUTH_CONTRACT = "ClimetaCore__NotAuthContract"

//TODO: Put some actual assertions in here - its all output only at the moment, requires review.

async function deploy() {
    const [custodian, rayOwner, founder1, founder2, founder3, beneficiary1, beneficiary2, member1, member2, member3, member4, benefactor1, benefactor2, benefactor3 , treasury] = await ethers.getSigners()

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

    console.log("Deploying climeta core")
    let ClimetaCore = await ethers.getContractFactory("ClimetaCore");
    const climetaCore = await upgrades.deployProxy(ClimetaCore, [await custodian.getAddress(), await rayNFT.getAddress(), await rayward.getAddress(), await erc6551registry.getAddress(), await erc6551account.getAddress()])
    await climetaCore.waitForDeployment()

    console.log("Deploying auth contract")
    let AuthContract = await ethers.getContractFactory("Authorization");
    const  authContract = await upgrades.deployProxy(AuthContract, [await custodian.getAddress(), await treasury.getAddress(), await climetaCore.getAddress()])
    await authContract.waitForDeployment()
    await climetaCore.updateAuthContract(await authContract.getAddress())

    return {
        custodian,
        rayOwner,
        founder1,
        founder2,
        member1,
        member2,
        member3,
        benefactor1,
        benefactor2,
        benefactor3,
        member4,
        treasury,
        rayward,
        rayNFT,
        climetaCore,
        authContract,
        erc6551registry,
        erc6551account,
    }
}

describe("Authorization Testing suite", function (accounts) {

    it ("Donation testing", async function () {
        const {
            rayNFT,
            rayward,
            authContract,
            climetaCore,
            custodian,
            rayOwner,
            member1,
            benefactor1,
            benefactor2,
            benefactor3,
            founder1,
            erc6551account,
            erc6551registry
        } = await deploy()

        const climetaCoreAddress = await climetaCore.getAddress()
        const authContractAddress = await authContract.getAddress()
        await benefactor1.sendTransaction({to: authContractAddress, value: ethers.parseEther("20.0"),})

        await benefactor2.sendTransaction({to: authContractAddress, value: ethers.parseEther("50.0"),})
        await benefactor3.sendTransaction({to: authContractAddress, value: ethers.parseEther("10.0"),})
        await benefactor3.sendTransaction({to: authContractAddress, value: ethers.parseEther("70.0"),})
        await benefactor1.sendTransaction({to: authContractAddress, value: ethers.parseEther("20.0"),})
        console.log("ensure we cannot donate to climatecore directly")

        console.log("Amount deposited to Auth contract : " + ethers.formatEther(await ethers.provider.getBalance(authContractAddress)))
        await expect(member1.sendTransaction({to: climetaCoreAddress, value: ethers.parseEther("1.0"),  })).to.be.rejectedWith(NOT_AUTH_CONTRACT)

    })
    
    it ("Approving testing", async function () {
        const {
            rayNFT,
            rayward,
            authContract,
            climetaCore,
            custodian,
            rayOwner,
            member1,
            benefactor1,
            benefactor2,
            benefactor3,
            founder1,
            erc6551account,
            erc6551registry
        } = await deploy()

        const climetaCoreAddress = await climetaCore.getAddress()
        const authContractAddress = await authContract.getAddress()
        await benefactor1.sendTransaction({to: authContractAddress, value: ethers.parseEther("20.0"),})

        await benefactor2.sendTransaction({to: authContractAddress, value: ethers.parseEther("50.0"),})
        await benefactor3.sendTransaction({to: authContractAddress, value: ethers.parseEther("10.0"),})
        await benefactor3.sendTransaction({to: authContractAddress, value: ethers.parseEther("70.0"),})
        await benefactor1.sendTransaction({to: authContractAddress, value: ethers.parseEther("20.0"),})

        console.log("Try to authorize benefactor1's transfer")
        const [addressesBefore, amountsBefore] = await authContract.getAllPendingDonations()
        console.log("Array before: " + addressesBefore)
        console.log("Array after: " + amountsBefore)
        console.log("Balance in voting contract before : " + await ethers.formatEther(await ethers.provider.getBalance(climetaCoreAddress)))
        console.log("Total ETH in auth contract before : " + await ethers.formatEther(await ethers.provider.getBalance(authContractAddress)))

        await authContract.connect(custodian).approveDonation(benefactor1.address, ethers.parseEther("20.0"))

        console.log("Balance in voting contract after : " + await ethers.formatEther(await ethers.provider.getBalance(climetaCoreAddress)))
        console.log("Total ETH in auth contract after : " + await ethers.formatEther(await ethers.provider.getBalance(authContractAddress)))
        var [addressesAfter, amountsAfter] = await authContract.getAllPendingDonations()
        console.log("Array after: " + addressesAfter)
        console.log("Array after: " + amountsAfter)

        await authContract.connect(custodian).approveDonation(benefactor1.address, ethers.parseEther("20.0"))
        var [addressesAfter, amountsAfter] = await authContract.getAllPendingDonations()
        console.log("Address Array after second approval: " + addressesAfter)
        console.log("Amount Array after second approval: " + amountsAfter)
    })

    it ("Rejection testing", async function () {
        const {
            rayNFT,
            rayward,
            authContract,
            climetaCore,
            custodian,
            rayOwner,
            member1,
            benefactor1,
            benefactor2,
            benefactor3,
            founder1,
            erc6551account,
            erc6551registry
        } = await deploy()

        const climetaCoreAddress = await climetaCore.getAddress()
        const authContractAddress = await authContract.getAddress()

        console.log("Rejecting benefactor 3 ")
        console.log("Balance benefactor before : " + await ethers.formatEther(await ethers.provider.getBalance(benefactor3.address)))
        const [addressesBeforeReject, amountsBeforeReject] = await authContract.getAllPendingDonations()
        console.log("Array before: " + addressesBeforeReject )
        console.log("Array before: " + amountsBeforeReject )
        await authContract.connect(custodian).rejectDonation(benefactor3.address, ethers.parseEther("10.0"))

        console.log("Balance benefactor after : " + await ethers.formatEther(await ethers.provider.getBalance(benefactor3.address)))
        console.log("Balance in voting contract after : " + await ethers.formatEther(await ethers.provider.getBalance(climetaCoreAddress)))
        console.log("Total ETH in auth contract after : " + await ethers.formatEther(await ethers.provider.getBalance(authContractAddress)))
        const [addressesAfterReject, amountsAfterReject] = await authContract.getAllPendingDonations()
        console.log("Array after: " + addressesAfterReject )
        console.log("Array after: " + amountsAfterReject )

        await authContract.connect(custodian).rejectDonation(benefactor3.address, ethers.parseEther("20.0"))
    })
})
