// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "solady/tokens/ERC20.sol";
import {Errors} from "../errors/Errors.sol";

contract HypeToken is ERC20, Errors {
    address public owner;
    bool private _locked;
    address public fanifyContract;
    address public seasonfyContract;

    // Events
    event TokensStaked(address indexed user, uint256 ethAmount, uint256 tokensMinted);
    event TokensUnstaked(address indexed user, uint256 tokensBurned, uint256 ethReturned);
    event TokensMinted(address indexed to, uint256 amount, address indexed by);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, NotOwner);
        _;
    }

    modifier nonReentrant() {
        require(!_locked, ReentrantCall);
        _locked = true;
        _;
        _locked = false;
    }

    constructor() {
        owner = msg.sender;
        // _mint(msg.sender, 1_000_000e18);
    }

    function setFanifyContract(address _fanifyContract) external onlyOwner {
        fanifyContract = _fanifyContract;
    }

    function setSeasonfyContract(address _seasonfyContract) external onlyOwner {
        seasonfyContract = _seasonfyContract;
    }

    function name() public pure override returns (string memory) {
        return "Hype Token";
    }

    function symbol() public pure override returns (string memory) {
        return "HYPE";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    // Override transfer functions to make token non-transferable except for Fanify contract
    function transfer(address to, uint256 amount) public override returns (bool) {
        if (msg.sender == fanifyContract || to == fanifyContract) {
            return super.transfer(to, amount);
        }
        revert(NonTransferable);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (msg.sender == fanifyContract || from == fanifyContract || to == fanifyContract) {
            return super.transferFrom(from, to, amount);
        }
        revert(NonTransferable);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (spender == fanifyContract) {
            return super.approve(spender, amount);
        }
        revert(NonTransferable);
    }

    function stake() public payable nonReentrant {
        if (msg.value < 1 ether) {
            revert(NotEnoughETH);
        }
        // // Check for overflow
        // if (msg.value > type(uint256).max / 1000) {
        //     revert("Stake amount too large");
        // }

        uint256 tokensToMint = msg.value * 1000;
        _mint(msg.sender, tokensToMint);
        emit TokensStaked(msg.sender, msg.value, tokensToMint);
    }

    function unstake(uint256 _amount) public nonReentrant {
        if (_amount > balanceOf(msg.sender)) {
            revert(InsufficientBalanceToUnstake);
        }
        if (_amount == 0) {
            revert(CannotUnstakeZero);
        }
        uint256 ethToReturn = _amount / 1000;
        if (ethToReturn == 0) {
            revert(AmountTooSmall);
        }
        if (address(this).balance < ethToReturn) {
            revert(InsufficientContractBalance);
        }

        // Burn tokens first to prevent reentrancy
        _burn(msg.sender, _amount);

        (bool success,) = payable(msg.sender).call{value: ethToReturn}("");
        if (!success) {
            revert(ETHTransferFailed);
        }
        emit TokensUnstaked(msg.sender, _amount, ethToReturn);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), CannotMintToZero);
        require(amount > 0, CannotMintZero);
        _mint(to, amount);
        emit TokensMinted(to, amount, msg.sender);
    }

    function mintBySeasonfy(address to, uint256 amount) external {
        require(msg.sender == seasonfyContract, NotOwner);
        require(to != address(0), CannotMintToZero);
        require(amount > 0, CannotMintZero);
        _mint(to, amount);
        emit TokensMinted(to, amount, msg.sender);
    }
}
