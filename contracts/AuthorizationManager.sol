// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AuthorizationManager
 * @notice Validates and consumes off-chain generated withdrawal authorizations
 * @dev This contract does NOT hold funds. It only validates permissions.
 */
contract AuthorizationManager {
    /// @notice Address allowed to sign withdrawal authorizations
    address public immutable signer;

    /// @dev Tracks whether an authorization has already been used
    mapping(bytes32 => bool) public authorizationUsed;

    /// @notice Emitted when an authorization is successfully consumed
    event AuthorizationConsumed(
        bytes32 indexed authorizationId,
        address indexed vault,
        address indexed recipient,
        uint256 amount,
        uint256 chainId
    );

    constructor(address _signer) {
        require(_signer != address(0), "Invalid signer");
        signer = _signer;
    }

    /**
     * @notice Verifies and consumes a withdrawal authorization
     *
     * @param vault Vault contract address
     * @param recipient Recipient of the withdrawal
     * @param amount Amount authorized
     * @param chainId Blockchain network ID
     * @param authorizationId Unique authorization identifier (nonce)
     * @param signature Off-chain signature from trusted signer
     *
     * @return success True if authorization is valid and consumed
     */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 chainId,
        bytes32 authorizationId,
        bytes calldata signature
    ) external returns (bool success) {
        require(chainId == block.chainid, "Invalid chain");
        require(!authorizationUsed[authorizationId], "Authorization already used");

        // Recreate signed message
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                vault,
                recipient,
                amount,
                chainId,
                authorizationId
            )
        );

        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        require(
            recoverSigner(ethSignedMessageHash, signature) == signer,
            "Invalid signature"
        );

        // Mark authorization as consumed BEFORE returning
        authorizationUsed[authorizationId] = true;

        emit AuthorizationConsumed(
            authorizationId,
            vault,
            recipient,
            amount,
            chainId
        );

        return true;
    }

    /// @dev Recovers signer from an Ethereum signed message
    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;
        require(v == 27 || v == 28, "Invalid v");

        return ecrecover(hash, v, r, s);
    }
}
