// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PolyERC20 is ERC20 {
    using SafeMath for uint256;

    uint256 public constant cap = 5000000000 ether;

    address[] public operators;

    modifier onlyOperator() {
        bool isOperator = false;
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == msg.sender) {
                isOperator = true;
                break;
            }
        }
        require(isOperator, "Only operator can call this function");
        _;
    }

    constructor() ERC20("AC", "AC") {}

    function mint(address to, uint256 amount) external virtual onlyOperator {
        _mint(to, amount);
    }

    function burn(uint256 amount) external virtual {
        _burn(msg.sender, amount);
    }
}
