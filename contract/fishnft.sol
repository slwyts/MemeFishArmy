// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MemeFishArmy is ERC1155, Ownable, ERC2981 {
    using Strings for uint256;

    // --- State Variables ---
    string public name;
    string private _baseURI;
    uint256 private _nextTokenId; 
    uint256 public maxMintsPerUser;

    mapping(address => uint256) public userMintCount;
    mapping(address => bool) public whitelist;

    uint256 public constant AIRDROP_SUPPLY = 500;
    uint256 public constant MAX_TOKEN_ID = 5000;

    // --- Events ---
    event WhitelistUpdated(address indexed user, bool added);
    event BaseURIUpdated(string newURI);
    event MaxMintsUpdated(uint256 newLimit);
    event RoyaltyUpdated(address indexed receiver, uint96 royaltyFraction);

    // --- Constructor ---
    constructor()
        ERC1155("https://fishnft.okassets.uk/metadata/{id}.json")
        Ownable(msg.sender) // The deployer is the initial owner
    {
        name = "Meme Fish Army"; // Set the collection name
        _baseURI = "https://fishnft.okassets.uk/metadata/";
        _nextTokenId = AIRDROP_SUPPLY + 1;
        maxMintsPerUser = 1;

        // Set the default royalty to 5% (500 basis points).
        // The royalty receiver is the contract owner.
        _setDefaultRoyalty(owner(), 500);

        // Mint airdrop supply to the owner
        uint256[] memory ids = new uint256[](AIRDROP_SUPPLY);
        uint256[] memory amounts = new uint256[](AIRDROP_SUPPLY);
        for (uint256 i = 0; i < AIRDROP_SUPPLY; i++) {
            ids[i] = i + 1;
            amounts[i] = 1;
        }
        _mintBatch(msg.sender, ids, amounts, "");
    }

    // --- URI Functions ---
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= MAX_TOKEN_ID, "ERC1155Metadata: URI query for nonexistent token");
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        _baseURI = newURI;
        emit BaseURIUpdated(newURI);
    }
    
    // --- Royalty Functions ---
    /**
     * @dev Sets the royalty information.
     * @param royaltyFraction The royalty percentage in basis points (e.g., 500 for 5%).
     */
    function setRoyalty(uint96 royaltyFraction) public onlyOwner {
        require(royaltyFraction <= 10000, "Royalty fraction cannot exceed 10000 basis points");
        _setDefaultRoyalty(owner(), royaltyFraction);
        emit RoyaltyUpdated(owner(), royaltyFraction);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Minting Functions ---
    function mint() public {
        require(whitelist[msg.sender], "You are not on the whitelist");        
        uint256 tokenIdToMint = _nextTokenId;
        require(tokenIdToMint <= MAX_TOKEN_ID, "All tokens have been minted");
        require(userMintCount[msg.sender] < maxMintsPerUser, "You have reached your minting limit");
        
        userMintCount[msg.sender]++;
        _nextTokenId++;
        _mint(msg.sender, tokenIdToMint, 1, "");
    }

    // --- Admin Functions ---
    function setMaxMintsPerUser(uint256 newLimit) public onlyOwner {
        require(newLimit > 0, "Limit must be greater than zero");
        maxMintsPerUser = newLimit;
        emit MaxMintsUpdated(newLimit);
    }

    function addToWhitelist(address user) public onlyOwner {
        require(user != address(0), "Cannot add the zero address");
        if (!whitelist[user]) {
            whitelist[user] = true;
            emit WhitelistUpdated(user, true);
        }
    }

    function removeFromWhitelist(address user) public onlyOwner {
        if (whitelist[user]) {
            whitelist[user] = false;
            emit WhitelistUpdated(user, false);
        }
    }
    
    function batchUpdateWhitelist(address[] calldata users, bool[] calldata statuses) public onlyOwner {
        require(users.length == statuses.length, "Arrays must have the same length");
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0)) {
                if (whitelist[users[i]] != statuses[i]) {
                    whitelist[users[i]] = statuses[i];
                    emit WhitelistUpdated(users[i], statuses[i]);
                }
            }
        }
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155) {
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(ids[i] <= AIRDROP_SUPPLY, "User-minted tokens are soulbound and cannot be transferred.");
            }
        }
        super._update(from, to, ids, amounts);
    }
}