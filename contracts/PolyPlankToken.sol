// contracts/PolyPlankToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract PolyPlankToken is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct Promoter {
        bool isClaimed;
        bool isApproved;
    }

    Counters.Counter private _tokenIds;

    uint256 public constant MaxPlanks = 100;

    uint256 private _buyingPrice = 25 ether;
    address payable private _devWallet;

    uint256 public salesRemaining;
    mapping(uint256 => uint256) public availablePlanks;

    mapping(address => Promoter) private promoterClaims;
    mapping(address => uint256) private nonce;

    modifier onlyPromoter() {
        require(promoterClaims[msg.sender].isApproved, "Only promoter.");
        _;
    }

    constructor(address payable devWallet) ERC721("PolyPlank GEN1", "POLYPLANKG1") {
        _devWallet = devWallet;
    }

    function removeAvailablePlank(uint256 indexToRemove) internal {
        salesRemaining--;
        availablePlanks[indexToRemove] = availablePlanks[salesRemaining];
        availablePlanks[salesRemaining] = 0;
    }

    /**
     * @dev it is Okay, here we have block.difficulty to strength randomness
     */
    function randomIndex() internal returns (uint256) {
        nonce[msg.sender]++;
        uint256 index = uint256(keccak256(abi.encodePacked(nonce[msg.sender], msg.sender, block.difficulty))) % salesRemaining;
        return index;
    }

    function mintPlank(string memory tokenURI) external onlyOwner returns (uint256) {
        require(_tokenIds.current() < 100, "All tokens have been minted");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(address(this), newItemId);
        _setTokenURI(newItemId, tokenURI);
        availablePlanks[salesRemaining] = newItemId;

        salesRemaining++;

        return newItemId;
    }

    function addPromoter(address promoterAddress) external onlyOwner {
        promoterClaims[promoterAddress].isApproved = true;
    }

    function claimPromoter() external nonReentrant onlyPromoter {
        require(1 <= salesRemaining, "There aren't enough left to buy that many");
        require(!promoterClaims[msg.sender].isClaimed, "You have already claimed your Plank");
        uint256 indexOfSale = randomIndex();
        uint256 tokenId = availablePlanks[indexOfSale];
        removeAvailablePlank(indexOfSale);
        promoterClaims[msg.sender].isClaimed = true;
        _safeTransfer(address(this), msg.sender, tokenId, "");
    }

    function buyPlanks(uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "Must buy at least one");
        require(msg.value == quantity * _buyingPrice, "Incorrect amount of matic sent");
        require(quantity <= salesRemaining, "There aren't enough left to buy that many");

        _devWallet.transfer(msg.value);

        for (uint256 index = 0; index < quantity; index++) {
            uint256 indexOfSale = randomIndex();
            uint256 tokenId = availablePlanks[indexOfSale];
            removeAvailablePlank(indexOfSale);
            _safeTransfer(address(this), msg.sender, tokenId, "");
        }
    }
}
