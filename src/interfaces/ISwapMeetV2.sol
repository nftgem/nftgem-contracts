// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/UInt256Set.sol";

interface ISwapMeetV2 {
    struct Bid {
        uint256 offerId;
        address bidder;
        uint256 amount;
    }

    // an offer to swap a gem for some number of other gems
    struct Offer {
        address owner;
        address pool;
        uint256 gem;
        address[] pools;
        uint256[] gems;
        uint256[] quantities;
        uint256 listingFee;
        uint256 acceptFee;
        uint256 references;
        bool missingTokenPenalty;
        uint256 blockCount;
        bool wethOnly;
        bool collectPayment;
        address winner;
        uint256 winningBidAmount;
    }

    // an offer is registered with the swap
    event OfferRegistered(
        address _from,
        uint256 _offerId,
        address _pool,
        uint256 _gem,
        address[] _pools,
        uint256[] _gems,
        uint256[] _quantities,
        uint256 _references,
        uint256 _listingFee,
        uint256 _blockCount
    );

    // an offer is cancelled
    event OfferUnregistered(uint256 _offerId);

    // an offer is aacepted
    event OfferAccepted(
        uint256 _offerId,
        address _offerPool,
        uint256 _offerItem,
        address _acceptor,
        uint256[] _gems,
        uint256 _acceptFee
    );

    // bid is created
    event BidCreated(uint256 _itemId, address _bidder, uint256 _amount);

    // bid is created
    event AuctionClosed(
        uint256 _itemId,
        address _winner,
        uint256 _amount,
        uint256 _blockClosed
    );

    // bid is created
    event AuctionCompleted(
        uint256 _itemId,
        address _winner,
        uint256 _amount,
        uint256 _blockClosed
    );

    // an offer is cancelled
    event SwapMeetFeesWithdrawn(address _recipient, uint256 _feesAmount);

    // when the meet is opened and closed. closed means
    // the meet is no longer accepting offers
    event SwapMeetIsOpen(bool openState);

    // registe a new offer
    function registerOffer(
        // what to have to swap
        address _pool,
        uint256 _gem,
        // what you are willing to swap it for
        address[] calldata _pools,
        uint256[] calldata _gems,
        uint256[] calldata _quantities,
        uint256 references,
        uint256 _blockCount,
        bool _wethOnly
    ) external payable returns (uint256 _offerId, Offer memory _offer);

    // unregister an offer
    function unregisterOffer(uint256 _id) external returns (bool);

    // is an active offer
    function isOffer(uint256 _id) external view returns (bool);

    // list all offers
    function listOffers() external view returns (Offer[] memory);

    // list all offer ids
    function listOfferIds() external view returns (uint256[] memory);

    // list all offers
    function listOffersByOwner(address ownerAddress)
        external
        view
        returns (Offer[] memory);

    // get details of an offer
    function getOffer(uint256 _id) external view returns (Offer memory);

    // get bids of an offer
    function getOfferBids(uint256 _id) external view returns (Bid[] memory);

    // create a bid
    function createBid(
        uint256 _id,
        uint256 _amount,
        bool useWeth
    ) external payable returns (bool);

    // accept an offer
    function acceptOffer(uint256 _id, uint256[] memory)
        external
        payable
        returns (bool);

    // withdraw the swap meet fees
    function withdrawFees(address _receiver) external;

    // set the open state of the swap
    function setOpenState(bool openState) external;

    // is the swap open
    function isOpen() external view returns (bool);

    // is the swap offer an auction?
    function isAuction(uint256 _id) external view returns (bool);

    // set the open state of the swap
    function closeAuction(uint256 _id) external returns (bool);

    function completeAuction(uint256 _id) external payable returns (bool);

    // nigrate the swap meet to another version
    // function migrate(address _newSwap) external;

    // function initialize(
    //     bool _open,
    //     address _feeManager,
    //     address _multitoken,
    //     mapping(uint256 => Offer) memory _offers,
    //     mapping(address => Offer[]) memory _offersByOwner,
    //     UInt256Set.Set memory _offerIds,
    //     mapping(address => address) memory _proxyList
    // ) external;
}