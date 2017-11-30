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

let ERC223MintableToken = artifacts.require("./ERC223MintableToken.sol")

module.exports = (deployer) => {
  deployer.deploy(ERC223MintableToken)
}
