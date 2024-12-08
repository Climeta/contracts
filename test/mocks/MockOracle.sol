// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract MockOracle {
    function fulfillRequest(address consumer, bytes32 requestId, string memory data) external {
        (bool success, ) = consumer.call(
            abi.encodeWithSignature("fulfill(bytes32,string)", requestId, data)
        );
        require(success, "Fulfillment failed");
    }
}
