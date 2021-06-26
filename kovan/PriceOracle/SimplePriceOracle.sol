pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./DErc20.sol";

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint) prices;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    function getUnderlyingPrice(DToken dToken) public view returns (uint) {
        if (dankareStrings(dToken.symbol(), "dETH")) {
            return 1e18;
        } else {
            return prices[address(DErc20(address(dToken)).underlying())];
        }
    }

    function setUnderlyingPrice(DToken dToken, uint underlyingPriceMantissa) public {
        address asset = address(DErc20(address(dToken)).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint price) public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function dankareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}