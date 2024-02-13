//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC2048.sol";
import "./StringUtils.sol";

contract Binary is ERC2048{
	address payable public treasury;

	constructor(address payable _treasury) ERC2048("Binary", "BINARY", 18, 1024 ** 2) {
		treasury = _treasury;
		_mint(address(this), totalSupply);
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

	function tokenURI(uint256 id) override public pure returns (string memory) {
        ownerOf(id); // check NFT exists

        uint8 level = _extractLevelFromNftId(id);
        string memory idStr = StringUtils.uintToString(id);
        string memory amountStr = StringUtils.uintToString(2 ** level);

        string memory name = StringUtils.concat(StringUtils.concat('"name":"Binary:', idStr), '",');
        string memory description = '"description":"A collection of 1048576 replicants enabled by ERC2048, an experimental token standard.",';
        string memory image = StringUtils.concat(StringUtils.concat('"image":"https://raw.githubusercontent.com/erc2048/erc2048/main/assets/', amountStr), '.svg"');
        string memory json = StringUtils.concat('{', name);
        json = StringUtils.concat(json, description);
        json = StringUtils.concat(json, image);
        json = StringUtils.concat(json, '}');
        return StringUtils.concat('data:application/json;utf8,', json);
	}

	function getOwnerNfts(address owner) public view returns (Nft[] memory) {
		return _getOwnerNfts(owner);
	}
}
