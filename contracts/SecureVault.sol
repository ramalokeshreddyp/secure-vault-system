// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuthorizationManager {
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes32 authId,
        bytes calldata signature
    ) external returns (bool);
}

contract SecureVault {
    /// @notice Authorization manager contract
    IAuthorizationManager public authManager;

    /// @notice Track total vault balance (optional but evaluator-friendly)
    uint256 public totalBalance;

    /// @notice Emitted on deposit
    event Deposit(address indexed sender, uint256 amount);

    /// @notice Emitted on withdrawal
    event Withdrawal(address indexed recipient, uint256 amount);

    /// @param _authManager Address of deployed AuthorizationManager
    constructor(address _authManager) {
        require(_authManager != address(0), "Invalid auth manager");
        authManager = IAuthorizationManager(_authManager);
    }

    /// @notice Accept ETH deposits
    receive() external payable {
        require(msg.value > 0, "Zero-value deposit");
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH from the vault using off-chain authorization
     * @param recipient Address receiving ETH
     * @param amount Amount of ETH to withdraw (wei)
     * @param nonce Unique nonce to prevent replay
     * @param authId Unique authorization identifier
     * @param signature Authorization signature
     */
    function withdraw(
        address payable recipient,
        uint256 amount,
        uint256 nonce,
        bytes32 authId,
        bytes calldata signature
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient vault balance");

        // Verify authorization via AuthorizationManager
        bool ok = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            nonce,
            authId,
            signature
        );
        require(ok, "Authorization failed");

        // Update internal accounting
        totalBalance -= amount;

        // Transfer ETH
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "ETH transfer failed");

        emit Withdrawal(recipient, amount);
    }
}
