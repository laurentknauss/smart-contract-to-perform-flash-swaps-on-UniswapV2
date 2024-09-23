// SPDX-License-Identifier: UNLICENSED
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Pair} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";

/// @title UniswapV2FlashSwap
/// @notice A contract for performing flash swaps on Uniswap V2
/// @dev This contract allows users to borrow tokens from a Uniswap V2 pair and repay them with a fee in the same transaction
contract UniswapV2FlashSwap {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    /// @notice Constructs the UniswapV2FlashSwap contract
    /// @param _pair The address of the Uniswap V2 pair contract
    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    /// @notice Initiates a flash swap
    /// @param token The address of the token to borrow
    /// @param amount The amount of tokens to borrow
    /// @dev This function triggers the flash swap by calling the Uniswap V2 pair's swap function
    function flashSwap(address token, uint256 amount) external {
        require(token == token0 || token == token1, "invalid token");

        // 1. Determine amount0Out and amount1Out
        (uint256 amount0Out, uint256 amount1Out) =
            token == token0 ? (amount, uint256(0)) : (uint256(0), amount);

        // 2. Encode token and msg.sender as bytes
        bytes memory data = abi.encode(token, msg.sender);

        // 3. Call pair.swap
        pair.swap({
            amount0Out: amount0Out,
            amount1Out: amount1Out,
            to: address(this),
            data: data
        });
    }

    /// @notice Uniswap V2 callback function
    /// @param sender The address that initiated the swap
    /// @param amount0 The amount of token0 received
    /// @param amount1 The amount of token1 received
    /// @param data Additional data with the callback
    /// @dev This function is called by the Uniswap V2 pair contract after sending the tokens
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // 1. Require msg.sender is pair contract
        // 2. Require sender is this contract
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        // 3. Decode token and caller from data
        (address token, address caller) = abi.decode(data, (address, address));
        
        // 4. Determine amount borrowed (only one of them is > 0)
        uint256 amount = token == token0 ? amount0 : amount1;

        // 5. Calculate flash swap fee and amount to repay
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        // 6. Get flash swap fee from caller
        IERC20(token).transferFrom(caller, address(this), fee);
        
        // 7. Repay Uniswap V2 pair
        IERC20(token).transfer(address(pair), amountToRepay);
    }
}