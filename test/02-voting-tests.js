const { ethers, upgrades } = require("hardhat")
var chai = require("chai")
var  chaiAsPromised = require("chai-as-promised")
const { LazyMinter } = require( "../script/Voucher")
const expect = chai.expect
chai.use(chaiAsPromised)
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {getAddress} = require("ethers");
require('dotenv').config();

const CHAINID = process.env.BLOCKCHAIN_ID
const NOT_AN_ADMIN = "ClimetaCore__NotAdmin"
const NOT_WALLET_OWNER = "ClimetaCore__NotRayWallet"

async function setup() {
  const [custodian, rayOwner, founder1, founder2, charity1, charity2, charity3, member1, member2, member3, member4, benefactor1, benefactor2, benefactor3 , treasury] = await ethers.getSigners()

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

  console.log("Creating smart accounts for NFTs")
  const account0 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0, "0x")
  const account1 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0, "0x")
  const account2 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0, "0x")
  const account3 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0, "0x")
  const account4 = await erc6551registry.createAccount(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 4, 0, "0x")
  const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)


  console.log("Deploying climeta core")
  let ClimetaCore = await ethers.getContractFactory("ClimetaCore");
  const climetaCore = await upgrades.deployProxy(ClimetaCore, [await custodian.getAddress(), await rayNFT.getAddress(), await rayward.getAddress(), await erc6551registry.getAddress(), account0address])
  await climetaCore.waitForDeployment()

  console.log("Deploying auth contract")
  let AuthContract = await ethers.getContractFactory("Authorization");
  const  authContract = await upgrades.deployProxy(AuthContract, [await custodian.getAddress(), await treasury.getAddress(), await climetaCore.getAddress()])
  await authContract.waitForDeployment()
  await climetaCore.updateAuthContract(await authContract.getAddress())


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
  await rayNFT.connect(member3).redeem(voucher3, {value: ethers.parseEther("0.1")})
  await rayNFT.connect(member3).redeem(voucher4, {value: ethers.parseEther("0.1")})

  console.log("Minting some Raywards and giving them to Ray and the founders")
  await rayward.mint(founder1, 1000)
  await rayward.mint(founder2, 1000)
  await rayward.mint(await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0), 100000)

  const account0contract = await ethers.getContractAt("RayWallet", account0address, custodian)

  // Call the rayward contract as ray's smart wallet to approve the moving of raywards from Ray's wallet when called from the ClimetaCore contract.
  console.log("Setting up allowances")
  ABI = ["function approve(address, uint256)"]
  iface = new ethers.Interface(ABI)
  calldata = iface.encodeFunctionData("approve", [await climetaCore.getAddress(), 100000])
  await account0contract.connect(rayOwner).executeCall(await rayward.getAddress(), 0, calldata)

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
    charity1,
    charity2,
    charity3,
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

describe("ClimetaCore Testing Suite", function (accounts) {

  before(async () => {
  });

  it("Prove allowances", async function () {
    const {rayNFT,rayward, climetaCore, authContract, erc6551registry, erc6551account, benefactor1, benefactor2, custodian, member1, member2, member3, member4, rayOwner, charity1, charity2, charity3, founder1, treasury} = await setup()
    provider = hre.ethers.provider

    const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)
    const account0contract = await ethers.getContractAt("RayWallet", account0address, custodian)

    console.log("Setting up allowances for an account to move raywards")
    ABI = ["function approve(address, uint256)"]
    iface = new ethers.Interface(ABI)
    calldata = iface.encodeFunctionData("approve", [await benefactor1.getAddress(), 100000])
    await account0contract.connect(rayOwner).executeCall(await rayward.getAddress(), 0, calldata)

    await rayward.connect(benefactor1).transferFrom(account0address, await benefactor1.getAddress(), 100)

  })


  it("Admin group testing", async function () {
    const {rayNFT,climetaCore, custodian, rayOwner, member1, founder1, member2, charity1, treasury} = await setup()

    await expect(climetaCore.connect(member1).addBeneficiary(await charity1.getAddress(), "Charity1", "")).to.be.rejectedWith(NOT_AN_ADMIN)
    await climetaCore.addAdmin(await founder1.getAddress())

    await climetaCore.connect(founder1).addAdmin(await member1.getAddress())

    await climetaCore.connect(member1).addBeneficiary(await charity1.getAddress(), "Charity1", "")

    await expect(climetaCore.connect(member2).revokeAdmin(await member1.getAddress())).to.be.rejectedWith(NOT_AN_ADMIN)

    await climetaCore.connect(member1).revokeAdmin(await founder1.getAddress())
    await expect(climetaCore.connect(founder1).addAdmin(await member2.getAddress())).to.be.rejectedWith(NOT_AN_ADMIN)
    await expect(climetaCore.connect(member1).revokeAdmin(await member1.getAddress())).to.be.rejectedWith("Can't revoke yourself")
    await climetaCore.revokeAdmin(await member1.getAddress())
    await expect(climetaCore.connect(member1).addBeneficiary(await charity1.getAddress(), "Charity1", "")).to.be.rejectedWith(NOT_AN_ADMIN)
  })

  it("Charity loading testing", async function () {
    const {rayNFT,climetaCore, custodian, rayOwner, charity1, charity2, charity3, founder1, treasury} = await setup()

    console.log("Add charity")
    await expect(climetaCore.connect(founder1).addBeneficiary(await charity1.getAddress(), "Charity1", "")).to.be.rejectedWith(NOT_AN_ADMIN)
    await climetaCore.addBeneficiary(await charity1.getAddress(), "Charity1", "uri1")
    expect(await climetaCore.isBeneficiary(await charity1.getAddress())).to.equal(true)

    expect(await climetaCore.isBeneficiary(await charity2.getAddress())).to.equal(false)
    await expect(climetaCore.addBeneficiary(await charity2.getAddress(), "", "")).to.be.rejectedWith('Name cannot be empty')
    await climetaCore.addBeneficiary(await charity2.getAddress(), "Charity2", "uri2")
    await climetaCore.addBeneficiary(await charity2.getAddress(), "Charity2", "uri2-updated")
    expect(await climetaCore.isBeneficiary(await charity2.getAddress())).to.equal(true)

    expect(await climetaCore.isBeneficiary(await charity3.getAddress())).to.equal(false)
    await climetaCore.addBeneficiary(await charity3.getAddress(), "Charity3", "uri3")
    expect(await climetaCore.isBeneficiary(await charity3.getAddress())).to.equal(true)

    //TODO some BeneficiaryRemovals?
  })

  it("Pitch management testing", async function () {
    const {rayNFT,climetaCore, custodian, rayOwner, charity1, charity2, charity3, founder1, treasury} = await setup()
    await climetaCore.addBeneficiary(await charity1.getAddress(), "Charity1", "uri1")
    await climetaCore.addBeneficiary(await charity2.getAddress(), "Charity2", "uri2")
    await climetaCore.addBeneficiary(await charity3.getAddress(), "Charity3", "uri3")

    await expect(climetaCore.connect(founder1).addProposal(await charity1.getAddress(), "Proposal Charity1 URI")).to.be.rejectedWith(NOT_AN_ADMIN)

    // Add first proposal from charity1 and test the event coming out
    await expect(climetaCore.addProposal(await charity1.getAddress(), "Proposal Charity1 URI"))
        .to.emit(climetaCore, 'ClimetaCore__NewProposal')
        .withArgs(await charity1.getAddress(), 1, anyValue)

    // test the proposal metadatauri
    console.log("test the proposal metadatauri")
    const prop1 =await climetaCore.getProposal(1)
    expect(prop1.metadataURI).to.equal("Proposal Charity1 URI")

    // Add another proposal from the same charity with different URI
    console.log("Add another proposal from the same charity with different URI")
    await climetaCore.addProposal(await charity1.getAddress(), "Proposal Charity1 URI2")
    expect((await climetaCore.getProposal(2)).metadataURI).to.equal("Proposal Charity1 URI2")

    // Update a proposal metadata
    await climetaCore.updateProposal(2, "Proposal Charity2 URI")
    expect((await climetaCore.getProposal(2)).metadataURI).to.equal("Proposal Charity2 URI")

    await expect(climetaCore.connect(founder1).addProposal(await charity1.getAddress(), "A new one")).to.be.rejectedWith(NOT_AN_ADMIN)

  })

  it("Vote testing", async function () {
    const {rayNFT,climetaCore, authContract,custodian, rayOwner, member1, member2, member3, founder1, treasury} = await setup()
  })


  it("Full vote testing", async function () {
    const {rayNFT,rayward, climetaCore, authContract, erc6551registry, erc6551account, benefactor1, benefactor2, custodian, member1, member2, member3, member4, rayOwner, charity1, charity2, charity3, founder1, treasury} = await setup()
    provider = hre.ethers.provider
    // Add charities
    await climetaCore.addBeneficiary(await charity1.getAddress(), "Charity1", "uri1")
    await climetaCore.addBeneficiary(await charity2.getAddress(), "Charity2", "uri2")
    await climetaCore.addBeneficiary(await charity3.getAddress(), "Charity3", "uri3")
    // Add proposals
    await climetaCore.addProposal(await charity1.getAddress(), "Proposal Charity1 URI")
    await climetaCore.addProposal(await charity2.getAddress(), "Proposal Charity2 URI")
    await climetaCore.addProposal(await charity3.getAddress(), "Proposal Charity3 URI")
    // Add and approve donation
    const authContractAddress = await authContract.getAddress()
    await benefactor1.sendTransaction({to: authContractAddress, value: ethers.parseEther("100.0"),})
    await authContract.connect(custodian).approveDonation(await benefactor1.getAddress(), ethers.parseEther("100.0"))
    // TODO Is the total donated by the brand the amount after the 10% :)
    expect (await climetaCore.getTotalDonationsByAddress(await benefactor1.getAddress())).to.equal(ethers.parseEther("90.0"))


    console.log("Ensure non member cannot vote")
    await expect(climetaCore.connect(benefactor1).castVote(1)).to.be.eventually.be.rejected
    console.log("Ensure member cannot vote for 0 id")
    await expect(climetaCore.connect(member1).castVote(0)).to.be.eventually.be.rejected
    console.log("Ensure member cannot vote for proposal above range")
    await expect(climetaCore.connect(member1).castVote(3)).to.be.eventually.be.rejected
    console.log("Ensure member cannot vote for proposal not yet approved")
    await expect(climetaCore.connect(member1).castVote(1)).to.be.eventually.be.rejected

    console.log("Set up vote")
    await climetaCore.addProposalToVotingRound(1)
    await climetaCore.addProposalToVotingRound(2)
    await climetaCore.addProposalToVotingRound(3)
    expect( (await climetaCore.getProposalsThisRound()).length).to.equal(3)

    await climetaCore.removeProposalFromVotingRound(1)
    expect( (await climetaCore.getProposalsThisRound()).length).to.equal(2)
    await climetaCore.removeProposalFromVotingRound(2)
    expect( (await climetaCore.getProposalsThisRound()).length).to.equal(1)
    // ensure last proposal left is proposal 3
    expect( (await climetaCore.getProposalsThisRound())[0]).to.equal(3)
    await climetaCore.removeProposalFromVotingRound(3)
    expect( (await climetaCore.getProposalsThisRound()).length).to.equal(0)

    // Add them back in and out again
    await climetaCore.addProposalToVotingRound(1)
    await climetaCore.removeProposalFromVotingRound(1)
    await climetaCore.addProposalToVotingRound(2)
    await climetaCore.addProposalToVotingRound(3)
    await climetaCore.addProposalToVotingRound(1)
    await climetaCore.removeProposalFromVotingRound(1)
    await climetaCore.removeProposalFromVotingRound(2)
    await climetaCore.addProposalToVotingRound(2)
    await climetaCore.addProposalToVotingRound(1)
    expect( (await climetaCore.getProposalsThisRound()).length).to.equal(3)


    // get Rays own wallet address
    const account0address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 0, 0)

    // Get smart wallets for members 1-3
    const account1address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 1, 0)
    const account1contract = await ethers.getContractAt("RayWallet", account1address, custodian)
    const account2address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 2, 0)
    const account2contract = await ethers.getContractAt("RayWallet", account2address, custodian)
    const account3address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 3, 0)
    const account3contract = await ethers.getContractAt("RayWallet", account3address, custodian)
    const account4address = await erc6551registry.account(await erc6551account.getAddress(), CHAINID, await rayNFT.getAddress(), 4, 0)
    const account4contract = await ethers.getContractAt("RayWallet", account4address, custodian)

    console.log("Voting as a Ray wallet section")
    let ABI = ["function castVote(uint256)"]
    let iface = new ethers.Interface(ABI)
    voteFor1 = iface.encodeFunctionData("castVote", [1])
    voteFor2 = iface.encodeFunctionData("castVote", [2])
    voteFor0 = iface.encodeFunctionData("castVote", [0])
    voteFor10 = iface.encodeFunctionData("castVote", [10])

    // Test you can't connect to smart wallet of token owned by someone else
    await expect(account1contract.connect(member2).executeCall(await climetaCore.getAddress(), 0, voteFor1)).to.be.rejectedWith("Not token owner")
    await expect(account1contract.connect(custodian).executeCall(await climetaCore.getAddress(), 0, voteFor1)).to.be.rejectedWith("Not token owner")

    // Test we can't vote directly as non NFTs
    await expect(climetaCore.connect(member1).castVote(1)).to.be.rejectedWith(NOT_WALLET_OWNER)

    // Ensure no Raywards given out yet
    expect (await rayward.balanceOf(account1address)).to.equal(0)
    expect (await rayward.balanceOf(account2address)).to.equal(0)
    expect (await rayward.balanceOf(account3address)).to.equal(0)

    console.log("Voting as delmundos")
    // Member 1 Votes for Proposal ID 1
    await account1contract.connect(member1).executeCall(await climetaCore.getAddress(), 0, voteFor1)
    // Member 2 and Member 3 votes
    await account2contract.connect(member2).executeCall(await climetaCore.getAddress(), 0, voteFor2)
    await account3contract.connect(member3).executeCall(await climetaCore.getAddress(), 0, voteFor2)

    console.log("Testing can't vote and a non delmundo")
// Test to see if Raywards have been given out.
    expect (await rayward.balanceOf(account1address)).to.equal(100)
    expect (await rayward.balanceOf(account2address)).to.equal(100)
    expect (await rayward.balanceOf(account3address)).to.equal(100)

    // Member3 votes with second DelMundo
    expect (await rayward.balanceOf(account4address)).to.equal(0)
    await account4contract.connect(member3).executeCall(await climetaCore.getAddress(), 0, voteFor2)
    expect (await rayward.balanceOf(account4address)).to.equal(100)

    // Ensure member1 cannot vote twice nor on same proposal
    await expect(account1contract.connect(member1).executeCall(await climetaCore.getAddress(), 0, voteFor1)).to.be.rejectedWith("This RayDelMundo has already voted")
    await expect(account1contract.connect(member1).executeCall(await climetaCore.getAddress(), 0, voteFor2)).to.be.rejectedWith("This RayDelMundo has already voted")
    await expect(account3contract.connect(member3).executeCall(await climetaCore.getAddress(), 0, voteFor2)).to.be.rejectedWith("This RayDelMundo has already voted")
    await expect(account1contract.connect(member3).executeCall(await climetaCore.getAddress(), 0, voteFor2)).to.be.rejectedWith("Not token owner")

    // Ensure we can't vote on a proposal not in the voting round
    await expect(account1contract.connect(member1).executeCall(await climetaCore.getAddress(), 0, voteFor0)).to.be.rejectedWith("Can't vote on a proposal not in this round")
    await expect(account1contract.connect(member1).executeCall(await climetaCore.getAddress(), 0, voteFor10)).to.be.rejectedWith("Can't vote on a proposal not in this round")


    console.log("Ensure cannot vote directly")
    await expect(climetaCore.connect(member3).castVote(2)).to.be.eventually.be.rejected
    await expect(climetaCore.connect(member3).castVote(1)).to.be.eventually.be.rejected

    // Test final vote count before finishing round
    let proposals =  await climetaCore.getProposalsThisRound()
    for (let i = 0; i < proposals.length; i++) {
      votes = await climetaCore.getVotesForProposal(proposals[i])
      console.log("Proposal number " + proposals[i] + " with " + votes.length + " votes")
    }
    console.log("Fund total " + await provider.getBalance(await climetaCore.getAddress()))

    console.log("End vote Tests")

    expect ((await provider.getBalance(await charity1.getAddress())).toString()).to.equal("10000000000000000000000")
    expect ((await provider.getBalance(await charity2.getAddress())).toString()).to.equal("10000000000000000000000")
    expect ((await provider.getBalance(await charity3.getAddress())).toString()).to.equal("10000000000000000000000")

    await climetaCore.endVotingRound()

    // Test to make sure all fund has been dispatched.
    expect ((await provider.getBalance(await charity1.getAddress())).toString()).to.equal("10023250000000000000000")
    expect ((await provider.getBalance(await charity2.getAddress())).toString()).to.equal("10063750000000000000000")
    expect ((await provider.getBalance(await charity3.getAddress())).toString()).to.equal("10003000000000000000000")

    // Test to make sure all fund has been dispatched
    expect(await provider.getBalance(await climetaCore.getAddress())).to.equal(0)

    // Test to make sure right money has gone to the right place
    // Charity 1

    console.log("................ Second round ..............")

    await climetaCore.addProposal(await charity1.getAddress(), "Proposal2 Charity1 URI")
    await climetaCore.addProposal(await charity2.getAddress(), "Proposal2 Charity2 URI")
    await climetaCore.addProposal(await charity3.getAddress(), "Proposal2 Charity3 URI")
    await climetaCore.addProposalToVotingRound(4)
    await climetaCore.addProposalToVotingRound(5)
    await climetaCore.addProposalToVotingRound(6)

    // Test what happens when its split 3 ways and total not divisible
    await benefactor1.sendTransaction({to: authContractAddress, value: ethers.parseEther("26.0"),})
    await benefactor2.sendTransaction({to: authContractAddress, value: ethers.parseEther("50.0"),})
    await authContract.connect(custodian).approveDonation(await benefactor2.getAddress(), ethers.parseEther("50.0"))
    await authContract.connect(custodian).approveDonation(await benefactor1.getAddress(), ethers.parseEther("26.0"))

    // Test no votes simply exits with error message
    await expect(climetaCore.endVotingRound()).to.be.eventually.be.rejectedWith("No votes on this round, need to extend voting period")

    // Vote
    voteFor6 = iface.encodeFunctionData("castVote", [6])
    await account1contract.connect(member1).executeCall(await climetaCore.getAddress(), 0, voteFor6)
    await account2contract.connect(member2).executeCall(await climetaCore.getAddress(), 0, voteFor6)
    await account3contract.connect(member3).executeCall(await climetaCore.getAddress(), 0, voteFor6)
    await account4contract.connect(member3).executeCall(await climetaCore.getAddress(), 0, voteFor6)

    expect((await climetaCore.getVotesForProposal(4)).length).to.equal(0)
    expect((await climetaCore.getVotesForProposal(5)).length).to.equal(0)
    expect((await climetaCore.getVotesForProposal(6)).length).to.equal(4)

    console.log("Charity 1 before round 2 : " + ethers.formatEther(await provider.getBalance(await charity1.getAddress()) ))
    console.log("Charity 3 before round 2 : " + ethers.formatEther(await provider.getBalance(await charity3.getAddress()) ))
    await climetaCore.endVotingRound()
    console.log("Charity 1 after round 2 : " + ethers.formatEther(await provider.getBalance(await charity1.getAddress()) ))
    console.log("Charity 3 after round 2 : " + ethers.formatEther(await provider.getBalance(await charity3.getAddress()) ))

  });

});



