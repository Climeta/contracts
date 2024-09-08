-include .env

.PHONY: help


generate-abi: cast
forge deploy-delmundo: ADMIN_ADDRESS=0x28292A73813b87d0E941167511D1e16C0cEb3f9f forge script script/defender/DeployDelMundo.s.sol --force --rpc-url <ALCHEMY_URL> --ffi
forge verify: forge verify-contract 0x4e936d032C5E3Dd4714b837bD71Bd1df6DA159aF src/token/DelMundo.sol:DelMundo --chain 84532 --watch --constructor-args 0x00000000000000000000000028292a73813b87d0e941167511d1e16c0ceb3f9f
verify-with-params: forge verify-contract 0xf09a905E1DBF424DA22624098C1285d2a332309c src/token/ClimetaFarcastNFTs.sol:ClimetaFarcastNFTs --chain 84532 --watch --constructor-args $(cast abi-encode "constructor(address,string)" "0x28292A73813b87d0E941167511D1e16C0cEb3f9f" "URI")


deploy-farcast-base: ADMIN_ADDRESS=0x8b6d732c9bD985DF48f1a34B4cD3ca59516E98a5 forge script script/defender/DeployClimetaFarcastNFTs.s.sol --force --rpc-url <ALCHEMY_URL> --ffi
verify-farcast-base-with-params: forge verify-contract 0x93A0216453B3D41e295ED3cd2624e0891d79D00c src/token/ClimetaFarcasterNFTs.sol:ClimetaFarcasterNFTs --chain 8453 --watch --constructor-args $(cast abi-encode "constructor(address,string)" "0x8b6d732c9bD985DF48f1a34B4cD3ca59516E98a5" "URI")

deploy-farcast-nfts-direct:
forge create --rpc-url <ALCHEMY_URL> --private-key <DEPLOY_PRIVATE_KEY> src/token/ClimetaFarcasterNFTs.sol:ClimetaFarcasterNFTs --constructor-args $(cast abi-encode "constructor(address,string)" "0x8b6d732c9bD985DF48f1a34B4cD3ca59516E98a5" "URI")

deploy-delmundo-sepolia: forge create --rpc-url <ALCHEMY_URL> --private-key <PRIVATE_KEY> src/token/DelMundo.sol:DelMundo --constructor-args $(cast abi-encode --packed "constructor(address)" "0x348F389d3C8b68cdb089E101b2e6838FfFF7A20E") --verify