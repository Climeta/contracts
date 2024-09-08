// Import necessary libraries
const ethers = require ('ethers');
require('dotenv').config();

// Set up environment variables
const { RESCUE_PRIVATE_KEY, HACKED_PRIVATE_KEY, HACKED_ADDRESS, RESCUE_ADDRESS, ASSET_CONTRACT_ADDRESS, BASE_MAINNET_RPC } = process.env;

if (!RESCUE_PRIVATE_KEY || !HACKED_PRIVATE_KEY || !ASSET_CONTRACT_ADDRESS || !BASE_MAINNET_RPC) {
    throw new Error("Env's are missing");
}

const run = async () => {
    // Initialize providers and wallets

    console.log(BASE_MAINNET_RPC);
    const provider=  new ethers.JsonRpcProvider(BASE_MAINNET_RPC);
    const rescueWallet = new ethers.Wallet(RESCUE_PRIVATE_KEY).connect(provider);
    const hackedWallet = new ethers.Wallet(HACKED_PRIVATE_KEY).connect(provider);

    // Define ABI and Interface
    const abi = ["function safeTransferFrom(address,address,uint256,uint256,bytes)"];
    const iface = new ethers.Interface(abi);

    // Send ETH
    const sendEthTx = {
        to: HACKED_ADDRESS,
        value: ethers.parseEther('0.001'), // Amount of ETH to send
    };

    const sendEthReceipt = await rescueWallet.sendTransaction(sendEthTx);
    await sendEthReceipt.wait();

    //    safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data)

    // Transfer Assets
    const transferAssetsTx = {
        abi: abi,
        to: ASSET_CONTRACT_ADDRESS,
        data: iface.encodeFunctionData("safeTransferFrom", [
            hackedWallet.address,
            rescueWallet.address,
            1,
            1,
            "0x"
        ]),
    };

    const transferAssetsReceipt = await hackedWallet.sendTransaction(transferAssetsTx);
    await transferAssetsReceipt.wait();

    console.log('ETH sent and assets transferred successfully');
};

run();