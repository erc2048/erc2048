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

abstract contract ERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
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
 
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Errors
    error NotFound();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();
    error Unauthorized();

    // Metadata
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation
    uint8 public immutable decimals;

    /// @dev Total supply in fractionalized representation
    uint256 public immutable totalSupply;

    // Mappings
    /// @dev Balance of user in fractional representation
    mapping(address => uint256) public balanceOf;

    /// @dev Allowance of user in fractional representation
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    mapping(address => mapping(address => bool)) public isApprovedForAll;

	mapping(address => uint32) public userIdOfOwner;
	mapping(uint32 => address) public ownerOfUserId;
	uint32 private uniqueUserId;

	struct Nft {
		uint256 nftId;
		address owner;
		uint8 level;
	}

    // Constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _nativeTotalSupply
    ) {
        require(_decimals >= 18, "Decimals should >= 18");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _nativeTotalSupply * _getUnit();
    }

    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view virtual returns (address owner) {
		(uint32 userId, ) = _getUserIdAndLevel(id);
		owner = ownerOfUserId[userId];
        if (owner == address(0)) {
            revert NotFound();
        }
    }

    /// @notice tokenURI must be implemented by child contract
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(
        address spender,
        uint256 amountOrId
    ) public virtual returns (bool) {
        require(amountOrId > 0, "amountOrId must > 0");

        if (_isNftIdOrAmount(amountOrId)) {
			address owner = ownerOf(amountOrId);

            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert Unauthorized();
            }

            getApproved[amountOrId] = spender;

            emit ERC721Events.Approval(owner, spender, amountOrId);
        } else {
            allowance[msg.sender][spender] = amountOrId;

            emit ERC20Events.Approval(msg.sender, spender, amountOrId);
        }

        return true;
    }

    /// @notice Function for native approvals
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public virtual {
        if (_isNftIdOrAmount(amountOrId)) {
			(uint32 userId, uint8 level) = _getUserIdAndLevel(amountOrId);
			address owner = ownerOfUserId[userId];
            if (from != owner) {
                revert InvalidSender();
            }

            if (to == address(0)) {
                revert InvalidRecipient();
            }

            if (
                msg.sender != from &&
                !isApprovedForAll[from][msg.sender] &&
                msg.sender != getApproved[amountOrId]
            ) {
                revert Unauthorized();
            }

			_transfer(from, to, _getTokenAmount(level));

            delete getApproved[amountOrId];
        } else {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max) {
                allowance[from][msg.sender] = allowed - amountOrId;
            }

            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for fractional transfers
    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for native transfers with contract support
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Function for native transfers with contract support and callback data
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Internal function for fractional transfers
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) virtual internal returns (bool) {
		uint256 oldBalanceOfFrom = balanceOf[from]; 
        balanceOf[from] -= amount;

		uint256 oldBalanceOfTo = balanceOf[to]; 
		balanceOf[to] += amount;
       
        emit ERC20Events.Transfer(from, to, amount);

		_emitNftEventsByBalance(from, oldBalanceOfFrom, balanceOf[from]);
		_emitNftEventsByBalance(to, oldBalanceOfTo, balanceOf[to]);

        return true;
    }

    // Internal utility logic
	function _isNftIdOrAmount(uint256 amountOrId) internal virtual returns (bool) {
		return amountOrId <= (0xffffffffff);
	}

	function _emitNftEventsByBalance(address owner, uint256 oldBalance, uint256 newBalance) internal {
		if (owner == address(0) || owner == address(this)) {
			return;
		}

		oldBalance /= _getUnit();
		newBalance /= _getUnit();
	
		uint256 burnNftDigits = oldBalance ^ (oldBalance & newBalance);
		uint256 mintNftDigits = newBalance ^ (oldBalance & newBalance);

		uint32 userId = _getUserIdOrDefault(owner);

        uint8 level = 0;

		while (burnNftDigits > 0) {
			if (burnNftDigits & 1 == 1) {
				uint256 nftId = _getNftId(userId, level);

				emit ERC721Events.Transfer(owner, address(0), nftId);
			}
			level += 1;
			burnNftDigits >>= 1;
		}

		level = 0;

		while (mintNftDigits > 0) {
			if (mintNftDigits & 1 > 0) {
				uint256 nftId = _getNftId(userId, level);

				emit ERC721Events.Transfer(address(0), owner, nftId);
			}
			level += 1;
			mintNftDigits >>= 1;
		}

	}

	function _getUserIdOrDefault(address owner) internal returns (uint32) {
		if(userIdOfOwner[owner] == 0) {
			uniqueUserId += 1;
			userIdOfOwner[owner] = uniqueUserId;
			ownerOfUserId[uniqueUserId] = owner;
		}
		return userIdOfOwner[owner];
	}

    function _getUnit() internal view returns (uint256) {
        return 10 ** decimals;
    }

	function _getTokenAmount(uint8 level) internal view returns (uint256) {
		return (1 << level) * _getUnit();
	}

    function _setNameSymbol(
        string memory _name,
        string memory _symbol
    ) internal {
        name = _name;
        symbol = _symbol;
    }

	function _getNftId(uint32 userId, uint8 level) virtual pure internal returns (uint256) {
		return (uint256(userId) << 8) + level;
	}

	function _getUserIdAndLevel(uint256 nftId) virtual pure internal returns (uint32 userId, uint8 level) {
		userId = _getUserIdByNftId(nftId);
        level = _getNftLevelByNftId(nftId);
	}

	function _getUserIdByNftId(uint256 nftId)virtual pure internal returns (uint32){
		return uint32(nftId >> 8 & 0xffffffff);
	}

	function _getNftLevelByNftId(uint256 nftId) virtual pure internal returns(uint8) {
		return uint8(nftId & 0xff);
	}

	function _getOwnerNfts(address owner) virtual view internal returns(Nft[] memory) {
		if (userIdOfOwner[owner] != 0 && balanceOf[owner] > 0) {
			uint256 balance = balanceOf[owner] / _getUnit();
			uint32 userId = userIdOfOwner[owner];

			Nft[] memory tmp = new Nft[](256);

            uint8 level = 0;
			uint8 count = 0;

			while (balance > 0) {
				if (balance & 1 > 0) {
					uint256 nftId = _getNftId(userId, level);
					Nft memory nft = Nft({
						nftId: nftId,
						owner: owner,
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
}
