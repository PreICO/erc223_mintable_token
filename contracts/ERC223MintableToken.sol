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

contract ERC223MintableToken is Receiver {
    using SafeMath for uint256;

    enum TernarySwitch {
        Undefined,
        Disabled,
        Enabled
    }

    address public owner;

    address public pendingOwner;

    address public minter;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    //For backward compatibility with ERC20.
    mapping (address => mapping (address => uint256)) public allowance;

    bool public minterTransferLocked = false;

    bool public mintLocked;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    mapping(address => TernarySwitch) public securityHoleForCompatibilityOf;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    bool public securityHoleForCompatibilityOfContracts;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    bool public securityHoleForCompatibilityOfUsers;

    //For backward compatibility with ERC20.
    event Transfer(address indexed oldTokensHolder,
                   address indexed newTokensHolder, uint256 tokensNumber);

    //For backward compatibility with ERC20.
    //
    //An Attack Vector on Approve/TransferFrom Methods:
    //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    event Transfer(address indexed tokensSpender,
                   address indexed oldTokensHolder,
                   address indexed newTokensHolder, uint256 tokensNumber);

    event Transfer(address indexed oldTokensHolder,
                   address indexed newTokensHolder,
                   uint256 indexed tokensNumber, bytes data);

    //For backward compatibility with ERC20.
    event Approval(address indexed tokensHolder, address indexed tokensSpender,
                   uint256 newTokensNumber);

    //For backward compatibility with ERC20.
    //
    //An Attack Vector on Approve/TransferFrom Methods:
    //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    event Approval(address indexed tokensHolder, address indexed tokensSpender,
                   uint256 oldTokensNumber, uint256 newTokensNumber);

    event Mint(uint256 indexed tokensNumber);

    event Burn(address indexed oldTokensHolder, uint256 indexed tokensNumber);

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    event BadWay;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    event PossibleLossTokens;

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

    modifier onlyMinterTransferNotLocked {
        require(!minterTransferLocked);

        _;
    }

    modifier onlyMinterTransferLocked {
        require(minterTransferLocked);

        _;
    }

    modifier onlyMintNotLocked {
        require(!mintLocked);

        _;
    }

    modifier onlyThisToken {
        require(this == msg.sender);

        _;
    }

    modifier onlyEmptyData(bytes data) {
        require(data.length == 0);

        _;
    }

    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    modifier checkPayloadSize(uint256 size) {
       require(msg.data.length == size + 4);

       _;
    }

    function ERC223MintableToken(ERC223MintableToken initialMinter,
                                 string _name, string _symbol, uint8 _decimals,
                                 uint256 initialTotalSupply,
                                 bool initialMintLocked,
                            //For backward compatibility with ERC20.
                            //
                            //It is necessary to support a vulnerability in
                            //ERC20, without which something can break. In the
                            //bright future, when everyone will support ERC223,
                            //it needs to be burned with napalm.
                            bool initialSecurityHoleForCompatibilityOfContracts,
                                //For backward compatibility with ERC20.
                                //
                                //It is necessary to support a vulnerability in
                                //ERC20, without which something can break. In
                                //the bright future, when everyone will support
                                //ERC223, it needs to be burned with napalm.
                                bool initialSecurityHoleForCompatibilityOfUsers)
                                public {
        securityHoleForCompatibilityOf[this] = TernarySwitch.Disabled;

        owner = msg.sender;

        name = _name;

        symbol = _symbol;

        decimals = _decimals;

        mintLocked = initialMintLocked;

        //For backward compatibility with ERC20.
        //
        //It is necessary to support a vulnerability in ERC20, without which
        //something can break. In the bright future, when everyone will support
        //ERC223, it needs to be burned with napalm.
        securityHoleForCompatibilityOfContracts =
            initialSecurityHoleForCompatibilityOfContracts;

        //For backward compatibility with ERC20.
        //
        //It is necessary to support a vulnerability in ERC20, without which
        //something can break. In the bright future, when everyone will support
        //ERC223, it needs to be burned with napalm.
        securityHoleForCompatibilityOfUsers =
            initialSecurityHoleForCompatibilityOfUsers;

        require(setMinter(initialMinter));

        require(mint(initialTotalSupply));
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
        securityHoleForCompatibilityOf[minter] = TernarySwitch.Undefined;

        minter = newMinter;

        securityHoleForCompatibilityOf[minter] = TernarySwitch.Disabled;

        return true;
    }

    function minterTransferLock() public onlyOwner returns(bool) {
        require(mintLock());

        minterTransferLocked = true;

        return true;
    }

    function mintLock() public onlyOwner returns(bool) {
        mintLocked = true;

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    function setSecurityHoleForCompatibilityOfContracts(bool enabled) public
                                                       onlyOwner returns(bool) {
        securityHoleForCompatibilityOfContracts = enabled;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    function setSecurityHoleForCompatibilityOfUsers(bool enabled) public
                                                   onlyOwner returns(bool) {
        securityHoleForCompatibilityOfUsers = enabled;
    }

    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function transfer(address newTokensHolder, uint256 tokensNumber) public
                     checkPayloadSize(2 * 32) returns(bool) {
        bytes memory emptyData;

        return transfer(newTokensHolder, tokensNumber, emptyData);
    }

    function transfer(address newTokensHolder, uint256 tokensNumber, bytes data)
                     public returns(bool) {
        string memory emptyCustomFallback;

        return transfer(newTokensHolder, tokensNumber, data,
                        emptyCustomFallback);
    }

    function transfer(address newTokensHolder, uint256 tokensNumber, bytes data,
                      string customFallback) public returns(bool) {
        return transfer(msg.sender, newTokensHolder, tokensNumber, data,
                        customFallback, false);
    }

    //For backward compatibility with ERC20.
    //
    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function transferFrom(address oldTokensHolder, address newTokensHolder,
                          uint256 tokensNumber) public checkPayloadSize(3 * 32)
                         returns (bool) {
        var newTokensNumber =
            allowance[oldTokensHolder][msg.sender].sub(tokensNumber);

        approve(oldTokensHolder, msg.sender, newTokensNumber);

        bytes memory emptyData;
        string memory emptyCustomFallback;

        require(transfer(oldTokensHolder, newTokensHolder, tokensNumber,
                         emptyData, emptyCustomFallback, true));

        Transfer(msg.sender, oldTokensHolder, newTokensHolder, tokensNumber);

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function approve(address tokensSpender, uint256 newTokensNumber) public
                    checkPayloadSize(2 * 32) returns(bool) {
        //An Attack Vector on Approve/TransferFrom Methods:
        //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(allowance[msg.sender][tokensSpender] == 0 ||
                newTokensNumber == 0);

        approve(msg.sender, tokensSpender, newTokensNumber);

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //An Attack Vector on Approve/TransferFrom Methods:
    //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //
    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function approve(address tokensSpender, uint256 oldTokensNumber,
                     uint256 newTokensNumber) public checkPayloadSize(3 * 32)
                    returns(bool) {
        require(allowance[msg.sender][tokensSpender] == oldTokensNumber);

        approve(msg.sender, tokensSpender, newTokensNumber);

        Approval(msg.sender, tokensSpender, oldTokensNumber, newTokensNumber);

        return true;
    }

    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function minterTransfer(address newTokensHolder, uint256 tokensNumber)
                           public checkPayloadSize(2 * 32) onlyMinter
                           onlyMinterTransferNotLocked returns(bool) {
        bytes memory emptyData;

        return minterTransfer(newTokensHolder, tokensNumber, emptyData);
    }

    function minterTransfer(address newTokensHolder, uint256 tokensNumber,
                            bytes data) public onlyMinter
                           onlyMinterTransferNotLocked returns(bool)  {
        string memory emptyCustomFallback;

        return minterTransfer(newTokensHolder, tokensNumber, data,
                              emptyCustomFallback);
    }

    function minterTransfer(address newTokensHolder, uint256 tokensNumber,
                            bytes data, string customFallback) public onlyMinter
                           onlyMinterTransferNotLocked returns(bool)  {
        return transfer(this, newTokensHolder, tokensNumber, data,
                        customFallback, false);
    }

    function mint(uint256 tokensNumber) public onlyMinter onlyMintNotLocked
                 returns(bool) {
        totalSupply = totalSupply.add(tokensNumber);

        balanceOf[this] = balanceOf[this].add(tokensNumber * 10 **
                                              uint256(decimals));

        Mint(tokensNumber);

        return true;
    }

    function tokenFallback(address oldTokensHolder, uint256 tokensNumber,
                           bytes data) public onlyThisToken onlyEmptyData(data)
                          onlyMinterTransferLocked {
        Burn(oldTokensHolder, tokensNumber);
    }

    function transfer(address oldTokensHolder, address newTokensHolder,
                      uint256 tokensNumber, bytes data, string customFallback,
                      //For backward compatibility with ERC20.
                      bool isTransferFrom)
                     private returns(bool) {
        balanceOf[oldTokensHolder] =
            balanceOf[oldTokensHolder].sub(tokensNumber);

        balanceOf[newTokensHolder] =
            balanceOf[newTokensHolder].add(tokensNumber);

        bool result = true;

        if(!isTransferFrom && isContract(newTokensHolder)) {
            var receiver = Receiver(newTokensHolder);

            if(bytes(customFallback).length > 0) {
                result =
                    receiver.call(bytes4(keccak256(customFallback)),
                                  oldTokensHolder, tokensNumber, data);

                require(result);
            //For backward compatibility with ERC20.
            //
            //It is necessary to support a vulnerability in ERC20, without which
            //something can break. In the bright future, when everyone will
            //support ERC223, it needs to be burned with napalm.
            } else if(securityHoleForCompatibilityOf[oldTokensHolder] ==
                          TernarySwitch.Enabled ||
                      securityHoleForCompatibilityOf[oldTokensHolder] ==
                          TernarySwitch.Undefined &&
                      (isContract(oldTokensHolder) &&
                       securityHoleForCompatibilityOfContracts ||
                       !isContract(oldTokensHolder) &&
                       securityHoleForCompatibilityOfUsers)) {
                BadWay();

                result =
                    receiver.call(bytes4(
                             keccak256("tokenFallback(address,uint256,bytes)")),
                                  oldTokensHolder, tokensNumber, data);

                if(!result) {
                    PossibleLossTokens();
                }
            } else {
                receiver.tokenFallback(oldTokensHolder, tokensNumber, data);
            }
        }

        //For backward compatibility with ERC20.
        Transfer(oldTokensHolder, newTokensHolder, tokensNumber);

        Transfer(oldTokensHolder, newTokensHolder, tokensNumber, data);

        return result;
    }

    function isContract(address tokensHolder) private constant returns(bool) {
        uint256 length;

        assembly {
            length := extcodesize(tokensHolder)
        }

        return length > 0;
    }

    //For backward compatibility with ERC20.
    function approve(address tokensHolder, address tokensSpender,
                     uint256 newTokensNumber) private {
        allowance[tokensHolder][tokensSpender] = newTokensNumber;

        Approval(msg.sender, tokensSpender, newTokensNumber);
    }
}
