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

contract Migrations {
  address public owner;

  uint256 public last_completed_migration;

  modifier restricted() {
    require(msg.sender == owner);

     _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint256 completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    var upgraded = Migrations(new_address);

    upgraded.setCompleted(last_completed_migration);
  }
}
