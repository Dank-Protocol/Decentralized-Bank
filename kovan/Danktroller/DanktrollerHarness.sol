pragma solidity ^0.5.16;

import "../../contracts/Danktroller.sol";
import "../../contracts/PriceOracle.sol";

contract DanktrollerKovan is Danktroller {
    function getDankAddress() public view returns (address) {
        return 0x61460874a7196d6a22D1eE4922473664b3E95270;
    }
}

contract DanktrollerRopsten is Danktroller {
    function getDankAddress() public view returns (address) {
        return 0x1Fe16De955718CFAb7A44605458AB023838C2793;
    }
}

contract DanktrollerHarness is Danktroller {
    address dankAddress;
    uint public blockNumber;

    constructor() Danktroller() public {}

    function setPauseGuardian(address harnessedPauseGuardian) public {
        pauseGuardian = harnessedPauseGuardian;
    }

    function setDankSupplyState(address dToken, uint224 index, uint32 blockNumber_) public {
        dankSupplyState[dToken].index = index;
        dankSupplyState[dToken].block = blockNumber_;
    }

    function setDankBorrowState(address dToken, uint224 index, uint32 blockNumber_) public {
        dankBorrowState[dToken].index = index;
        dankBorrowState[dToken].block = blockNumber_;
    }

    function setDankAccrued(address user, uint userAccrued) public {
        dankAccrued[user] = userAccrued;
    }

    function setDankAddress(address dankAddress_) public {
        dankAddress = dankAddress_;
    }

    function getDankAddress() public view returns (address) {
        return dankAddress;
    }

    function setDankSpeed(address dToken, uint dankSpeed) public {
        dankSpeeds[dToken] = dankSpeed;
    }

    function setDankBorrowerIndex(address dToken, address borrower, uint index) public {
        dankBorrowerIndex[dToken][borrower] = index;
    }

    function setDankSupplierIndex(address dToken, address supplier, uint index) public {
        dankSupplierIndex[dToken][supplier] = index;
    }

    function harnessUpdateDankBorrowIndex(address dToken, uint marketBorrowIndexMantissa) public {
        updateDankBorrowIndex(dToken, Exp({mantissa: marketBorrowIndexMantissa}));
    }

    function harnessUpdateDankSupplyIndex(address dToken) public {
        updateDankSupplyIndex(dToken);
    }

    function harnessDistributeBorrowerDank(address dToken, address borrower, uint marketBorrowIndexMantissa) public {
        distributeBorrowerDank(dToken, borrower, Exp({mantissa: marketBorrowIndexMantissa}), false);
    }

    function harnessDistributeSupplierDank(address dToken, address supplier) public {
        distributeSupplierDank(dToken, supplier, false);
    }

    function harnessTransferDank(address user, uint userAccrued, uint threshold) public returns (uint) {
        return transferDank(user, userAccrued, threshold);
    }

    function harnessFastForward(uint blocks) public returns (uint) {
        blockNumber += blocks;
        return blockNumber;
    }

    function setBlockNumber(uint number) public {
        blockNumber = number;
    }

    function getBlockNumber() public view returns (uint) {
        return blockNumber;
    }

    function getDankMarkets() public view returns (address[] memory) {
        uint m = allMarkets.length;
        uint n = 0;
        for (uint i = 0; i < m; i++) {
            if (markets[address(allMarkets[i])].isDanked) {
                n++;
            }
        }

        address[] memory dankMarkets = new address[](n);
        uint k = 0;
        for (uint i = 0; i < m; i++) {
            if (markets[address(allMarkets[i])].isDanked) {
                dankMarkets[k++] = address(allMarkets[i]);
            }
        }
        return dankMarkets;
    }
}

contract DanktrollerBorked {
    function _become(Unitroller unitroller, PriceOracle _oracle, uint _closeFactorMantissa, uint _maxAssets, bool _reinitializing) public {
        _oracle;
        _closeFactorMantissa;
        _maxAssets;
        _reinitializing;

        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        unitroller._acceptImplementation();
    }
}

contract BoolDanktroller is DanktrollerInterface {
    bool allowMint = true;
    bool allowRedeem = true;
    bool allowBorrow = true;
    bool allowRepayBorrow = true;
    bool allowLiquidateBorrow = true;
    bool allowSeize = true;
    bool allowTransfer = true;

    bool verifyMint = true;
    bool verifyRedeem = true;
    bool verifyBorrow = true;
    bool verifyRepayBorrow = true;
    bool verifyLiquidateBorrow = true;
    bool verifySeize = true;
    bool verifyTransfer = true;

    bool failCalculateSeizeTokens;
    uint calculatedSeizeTokens;

    uint noError = 0;
    uint opaqueError = noError + 11; // an arbitrary, opaque error code

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata _dTokens) external returns (uint[] memory) {
        _dTokens;
        uint[] memory ret;
        return ret;
    }

    function exitMarket(address _dToken) external returns (uint) {
        _dToken;
        return noError;
    }

    /*** Policy Hooks ***/

    function mintAllowed(address _dToken, address _minter, uint _mintAmount) public returns (uint) {
        _dToken;
        _minter;
        _mintAmount;
        return allowMint ? noError : opaqueError;
    }

    function mintVerify(address _dToken, address _minter, uint _mintAmount, uint _mintTokens) external {
        _dToken;
        _minter;
        _mintAmount;
        _mintTokens;
        require(verifyMint, "mintVerify rejected mint");
    }

    function redeemAllowed(address _dToken, address _redeemer, uint _redeemTokens) public returns (uint) {
        _dToken;
        _redeemer;
        _redeemTokens;
        return allowRedeem ? noError : opaqueError;
    }

    function redeemVerify(address _dToken, address _redeemer, uint _redeemAmount, uint _redeemTokens) external {
        _dToken;
        _redeemer;
        _redeemAmount;
        _redeemTokens;
        require(verifyRedeem, "redeemVerify rejected redeem");
    }

    function borrowAllowed(address _dToken, address _borrower, uint _borrowAmount) public returns (uint) {
        _dToken;
        _borrower;
        _borrowAmount;
        return allowBorrow ? noError : opaqueError;
    }

    function borrowVerify(address _dToken, address _borrower, uint _borrowAmount) external {
        _dToken;
        _borrower;
        _borrowAmount;
        require(verifyBorrow, "borrowVerify rejected borrow");
    }

    function repayBorrowAllowed(
        address _dToken,
        address _payer,
        address _borrower,
        uint _repayAmount) public returns (uint) {
        _dToken;
        _payer;
        _borrower;
        _repayAmount;
        return allowRepayBorrow ? noError : opaqueError;
    }

    function repayBorrowVerify(
        address _dToken,
        address _payer,
        address _borrower,
        uint _repayAmount,
        uint _borrowerIndex) external {
        _dToken;
        _payer;
        _borrower;
        _repayAmount;
        _borrowerIndex;
        require(verifyRepayBorrow, "repayBorrowVerify rejected repayBorrow");
    }

    function liquidateBorrowAllowed(
        address _dTokenBorrowed,
        address _dTokenCollateral,
        address _liquidator,
        address _borrower,
        uint _repayAmount) public returns (uint) {
        _dTokenBorrowed;
        _dTokenCollateral;
        _liquidator;
        _borrower;
        _repayAmount;
        return allowLiquidateBorrow ? noError : opaqueError;
    }

    function liquidateBorrowVerify(
        address _dTokenBorrowed,
        address _dTokenCollateral,
        address _liquidator,
        address _borrower,
        uint _repayAmount,
        uint _seizeTokens) external {
        _dTokenBorrowed;
        _dTokenCollateral;
        _liquidator;
        _borrower;
        _repayAmount;
        _seizeTokens;
        require(verifyLiquidateBorrow, "liquidateBorrowVerify rejected liquidateBorrow");
    }

    function seizeAllowed(
        address _dTokenCollateral,
        address _dTokenBorrowed,
        address _borrower,
        address _liquidator,
        uint _seizeTokens) public returns (uint) {
        _dTokenCollateral;
        _dTokenBorrowed;
        _liquidator;
        _borrower;
        _seizeTokens;
        return allowSeize ? noError : opaqueError;
    }

    function seizeVerify(
        address _dTokenCollateral,
        address _dTokenBorrowed,
        address _liquidator,
        address _borrower,
        uint _seizeTokens) external {
        _dTokenCollateral;
        _dTokenBorrowed;
        _liquidator;
        _borrower;
        _seizeTokens;
        require(verifySeize, "seizeVerify rejected seize");
    }

    function transferAllowed(
        address _dToken,
        address _src,
        address _dst,
        uint _transferTokens) public returns (uint) {
        _dToken;
        _src;
        _dst;
        _transferTokens;
        return allowTransfer ? noError : opaqueError;
    }

    function transferVerify(
        address _dToken,
        address _src,
        address _dst,
        uint _transferTokens) external {
        _dToken;
        _src;
        _dst;
        _transferTokens;
        require(verifyTransfer, "transferVerify rejected transfer");
    }

    /*** Special Liquidation Calculation ***/

    function liquidateCalculateSeizeTokens(
        address _dTokenBorrowed,
        address _dTokenCollateral,
        uint _repayAmount) public view returns (uint, uint) {
        _dTokenBorrowed;
        _dTokenCollateral;
        _repayAmount;
        return failCalculateSeizeTokens ? (opaqueError, 0) : (noError, calculatedSeizeTokens);
    }

    /**** Mock Settors ****/

    /*** Policy Hooks ***/

    function setMintAllowed(bool allowMint_) public {
        allowMint = allowMint_;
    }

    function setMintVerify(bool verifyMint_) public {
        verifyMint = verifyMint_;
    }

    function setRedeemAllowed(bool allowRedeem_) public {
        allowRedeem = allowRedeem_;
    }

    function setRedeemVerify(bool verifyRedeem_) public {
        verifyRedeem = verifyRedeem_;
    }

    function setBorrowAllowed(bool allowBorrow_) public {
        allowBorrow = allowBorrow_;
    }

    function setBorrowVerify(bool verifyBorrow_) public {
        verifyBorrow = verifyBorrow_;
    }

    function setRepayBorrowAllowed(bool allowRepayBorrow_) public {
        allowRepayBorrow = allowRepayBorrow_;
    }

    function setRepayBorrowVerify(bool verifyRepayBorrow_) public {
        verifyRepayBorrow = verifyRepayBorrow_;
    }

    function setLiquidateBorrowAllowed(bool allowLiquidateBorrow_) public {
        allowLiquidateBorrow = allowLiquidateBorrow_;
    }

    function setLiquidateBorrowVerify(bool verifyLiquidateBorrow_) public {
        verifyLiquidateBorrow = verifyLiquidateBorrow_;
    }

    function setSeizeAllowed(bool allowSeize_) public {
        allowSeize = allowSeize_;
    }

    function setSeizeVerify(bool verifySeize_) public {
        verifySeize = verifySeize_;
    }

    function setTransferAllowed(bool allowTransfer_) public {
        allowTransfer = allowTransfer_;
    }

    function setTransferVerify(bool verifyTransfer_) public {
        verifyTransfer = verifyTransfer_;
    }

    /*** Liquidity/Liquidation Calculations ***/

    function setCalculatedSeizeTokens(uint seizeTokens_) public {
        calculatedSeizeTokens = seizeTokens_;
    }

    function setFailCalculateSeizeTokens(bool shouldFail) public {
        failCalculateSeizeTokens = shouldFail;
    }
}

contract EchoTypesDanktroller is UnitrollerAdminStorage {
    function stringy(string memory s) public pure returns(string memory) {
        return s;
    }

    function addresses(address a) public pure returns(address) {
        return a;
    }

    function booly(bool b) public pure returns(bool) {
        return b;
    }

    function listOInts(uint[] memory u) public pure returns(uint[] memory) {
        return u;
    }

    function reverty() public pure {
        require(false, "gotcha sucka");
    }

    function becomeBrains(address payable unitroller) public {
        Unitroller(unitroller)._acceptImplementation();
    }
}