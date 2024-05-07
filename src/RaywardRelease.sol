// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract TokenVesting is AccessControl {
    ERC20 public rayward;

    struct Vesting {
        uint256 amount;
        uint256 start;
        uint256 duration;
        uint256 claimed;
    }

    mapping(address => Vesting[]) public vestedAmount;

    event RaywardsReleased(address beneficiary, uint256 amount);

    constructor(ERC20 _token) {
        require(address(_token) != address(0));
        rayward = _token;
    }

    function addVesting(
        address _beneficiary,
        uint256 _amount,
        uint256 _start,
        uint256 _duration
    ) public {
        vestedAmount[_beneficiary].push(Vesting({
            amount: _amount,
            start: _start,
            duration: _duration,
            claimed: 0
        }));
    }

    function claim(uint256 _vestingIndex) public {
        Vesting storage vesting = vestedAmount[msg.sender][_vestingIndex];

        require(block.timestamp >= vesting.start, "Vesting not started");

        uint256 elapsed = block.timestamp - vesting.start;
        uint256 releasable = elapsed >= vesting.duration ?
            vesting.amount :
            vesting.amount * elapsed/vesting.duration;

        uint256 toClaim = releasable - vesting.claimed;
        require(toClaim > 0, "Nothing to claim");

        vesting.claimed = vesting.claimed + toClaim;
        rayward.transfer(msg.sender, toClaim);

        emit RaywardsReleased(msg.sender, toClaim);
    }

    function getMyVestings() external view returns (Vesting[] memory) {
        return vestedAmount[msg.sender];
    }
}
