// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    /* Functions */
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Get price from Chainlink contract
        (, int256 price,,,) = priceFeed.latestRoundData();

        // Cast to uint256 and multiply by 1e10 to match eth in wei
        return uint256(price * 1e10);
    }

    function convertPrice(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Get the current price
        uint256 price = getPrice(priceFeed);

        // Convert the price
        uint256 ethAmountInUsd = (price * ethAmount) / 1e18;

        // Return the price
        return ethAmountInUsd;
    }
}
