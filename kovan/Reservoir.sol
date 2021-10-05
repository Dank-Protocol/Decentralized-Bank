pragma solidity ^0.5.16;

/**
 * @title Reservoir Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Dank
 */

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() public {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Reservoir is Ownable {

    /// @notice The block number when the Reservoir started (immutable)
    uint public dripStart;

    /// @notice Tokens per block that to drip to target (immutable)
    uint public dripRate;

    /// @notice Reference to token to drip (immutable)
    EIP20Interface public token;

    /// @notice Target to receive dripped tokens (immutable)
    address public target0;
    address public target1;

    /// @notice Amount that has already been dripped
    uint public dripped;

    /**
      * @notice Constructs a Reservoir
      * @param dripRate_ Numer of tokens per block to drip
      * @param token_ The token to drip
      * @param target0_ The recipient of dripped tokens
      * @param target1_ The recipient of dripped tokens
      */
    constructor(uint dripRate_, EIP20Interface token_, address target0_, address target1_) public {
        dripStart = block.number;
        dripRate = dripRate_;
        token = token_;
        target0 = target0_;
        target1 = target1_;
        dripped = 0;
    }

    /**
      * @notice Drips the maximum amount of tokens to match the drip rate since inception
      * @dev Note: this will only drip up to the amount of tokens available.
      * @return The amount of tokens dripped in this call
      */
    function drip() public returns (uint) {
        // First, read storage into memory
        EIP20Interface token_ = token;
        uint reservoirBalance_ = token_.balanceOf(address(this));
        // TODO: Verify this is a static call
        uint dripRate_ = dripRate;
        uint dripStart_ = dripStart;
        uint dripped_ = dripped;
        address target0_ = target0;
        address target1_ = target1;
        uint blockNumber_ = block.number;

        // Next, calculate intermediate values
        uint dripTotal_ = mul(dripRate_, blockNumber_ - dripStart_, "dripTotal overflow");
        uint deltaDrip_ = sub(dripTotal_, dripped_, "deltaDrip underflow");
        uint toDrip_ = min(reservoirBalance_, deltaDrip_);
        uint drippedNext_ = add(dripped_, toDrip_, "tautological");

        // Finally, write new `dripped` value and transfer tokens to target
        dripped = drippedNext_;
        //         1 / 2
        uint maltAmount = div(mul(toDrip_, 5, "maltAmount overflow"), 10);
        token_.transfer(target0_, maltAmount);
        token_.transfer(target1_, maltAmount);

        return toDrip_;
    }

    /* Internal helper functions for safe math */

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }

    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }
}

import "./EIP20Interface.sol";