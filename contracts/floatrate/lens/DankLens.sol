pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../DErc20.sol";
import "../DToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../Governance/GovernorAlpha.sol";
import "../Governance/Dank.sol";

interface DanktrollerLensInterface {
    function markets(address) external view returns (bool, uint256);

    function oracle() external view returns (PriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAssetsIn(address) external view returns (DToken[] memory);

    function claimDank(address) external;

    function dankAccrued(address) external view returns (uint256);

    function dankSpeeds(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);
}

interface GovernorBravoInterface {
    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 eta;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
    }

    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );

    function proposals(uint256 proposalId)
        external
        view
        returns (Proposal memory);

    function getReceipt(uint256 proposalId, address voter)
        external
        view
        returns (Receipt memory);
}

contract DankLens {
    struct DTokenMetadata {
        address dToken;
        uint256 exchangeRateCurrent;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 reserveFactorMantissa;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 totalSupply;
        uint256 totalCash;
        bool isListed;
        uint256 collateralFactorMantissa;
        address underlyingAssetAddress;
        uint256 dTokenDecimals;
        uint256 underlyingDecimals;
        uint256 dankSpeed;
        uint256 borrowCap;
    }

    function dTokenMetadata(DToken dToken)
        public
        returns (DTokenMetadata memory)
    {
        uint256 exchangeRateCurrent = dToken.exchangeRateCurrent();
        DanktrollerLensInterface danktroller =
            DanktrollerLensInterface(address(dToken.danktroller()));
        (bool isListed, uint256 collateralFactorMantissa) =
            danktroller.markets(address(dToken));
        address underlyingAssetAddress;
        uint256 underlyingDecimals;

        if (dankareStrings(dToken.symbol(), "dETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            DErc20 dErc20 = DErc20(address(dToken));
            underlyingAssetAddress = dErc20.underlying();
            underlyingDecimals = EIP20Interface(dErc20.underlying()).decimals();
        }

        uint256 dankSpeed = 0;
        (bool dankSpeedSuccess, bytes memory dankSpeedReturnData) =
            address(danktroller).call(
                abi.encodePacked(
                    danktroller.dankSpeeds.selector,
                    abi.encode(address(dToken))
                )
            );
        if (dankSpeedSuccess) {
            dankSpeed = abi.decode(dankSpeedReturnData, (uint256));
        }

        uint256 borrowCap = 0;
        (bool borrowCapSuccess, bytes memory borrowCapReturnData) =
            address(danktroller).call(
                abi.encodePacked(
                    danktroller.borrowCaps.selector,
                    abi.encode(address(dToken))
                )
            );
        if (borrowCapSuccess) {
            borrowCap = abi.decode(borrowCapReturnData, (uint256));
        }

        return
            DTokenMetadata({
                dToken: address(dToken),
                exchangeRateCurrent: exchangeRateCurrent,
                supplyRatePerBlock: dToken.supplyRatePerBlock(),
                borrowRatePerBlock: dToken.borrowRatePerBlock(),
                reserveFactorMantissa: dToken.reserveFactorMantissa(),
                totalBorrows: dToken.totalBorrows(),
                totalReserves: dToken.totalReserves(),
                totalSupply: dToken.totalSupply(),
                totalCash: dToken.getCash(),
                isListed: isListed,
                collateralFactorMantissa: collateralFactorMantissa,
                underlyingAssetAddress: underlyingAssetAddress,
                dTokenDecimals: dToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                dankSpeed: dankSpeed,
                borrowCap: borrowCap
            });
    }

    function dTokenMetadataAll(DToken[] calldata dTokens)
        external
        returns (DTokenMetadata[] memory)
    {
        uint256 dTokenCount = dTokens.length;
        DTokenMetadata[] memory res = new DTokenMetadata[](dTokenCount);
        for (uint256 i = 0; i < dTokenCount; i++) {
            res[i] = dTokenMetadata(dTokens[i]);
        }
        return res;
    }

    struct DTokenBalances {
        address dToken;
        uint256 balanceOf;
        uint256 borrowBalanceCurrent;
        uint256 balanceOfUnderlying;
        uint256 tokenBalance;
        uint256 tokenAllowance;
    }

    function dTokenBalances(DToken dToken, address payable account)
        public
        returns (DTokenBalances memory)
    {
        uint256 balanceOf = dToken.balanceOf(account);
        uint256 borrowBalanceCurrent = dToken.borrowBalanceCurrent(account);
        uint256 balanceOfUnderlying = dToken.balanceOfUnderlying(account);
        uint256 tokenBalance;
        uint256 tokenAllowance;

        if (dankareStrings(dToken.symbol(), "dETH")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            DErc20 dErc20 = DErc20(address(dToken));
            EIP20Interface underlying = EIP20Interface(dErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(dToken));
        }

        return
            DTokenBalances({
                dToken: address(dToken),
                balanceOf: balanceOf,
                borrowBalanceCurrent: borrowBalanceCurrent,
                balanceOfUnderlying: balanceOfUnderlying,
                tokenBalance: tokenBalance,
                tokenAllowance: tokenAllowance
            });
    }

    function dTokenBalancesAll(
        DToken[] calldata dTokens,
        address payable account
    ) external returns (DTokenBalances[] memory) {
        uint256 dTokenCount = dTokens.length;
        DTokenBalances[] memory res = new DTokenBalances[](dTokenCount);
        for (uint256 i = 0; i < dTokenCount; i++) {
            res[i] = dTokenBalances(dTokens[i], account);
        }
        return res;
    }

    struct DTokenUnderlyingPrice {
        address dToken;
        uint256 underlyingPrice;
    }

    function dTokenUnderlyingPrice(DToken dToken)
        public
        returns (DTokenUnderlyingPrice memory)
    {
        DanktrollerLensInterface danktroller =
            DanktrollerLensInterface(address(dToken.danktroller()));
        PriceOracle priceOracle = danktroller.oracle();

        return
            DTokenUnderlyingPrice({
                dToken: address(dToken),
                underlyingPrice: priceOracle.getUnderlyingPrice(dToken)
            });
    }

    function dTokenUnderlyingPriceAll(DToken[] calldata dTokens)
        external
        returns (DTokenUnderlyingPrice[] memory)
    {
        uint256 dTokenCount = dTokens.length;
        DTokenUnderlyingPrice[] memory res =
            new DTokenUnderlyingPrice[](dTokenCount);
        for (uint256 i = 0; i < dTokenCount; i++) {
            res[i] = dTokenUnderlyingPrice(dTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        DToken[] markets;
        uint256 liquidity;
        uint256 shortfall;
    }

    function getAccountLimits(
        DanktrollerLensInterface danktroller,
        address account
    ) public returns (AccountLimits memory) {
        (uint256 errorCode, uint256 liquidity, uint256 shortfall) =
            danktroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return
            AccountLimits({
                markets: danktroller.getAssetsIn(account),
                liquidity: liquidity,
                shortfall: shortfall
            });
    }

    struct GovReceipt {
        uint256 proposalId;
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    function getGovReceipts(
        GovernorAlpha governor,
        address voter,
        uint256[] memory proposalIds
    ) public view returns (GovReceipt[] memory) {
        uint256 proposalCount = proposalIds.length;
        GovReceipt[] memory res = new GovReceipt[](proposalCount);
        for (uint256 i = 0; i < proposalCount; i++) {
            GovernorAlpha.Receipt memory receipt =
                governor.getReceipt(proposalIds[i], voter);
            res[i] = GovReceipt({
                proposalId: proposalIds[i],
                hasVoted: receipt.hasVoted,
                support: receipt.support,
                votes: receipt.votes
            });
        }
        return res;
    }

    struct GovBravoReceipt {
        uint256 proposalId;
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }

    function getGovBravoReceipts(
        GovernorBravoInterface governor,
        address voter,
        uint256[] memory proposalIds
    ) public view returns (GovBravoReceipt[] memory) {
        uint256 proposalCount = proposalIds.length;
        GovBravoReceipt[] memory res = new GovBravoReceipt[](proposalCount);
        for (uint256 i = 0; i < proposalCount; i++) {
            GovernorBravoInterface.Receipt memory receipt =
                governor.getReceipt(proposalIds[i], voter);
            res[i] = GovBravoReceipt({
                proposalId: proposalIds[i],
                hasVoted: receipt.hasVoted,
                support: receipt.support,
                votes: receipt.votes
            });
        }
        return res;
    }

    struct GovProposal {
        uint256 proposalId;
        address proposer;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool canceled;
        bool executed;
    }

    function setProposal(
        GovProposal memory res,
        GovernorAlpha governor,
        uint256 proposalId
    ) internal view {
        (
            ,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            bool canceled,
            bool executed
        ) = governor.proposals(proposalId);
        res.proposalId = proposalId;
        res.proposer = proposer;
        res.eta = eta;
        res.startBlock = startBlock;
        res.endBlock = endBlock;
        res.forVotes = forVotes;
        res.againstVotes = againstVotes;
        res.canceled = canceled;
        res.executed = executed;
    }

    function getGovProposals(
        GovernorAlpha governor,
        uint256[] calldata proposalIds
    ) external view returns (GovProposal[] memory) {
        GovProposal[] memory res = new GovProposal[](proposalIds.length);
        for (uint256 i = 0; i < proposalIds.length; i++) {
            (
                address[] memory targets,
                uint256[] memory values,
                string[] memory signatures,
                bytes[] memory calldatas
            ) = governor.getActions(proposalIds[i]);
            res[i] = GovProposal({
                proposalId: 0,
                proposer: address(0),
                eta: 0,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                startBlock: 0,
                endBlock: 0,
                forVotes: 0,
                againstVotes: 0,
                canceled: false,
                executed: false
            });
            setProposal(res[i], governor, proposalIds[i]);
        }
        return res;
    }

    struct GovBravoProposal {
        uint256 proposalId;
        address proposer;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
    }

    function setBravoProposal(
        GovBravoProposal memory res,
        GovernorBravoInterface governor,
        uint256 proposalId
    ) internal view {
        GovernorBravoInterface.Proposal memory p =
            governor.proposals(proposalId);

        res.proposalId = proposalId;
        res.proposer = p.proposer;
        res.eta = p.eta;
        res.startBlock = p.startBlock;
        res.endBlock = p.endBlock;
        res.forVotes = p.forVotes;
        res.againstVotes = p.againstVotes;
        res.abstainVotes = p.abstainVotes;
        res.canceled = p.canceled;
        res.executed = p.executed;
    }

    function getGovBravoProposals(
        GovernorBravoInterface governor,
        uint256[] calldata proposalIds
    ) external view returns (GovBravoProposal[] memory) {
        GovBravoProposal[] memory res =
            new GovBravoProposal[](proposalIds.length);
        for (uint256 i = 0; i < proposalIds.length; i++) {
            (
                address[] memory targets,
                uint256[] memory values,
                string[] memory signatures,
                bytes[] memory calldatas
            ) = governor.getActions(proposalIds[i]);
            res[i] = GovBravoProposal({
                proposalId: 0,
                proposer: address(0),
                eta: 0,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                startBlock: 0,
                endBlock: 0,
                forVotes: 0,
                againstVotes: 0,
                abstainVotes: 0,
                canceled: false,
                executed: false
            });
            setBravoProposal(res[i], governor, proposalIds[i]);
        }
        return res;
    }

    struct DankBalanceMetadata {
        uint256 balance;
        uint256 votes;
        address delegate;
    }

    function getDankBalanceMetadata(Dank dank, address account)
        external
        view
        returns (DankBalanceMetadata memory)
    {
        return
            DankBalanceMetadata({
                balance: dank.balanceOf(account),
                votes: uint256(dank.getCurrentVotes(account)),
                delegate: dank.delegates(account)
            });
    }

    struct DankBalanceMetadataExt {
        uint256 balance;
        uint256 votes;
        address delegate;
        uint256 allocated;
    }

    struct DankBalanceMetadataExtL2 {
        uint256 balance;
        uint256 allocated;
    }

    function getDankBalanceMetadataExt(
        Dank dank,
        DanktrollerLensInterface danktroller,
        address account
    ) external returns (DankBalanceMetadataExt memory) {
        uint256 balance = dank.balanceOf(account);
        danktroller.claimDank(account);
        uint256 newBalance = dank.balanceOf(account);
        uint256 accrued = danktroller.dankAccrued(account);
        uint256 total = add(accrued, newBalance, "sum dank total");
        uint256 allocated = sub(total, balance, "sub allocated");

        return
            DankBalanceMetadataExt({
                balance: balance,
                votes: uint256(dank.getCurrentVotes(account)),
                delegate: dank.delegates(account),
                allocated: allocated
            });
    }

    function getDankBalanceMetadataExtL2(
        Dank dank,
        DanktrollerLensInterface danktroller,
        address account
    ) external returns (DankBalanceMetadataExtL2 memory) {
        uint256 balance = dank.balanceOf(account);
        danktroller.claimDank(account);
        uint256 newBalance = dank.balanceOf(account);
        uint256 accrued = danktroller.dankAccrued(account);
        uint256 total = add(accrued, newBalance, "sum dank total");
        uint256 allocated = sub(total, balance, "sub allocated");

        return
            DankBalanceMetadataExtL2({balance: balance, allocated: allocated});
    }

    struct DankVotes {
        uint256 blockNumber;
        uint256 votes;
    }

    function getDankVotes(
        Dank dank,
        address account,
        uint32[] calldata blockNumbers
    ) external view returns (DankVotes[] memory) {
        DankVotes[] memory res = new DankVotes[](blockNumbers.length);
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            res[i] = DankVotes({
                blockNumber: uint256(blockNumbers[i]),
                votes: uint256(dank.getPriorVotes(account, blockNumbers[i]))
            });
        }
        return res;
    }

    function dankareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}
