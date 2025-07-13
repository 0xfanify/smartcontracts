// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {Ownable} from "lib/solady/src/auth/Ownable.sol";
import {LibString} from "lib/solady/src/utils/LibString.sol";

contract TeamNFT is ERC721, Ownable {
    using LibString for uint256;

    struct Metadata {
        uint256 teamId;
        uint256 seasonId;
    }

    uint256 private _tokenIds;
    address public stakeContract;

    mapping(uint256 => Metadata) private _tokenMetadata;
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyStakeContract() {
        if (msg.sender != stakeContract) {
            revert("Only stake contract can call this");
        }
        _;
    }

    constructor() {
        _initializeOwner(msg.sender);
    }

    function setStakeContract(address _stakeContract) external onlyOwner {
        stakeContract = _stakeContract;
    }

    function mintTo(address to, uint256 teamId, uint256 seasonId) external onlyStakeContract returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _mint(to, newTokenId);
        _tokenMetadata[newTokenId] = Metadata(teamId, seasonId);

        // Set token URI with metadata
        string memory uri = _buildTokenURI(teamId, seasonId);
        _tokenURIs[newTokenId] = uri;

        return newTokenId;
    }

    function burn(uint256 tokenId) external onlyStakeContract {
        _burn(tokenId);
        delete _tokenMetadata[tokenId];
        delete _tokenURIs[tokenId];
    }

    function getMetadata(uint256 tokenId) external view returns (uint256 teamId, uint256 seasonId) {
        if (!_exists(tokenId)) {
            revert("Token does not exist");
        }
        Metadata memory data = _tokenMetadata[tokenId];
        return (data.teamId, data.seasonId);
    }

    // ------------------------------
    // Override transfer & approve functions to disable transfers
    // ------------------------------
    function approve(address, uint256) public payable override {
        revert("Transfers disabled");
    }

    function setApprovalForAll(address, bool) public override {
        revert("Transfers disabled");
    }

    function transferFrom(address, address, uint256) public payable override {
        revert("Transfers disabled");
    }

    function safeTransferFrom(address, address, uint256) public payable override {
        revert("Transfers disabled");
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) public payable override {
        revert("Transfers disabled");
    }

    // ------------------------------
    // ERC721 overrides
    // ------------------------------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert("Token does not exist");
        }
        return _tokenURIs[tokenId];
    }

    function name() public pure override returns (string memory) {
        return "TeamNFT";
    }

    function symbol() public pure override returns (string memory) {
        return "TNFT";
    }

    // ------------------------------
    // Token URI helper
    // ------------------------------
    function _buildTokenURI(uint256 teamId, uint256 seasonId) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://api.funify.xyz/metadata?teamId=",
                teamId.toString(),
                "&seasonId=",
                seasonId.toString()
            )
        );
    }
} 