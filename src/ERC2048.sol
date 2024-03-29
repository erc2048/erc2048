//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library ERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library ERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

/// @notice ERC2048
///         A gas-efficient, mixed ERC20 / ERC721 implementation
///         with native liquidity and fractionalization.
///
///         This is an experimental standard designed to integrate
///         with pre-existing ERC20 / ERC721 support as smoothly as
///         possible.
///
/// @dev    In order to support full functionality of ERC20 and ERC721
///         supply assumptions are made that slightly constraint usage.
///         Ensure decimals are sufficiently large (standard 18 recommended)
///         as ids are effectively encoded in the lowest range of amounts.
///
///         NFTs are spent on ERC20 functions in a FILO queue, this is by
///         design.
///
abstract contract ERC2048 {
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation
    uint8 public immutable decimals;

    /// @dev Total supply in fractionalized representation
    uint256 public immutable totalSupply;

    /// @dev Balance of user in fractional representation
    mapping(address => uint256) public balanceOf;

    /// @dev Allowance of user in fractional representation
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev Unique id by owner
	mapping(address => uint32) private idByOwner;

    /// @dev Owner by unique id
	mapping(uint32 => address) private ownerById;

    /// @dev Global unique id
	uint32 private uniqueId;

	struct Nft {
		uint256 id;
		address owner;
        uint32 ownerId;
		uint8 level;
	}

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _nativeTotalSupply
    ) {
        require(_decimals >= 18, "decimals should >= 18");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _nativeTotalSupply * _getUnit();
        balanceOf[address(0)] = totalSupply;
    }

    /// @notice tokenURI must be implemented by child contract
    function tokenURI(uint256 id) virtual public view returns (string memory);

    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(
        address spender,
        uint256 amountOrId
    ) virtual public returns (bool) {
        require(amountOrId > 0, "amountOrId must > 0");

        if (_isAmountOrId(amountOrId)) {
            allowance[msg.sender][spender] = amountOrId;

            emit ERC20Events.Approval(msg.sender, spender, amountOrId);
        } else {
            address owner = _ownerOf(amountOrId);

            require(msg.sender == owner, "Not NFT owner");

            getApproved[amountOrId] = spender;

            emit ERC721Events.Approval(owner, spender, amountOrId);
        }

        return true;
    }

    /// @notice Function for native approvals
    function setApprovalForAll(address operator, bool approved) virtual public {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ERC721Events.ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for fractional transfers
    function transfer(
        address to,
        uint256 amount
    ) virtual public returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id if amount less than or equal to current max id
    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) virtual public {
        require(to != address(0), "Invalid recipient");

        if (_isAmountOrId(amountOrId)) {
            uint256 senderAllowance = allowance[from][msg.sender];

            require(senderAllowance >= amountOrId, "Insufficient allowance");

            allowance[from][msg.sender] = senderAllowance - amountOrId;

            _transfer(from, to, amountOrId);
        } else {
            address owner = _ownerOf(amountOrId);
            uint8 level = _extractLevelFromNftId(amountOrId);

            require(from == owner, "Not NFT owner");

            require(
                msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[amountOrId],
                "Unauthorized"
            );

			_transfer(from, to, _calcTokenAmountByLevel(level));

            delete getApproved[amountOrId];
        }
    }

    /// @notice This function is meaningless for ERC2048
    function safeTransferFrom(
        address /* from */,
        address /* to */,
        uint256 /* id */
    ) virtual public {
        revert("Unimplemented");
    }

    /// @notice This function is meaningless for ERC2048
    function safeTransferFrom(
        address /* from */,
        address /* to */,
        uint256 /* id */,
        bytes calldata /* data */
    ) virtual public {
        revert("Unimplemented");
    }

    /// @notice Function to find owner of a given id
    function ownerOf(uint256 id) virtual public view returns (address) {
		return _ownerOf(id);
    }

    /// @notice Internal function for fractional mint
    function _mint(address owner, uint256 amount) internal {
        _transfer(address(0), owner, amount);
    }

    function _remaining() internal view returns (uint256)  {
		return balanceOf[address(0)];
	}

    /// @notice Internal function for fractional transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(amount > 0, "Zero amount");
        require(to != address(0), "Invalid recipient");

		uint256 oldBalanceOfFrom = balanceOf[from];
        balanceOf[from] -= amount;

		uint256 oldBalanceOfTo = balanceOf[to];
		balanceOf[to] += amount;

        emit ERC20Events.Transfer(from, to, amount);

		_refactorNft(from, oldBalanceOfFrom, balanceOf[from]);
		_refactorNft(to, oldBalanceOfTo, balanceOf[to]);

        return true;
    }

	function _refactorNft(address owner, uint256 oldBalance, uint256 newBalance) internal {
		if (owner == address(0)) {
			return;
		}

		oldBalance /= _getUnit();
		newBalance /= _getUnit();

		uint256 burnNftDigits = oldBalance ^ (oldBalance & newBalance);
		uint256 mintNftDigits = newBalance ^ (oldBalance & newBalance);

		uint32 ownerId = _getOwnerIdOrSetNext(owner);

        uint8 level = 0;

		while (burnNftDigits > 0) {
			if (burnNftDigits & 1 == 1) {
				uint256 id = _buildNftId(ownerId, level);

				emit ERC721Events.Transfer(owner, address(0), id);
			}
			level += 1;
			burnNftDigits >>= 1;
		}

		level = 0;

		while (mintNftDigits > 0) {
			if (mintNftDigits & 1 > 0) {
				uint256 id = _buildNftId(ownerId, level);

				emit ERC721Events.Transfer(address(0), owner, id);
			}
			level += 1;
			mintNftDigits >>= 1;
		}
	}

    function _ownerOf(uint256 id) internal view returns (address) {
		uint32 ownerId = _extractOwnerIdFromNftId(id);

		address owner = ownerById[ownerId];

        require(_isNftOwned(id, owner), "NFT not found");

        return owner;
    }

    function _getOwnerIdOrSetNext(address owner) internal returns (uint32) {
		if(idByOwner[owner] == 0) {
			uniqueId += 1;
			idByOwner[owner] = uniqueId;
			ownerById[uniqueId] = owner;
		}
		return idByOwner[owner];
	}

	function _isAmountOrId(uint256 amountOrId) internal pure returns (bool) {
		return amountOrId > 0xffffffffff;
	}

    function _isNftOwned(uint256 id, address owner) internal view returns (bool) {
        uint8 level = _extractLevelFromNftId(id);
        uint256 nativeBalance = balanceOf[owner] / _getUnit();
        return owner != address(0) && nativeBalance & uint256(1) << level > 0;
    }

    function _getNft(uint256 id) internal view returns (Nft memory) {
        address owner = _ownerOf(id);
        uint32 ownerId = _extractOwnerIdFromNftId(id);
        uint8 level = _extractLevelFromNftId(id);
        return Nft({
            id: id,
            owner: owner,
            ownerId: ownerId,
            level: level
        });
    }

	function _getOwnerNfts(address owner) internal view returns (Nft[] memory) {
		if (idByOwner[owner] != 0 && balanceOf[owner] > 0) {
			uint256 balance = balanceOf[owner] / _getUnit();
			uint32 ownerId = idByOwner[owner];

			Nft[] memory tmp = new Nft[](256);

            uint8 level = 0;
			uint8 count = 0;

			while (balance > 0) {
				if (balance & 1 > 0) {
					uint256 id = _buildNftId(ownerId, level);
					Nft memory nft = Nft({
						id: id,
						owner: owner,
                        ownerId: ownerId,
						level: level
					});
					tmp[count] = nft;
					count += 1;
				}

				level += 1;
				balance >>= 1;
			}

			Nft[] memory nfts = new Nft[](count);

			while(count > 0) {
				nfts[count - 1] = tmp[count - 1];
				count -= 1;
			}

            return nfts;
		} else {
            return new Nft[](0);
        }
	}

    function _getUnit() internal view returns (uint256) {
        return 10 ** decimals;
    }

    function _buildNftId(uint32 ownerId, uint8 level) internal pure returns (uint256) {
		return (uint256(ownerId) << 8) + level;
	}

	function _extractOwnerIdFromNftId(uint256 id) internal pure returns (uint32){
		return uint32(id >> 8 & 0xffffffff);
	}

	function _extractLevelFromNftId(uint256 id) internal pure returns (uint8) {
		return uint8(id & 0xff);
	}

    function _calcTokenAmountByLevel(uint8 level) internal view returns (uint256) {
		return (uint256(1) << level) * _getUnit();
	}
}
