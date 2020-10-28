/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import {CalleeInterface} from "../../interfaces/CalleeInterface.sol";
import {IZeroXExchange} from "../../interfaces/ZeroXExchangeInterface.sol";
import {SafeERC20} from "../../packages/oz/SafeERC20.sol";
import {ERC20Interface} from "../../interfaces/ERC20Interface.sol";

/**
 * @author Opyn Team
 * @title Trade0x
 * @notice callee contract to trade on 0x.
 */
contract Trade0x is CalleeInterface {
    using SafeERC20 for ERC20Interface;
    IZeroXExchange public exchange;
    address public assetProxy;

    constructor(address _exchange, address _assetProxy) public {
        exchange = IZeroXExchange(_exchange);
        assetProxy = _assetProxy;
    }

    event Trade0xBatch(address indexed to, uint256 amount);
    event UnwrappedETH(address to, uint256 amount);

    function callFunction(
        address payable _sender,
        address, /* _vaultOwner */
        uint256, /* _vaultId, */
        bytes memory _data
    ) external override payable {
        (
            address takerAsset,
            uint256 totalTakerAssetAmount,
            IZeroXExchange.Order memory order,
            uint256 takerAssetFillAmount,
            bytes memory signature
        ) = abi.decode(_data, (address, uint256, IZeroXExchange.Order, uint256, bytes));

        ERC20Interface(takerAsset).safeTransferFrom(_sender, address(this), totalTakerAssetAmount);
        ERC20Interface(takerAsset).safeApprove(address(assetProxy), totalTakerAssetAmount);

        exchange.fillOrder{value: msg.value}(order, takerAssetFillAmount, signature);

        // transfer any excess fee back to user
        _sender.transfer(address(this).balance);
    }
}
