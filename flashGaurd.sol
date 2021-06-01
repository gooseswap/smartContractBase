// SPDX-License-Identifier: None

pragma solidity ^0.6.12;
abstract contract flashGaurd {
mapping (address => uint) internal tradeBlock;
    
    modifier noFlash() {
    require( tradeBlock[msg.sender] != block.number, "flashGaurd: one trade per block");
     tradeBlock[msg.sender] = block.number;
        _;

    }
}
