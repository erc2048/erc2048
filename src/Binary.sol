//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC2048.sol";

contract Binary is ERC2048{

	address payable public initialMintRecipient;

	constructor(address payable _recipient) ERC2048("Binary", "BINARY", 18, 1048576) {
		balanceOf[address(this)] = 1048576 * _getUnit();
		initialMintRecipient = _recipient;
	}

	function getRemainInitialNft() public view returns(uint256)  {
		return balanceOf[address(this)] / _getUnit();
	}

	function getInitialNftMintPrice(uint256 mintNftTimes) public pure returns(uint256) {
		return mintNftTimes * 10 ** 15 ;
	}

	function initialMint(uint256 times) public payable {
		require(times>0 && times<=balanceOf[address(this)], "The nft is not sufficient, use getRemainInitialNft to get remain.");
		require(msg.value == getInitialNftMintPrice(times), "The amount of eth is not correct, use getInitialNftMintPrice to get correct price.");
		_transfer(address(this), msg.sender, _getUnit() * times);
		initialMintRecipient.transfer(msg.value);
	}

	function tokenURI(uint256 id) pure public override returns (string memory) {
		// todo
	}

	function getOwnerNfts(address owner) public view returns(Nft[] memory) {
		return _getOwnerNfts(owner);
	}
}