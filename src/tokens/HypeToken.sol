// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "solady/tokens/ERC20.sol";

contract HypeToken is ERC20 {
    address public owner;
    bool private _locked;
    address public fanifyContract;

    // Events
    event TokensStaked(address indexed user, uint256 ethAmount, uint256 tokensMinted);
    event TokensUnstaked(address indexed user, uint256 tokensBurned, uint256 ethReturned);
    event TokensMinted(address indexed to, uint256 amount, address indexed by);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
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
        revert("HYPE tokens are non-transferable");
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (msg.sender == fanifyContract || from == fanifyContract || to == fanifyContract) {
            return super.transferFrom(from, to, amount);
        }
        revert("HYPE tokens are non-transferable");
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (spender == fanifyContract) {
            return super.approve(spender, amount);
        }
        revert("HYPE tokens are non-transferable");
    }

    function stake() public payable nonReentrant {
        if (msg.value < 1 ether) {
            revert("Not enough ETH");
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
            revert("Insufficient balance to unstake");
        }
        if (_amount == 0) {
            revert("Cannot unstake zero amount");
        }
        uint256 ethToReturn = _amount / 1000;
        if (ethToReturn == 0) {
            revert("Amount too small to unstake");
        }
        if (address(this).balance < ethToReturn) {
            revert("Insufficient contract balance");
        }

        // Burn tokens first to prevent reentrancy
        _burn(msg.sender, _amount);

        (bool success,) = payable(msg.sender).call{value: ethToReturn}("");
        if (!success) {
            revert("ETH transfer failed");
        }
        emit TokensUnstaked(msg.sender, _amount, ethToReturn);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Cannot mint zero amount");
        _mint(to, amount);
        emit TokensMinted(to, amount, msg.sender);
    }
}
