// contracts/PolyPlankToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PolyPlankToken is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct Promoter {
        bool isClaimed;
        bool isApproved;
    }

    Counters.Counter private _tokenIds;

    uint256 public constant MaxPlanks = 100;

    uint256 private _buyingPrice = 25 ether;
    uint256 internal _nonce = 0;
    address payable private _devWallet;

    uint256 public SalesRemaining;

    uint256[] public AvailablePlanks;

    mapping(address => Promoter) promoterClaims;

    modifier onlyPromoter() {
        require(promoterClaims[msg.sender].isApproved, "Only promoter.");
        _;
    }

    constructor(address payable devWallet, uint256 nonce) ERC721("PolyPlank GEN1", "POLYPLANKG1") {
        _nonce = nonce;
        _devWallet = devWallet;
    }

    function removeAvailablePlank(uint256 indexToRemove) internal {
        for (uint256 i = indexToRemove; i < AvailablePlanks.length - 1; i++) {
            AvailablePlanks[i] = AvailablePlanks[i + 1];
        }

        SalesRemaining--;

        AvailablePlanks.pop();
    }

    function setNonce(uint256 newNonce) external onlyOwner {
        _nonce = newNonce;
    }

    function randomIndex() internal view returns (uint256) {
        uint256 index = uint256(keccak256(abi.encodePacked(_nonce, msg.sender, block.difficulty, block.timestamp))) %
            AvailablePlanks.length;
        return index + 1;
    }

    function mintPlank(string memory tokenURI) external onlyOwner returns (uint256) {
        require(_tokenIds.current() < 100, "All tokens have been minted");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(address(this), newItemId);
        _setTokenURI(newItemId, tokenURI);

        AvailablePlanks.push(newItemId);

        SalesRemaining++;

        return newItemId;
    }

    function addPromoter(address promoterAddress) external onlyOwner {
        promoterClaims[promoterAddress].isApproved = true;
    }

    function claimPromoter() external nonReentrant onlyPromoter {
        require(1 <= SalesRemaining, "There aren't enough left to buy that many");
        require(!promoterClaims[msg.sender].isClaimed, "You have already claimed your Plank");

        uint256 indexOfSale = randomIndex();

        removeAvailablePlank(indexOfSale);

        promoterClaims[msg.sender].isClaimed = true;

        _safeTransfer(address(this), msg.sender, indexOfSale, "");
    }

    function buyPlanks(uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "Must buy at least one");
        require(msg.value == quantity * _buyingPrice, "Incorrect amount of matic sent");
        require(quantity <= SalesRemaining, "There aren't enough left to buy that many");

        _devWallet.transfer(msg.value);

        for (uint256 index = 0; index < quantity; index++) {
            uint256 indexOfSale = randomIndex();

            removeAvailablePlank(indexOfSale);

            _safeTransfer(address(this), msg.sender, indexOfSale, "");
        }
    }
}
