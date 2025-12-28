// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorizationManager is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    mapping(bytes32 => bool) public consumed;
    mapping(address => bool) public validVaults;

    event AuthorizationConsumed(bytes32 indexed authHash);
    event VaultRegistered(address vault);

    constructor() Ownable(msg.sender) {}

    function registerVault(address vault) external onlyOwner {
        require(vault != address(0), "Invalid vault");
        validVaults[vault] = true;
        emit VaultRegistered(vault);
    }

    function getAuthorizationHash(
        address vault,
        address recipient,
        uint256 amount,
        uint256 chainId,
        bytes32 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(vault, recipient, amount, chainId, nonce));
    }

    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 chainId,
        bytes32 nonce,
        bytes calldata signature
    ) external returns (bool) {
        require(validVaults[msg.sender], "Unregistered vault");

        bytes32 authHash = getAuthorizationHash(vault, recipient, amount, chainId, nonce);
        require(!consumed[authHash], "Authorization already used");

        bytes32 ethHash = authHash.toEthSignedMessageHash();
        address signer = ECDSA.recover(ethHash, signature);
        require(signer == owner(), "Invalid signature");

        consumed[authHash] = true;
        emit AuthorizationConsumed(authHash);
        return true;
    }
}
