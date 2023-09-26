// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MemeCoin is ERC1155 {
    // Token name and symbol
    string public name = "Meme Coin";
    uint256 public constant EXCHANGERATE = 5000; // Number of MemeCoin per ether

    // Mapping to keep track of registered users
    mapping(address => bool) private _registeredUsers;

    // Mapping to track the balances of each token for each address
    mapping(address => uint256) private _balances;

    // Structure to represent an enrolled asset
    struct Asset {
        string name; 
        uint256 price; // Price of the asset in money tokens
        address owner; 
        address[] ownershipHistory; 
    }

    // Mapping to track enrolled assets
    mapping(uint256 => Asset) private _enrolledAssets;

    // Variable to store the ID of the next available asset token
    uint256 private _nextAssetTokenId = 1;

    constructor() ERC1155("Token") {}

    // Mint new tokens
    function mint(address account, uint256 id, uint256 amount) public {
        _mint(account, id, amount, "");
    }

    // Register a new user and give them 1000 tokens
    function registerUser() public {
        require(!_registeredUsers[msg.sender], "User is already registered");

        // Mint 1000 tokens of type 0 (adjust token ID as needed)
        mint(msg.sender, 0, 1000);

        // Mark the user as registered
        _registeredUsers[msg.sender] = true;
    }

    // Enroll a new asset
    function enrollAsset(string memory assetName, uint256 assetPrice) public {
        require(_registeredUsers[msg.sender], "User is not registered");
        require(assetPrice > 0, "Asset price must be greater than 0");

        // Create a new asset token
        uint256 tokenId = _nextAssetTokenId++;
        _enrolledAssets[tokenId] = Asset({
            name: assetName,
            price: assetPrice,
            owner: msg.sender,
            ownershipHistory: new address[](0)
        });

        // Mint the asset token to the user
        mint(msg.sender, tokenId, 1);

        // Add the initial owner to the ownership history
        _enrolledAssets[tokenId].ownershipHistory.push(msg.sender);
    }

    // Get information about an enrolled asset
    function getAssetInfo(uint256 tokenId) public view returns (string memory, uint256, address, address[] memory) {
        require(tokenId < _nextAssetTokenId, "Invalid asset token ID");
        Asset memory asset = _enrolledAssets[tokenId];
        return (asset.name, asset.price, asset.owner, asset.ownershipHistory);
    }

    // Buy an asset using money tokens
    function buyAsset(uint256 tokenId) public {
        require(_registeredUsers[msg.sender], "User is not registered");
        require(tokenId < _nextAssetTokenId, "Invalid asset token ID");

        Asset storage asset = _enrolledAssets[tokenId];
        require(msg.sender != asset.owner, "You can't buy your own asset");
        // console.log(_balances[msg.sender]);
        require(balanceOf(msg.sender, 0) >= asset.price, "Insufficient funds.");

        // Transfer the asset token to the buyer
        _safeTransferFrom(msg.sender, asset.owner, 0, asset.price, ""); //transfer mtokens from buyer to seller
        _safeTransferFrom(asset.owner, msg.sender, tokenId, 1, "");//transfer asset token from seller to buyer

        // Update ownership information
        asset.ownershipHistory.push(msg.sender);
        asset.owner = msg.sender;
    }

    // Resell an asset
    function resellAsset(uint256 tokenId, uint256 newPrice) public {
        require(_registeredUsers[msg.sender], "User is not registered");
        require(tokenId < _nextAssetTokenId, "Invalid asset token ID");
        Asset storage asset = _enrolledAssets[tokenId];
        require(msg.sender == asset.owner, "You can only resell your own asset");
        asset.price = newPrice;
    }
}


