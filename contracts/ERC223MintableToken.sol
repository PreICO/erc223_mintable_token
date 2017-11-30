/* ERC223 mintable token
   Copyright (C) 2017  Sergey Sherkunov <leinlawun@leinlawun.org>

   This file is part of ERC223 mintable token.

   Token is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

pragma solidity ^0.4.18;

import {SafeMath} from "./SafeMath.sol";

import {Receiver} from "./Receiver.sol";

contract ERC223MintableToken {
    using SafeMath for uint256;

    address public owner;

    address public pendingOwner;

    address public minter;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed oldTokensHolder,
                   address indexed newTokensHolder,
                   uint256 indexed tokensNumber, bytes data);

    modifier onlyOwner {
        require(msg.sender == owner);

        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner);

        _;
    }

    modifier onlyMinter {
        require(msg.sender == minter);

        _;
    }

    function ERC223MintableToken(ERC223MintableToken _minter, string _name,
                                 string _symbol, uint8 _decimals,
                                 uint256 initialTotalSupply) public {
        owner = msg.sender;

        minter = _minter;

        name = _name;

        symbol = _symbol;

        decimals = _decimals;

        totalSupply = initialTotalSupply;
    }

    function transferOwnership(address newOwner) public onlyOwner
                              returns(bool) {
        pendingOwner = newOwner;

        return true;
    }

    function claimOwnership() public onlyPendingOwner returns(bool) {
        owner = pendingOwner;

        return true;
    }

    function setMinter(address newMinter) public onlyOwner returns(bool) {
        minter = newMinter;

        return true;
    }

    function transfer(address newTokensHolder, uint256 tokensNumber) public
                     returns(bool) {
        bytes memory empty;

        return transfer(newTokensHolder, tokensNumber, empty);
    }

    function transfer(address newTokensHolder, uint256 tokensNumber, bytes data)
                     public returns(bool) {
        transfer(msg.sender, newTokensHolder, tokensNumber, data);

        return true;
    }

    function minterTransfer(address newTokensHolder, uint256 tokensNumber)
                           public onlyMinter returns(bool) {
        bytes memory empty;

        return minterTransfer(newTokensHolder, tokensNumber, empty);
    }

    function minterTransfer(address newTokensHolder, uint256 tokensNumber,
                            bytes data) public onlyMinter returns(bool)  {
        transfer(this, newTokensHolder, tokensNumber, data);

        return true;
    }

    function mint(uint256 tokensNumber) public onlyMinter returns(bool) {
        totalSupply = totalSupply.add(tokensNumber);

        balanceOf[this] = balanceOf[this].add(tokensNumber);

        return true;
    }

    function transfer(address oldTokensHolder, address newTokensHolder,
                      uint256 tokensNumber, bytes data) private {
        balanceOf[oldTokensHolder] =
            balanceOf[oldTokensHolder].sub(tokensNumber);

        balanceOf[newTokensHolder] =
            balanceOf[newTokensHolder].add(tokensNumber);

        uint256 length;

        assembly {
            length := extcodesize(newTokensHolder)
        }

        if(length > 0) {
            var receiver = Receiver(newTokensHolder);

            receiver.tokenFallback(oldTokensHolder, tokensNumber, data);
        }

        Transfer(oldTokensHolder, newTokensHolder, tokensNumber, data);
    }
}
