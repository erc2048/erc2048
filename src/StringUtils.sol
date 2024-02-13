//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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
