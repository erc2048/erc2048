//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC2048.sol";

pragma solidity ^0.8.0;

library StringUtils {
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

	function concat(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);

        string memory concatenated = new string(bytesA.length + bytesB.length);
        bytes memory bytesConcatenated = bytes(concatenated);

        uint256 k = 0;
        for (uint256 i = 0; i < bytesA.length; i++) {
            bytesConcatenated[k++] = bytesA[i];
        }

        for (uint256 i = 0; i < bytesB.length; i++) {
            bytesConcatenated[k++] = bytesB[i];
        }

        return string(bytesConcatenated);
    }
}

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

	function tokenURI(uint256 id) pure public override returns (string memory) {
        uint8 level = _getNftLevelByNftId(id);
        string memory idStr = StringUtils.uintToString(id);
        string memory levelStr = StringUtils.uintToString(level);

        string memory name = StringUtils.concat(StringUtils.concat('"name":"Binary#', idStr), '",');
        string memory description = '"description":"A collection of 1048576 replicants enabled by ERC2048, an experimental token standard.",';
        string memory image = StringUtils.concat(StringUtils.concat('"image":"https://github.com/erc2048/erc2048/blob/dev/assets/', levelStr), '.svg"');
        string memory json = StringUtils.concat('{', name);
        json = StringUtils.concat(json, description);
        json = StringUtils.concat(json, image);
        json = StringUtils.concat(json, '}');
        return StringUtils.concat('data:application/json;utf8,', json);
	}

	function getOwnerNfts(address owner) public view returns(Nft[] memory) {
		return _getOwnerNfts(owner);
	}
}
