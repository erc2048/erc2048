//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC2048.sol";

contract Binary is ERC2048{
	address payable public treasury;

	constructor(address payable _treasury) ERC2048("Binary", "BINARY", 18, 1024 ** 2) {
		balanceOf[address(this)] = 1024 ** 2 * _getUnit();
		treasury = _treasury;
	}

	function getRemainingNativeAmount() public view returns (uint256)  {
		return balanceOf[address(this)] / _getUnit();
	}

	function getInitialMintPrice(uint256 nativeAmount) public pure returns (uint256) {
		return nativeAmount * 10 ** 15 ;
	}

	function initialMint(uint256 nativeAmount) public payable {
		uint256 amount = nativeAmount * _getUnit();
		require(amount > 0, "Mint amount should > 0");
		require(amount <= balanceOf[address(this)], "Exceed max mint amount");
		require(msg.value == getInitialMintPrice(nativeAmount), "Attached Ethers doesn't match");
		_transfer(address(this), msg.sender, amount);
		treasury.transfer(msg.value);
	}

	function tokenURI(uint256 id) pure public override returns (string memory) {
		// todo
	}

	function getOwnerNfts(address owner) public view returns(Nft[] memory) {
		return _getOwnerNfts(owner);
	}
}
