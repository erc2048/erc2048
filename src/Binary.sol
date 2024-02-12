//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC2048.sol";

pragma solidity ^0.8.0;

library StringUtils {
    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
		string memory levelString = StringUtils.uint256ToString(2 ** uint256(level));
		string memory s = StringUtils.concat('<svg width="100" height="100" version="1.1" xmlns="http://www.w3.org/2000/svg"><rect x="0" y="0" width="100" height="100" fill="#EEE4DA" rx="6" ry="6" /><text x="50" y="50" alignment-baseline="middle" text-anchor="middle" font-size="40" class="number" fill="#776E65">', levelString);
		return StringUtils.concat(s, '</text></svg>');
	}

	function getOwnerNfts(address owner) public view returns(Nft[] memory) {
		return _getOwnerNfts(owner);
	}
}
