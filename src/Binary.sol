//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC2048.sol";
import "./StringUtils.sol";

contract Binary is ERC2048{
	address payable public treasury;

	constructor(address payable _treasury) ERC2048("Binary", "BINARY", 18, 2048 * 2048) {
		treasury = _treasury;
		_mint(address(this), totalSupply);
	}

	function remaining() public view returns (uint256)  {
		return balanceOf[address(this)];
	}

	function mint() public payable {
		uint256 amount = msg.value * 10000; // 0.0001 ETH per token
		require(amount <= balanceOf[address(this)], "Exceed max mint amount");
		_transfer(address(this), msg.sender, amount);
		treasury.transfer(msg.value);
	}

	function tokenURI(uint256 id) override public view returns (string memory) {
        ownerOf(id); // check NFT exists

        uint8 level = _extractLevelFromNftId(id);
        string memory idStr = StringUtils.uintToString(id);
        string memory amountStr = StringUtils.uintToString(2 ** level);

        string memory name = StringUtils.concat(StringUtils.concat('"name":"Binary#', idStr), '",');
        string memory description = '"description":"A collection of 1048576 replicants enabled by ERC2048, an experimental token standard.",';
        string memory image = StringUtils.concat(StringUtils.concat('"image":"https://raw.githubusercontent.com/erc2048/erc2048/main/assets/', amountStr), '.svg"');
        string memory json = StringUtils.concat('{', name);
        json = StringUtils.concat(json, description);
        json = StringUtils.concat(json, image);
        json = StringUtils.concat(json, '}');
        return StringUtils.concat('data:application/json;utf8,', json);
	}

	function getNft(uint256 id) public view returns (Nft memory) {
		return _getNft(id);
	}

	function getOwnerNfts(address owner) public view returns (Nft[] memory) {
		return _getOwnerNfts(owner);
	}
}
