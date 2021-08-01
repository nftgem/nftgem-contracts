// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapMeet {
    // an offer is registered with the swap
    event OfferRegistered(
        address _from,
        uint256 _offerId,
        address _pool,
        uint256 _gem,
        address[] _pools,
        uint256[] _gems,
        uint256 _references
    );

    // an offer is cancelled
    event OfferUnregistered(uint256 _offerId);

    // an offer is aacepted
    event OfferAccepted(uint256 _offerId, address _acceptor, uint256[] _gems);

    // registe a new offer
    function registerOffer(
        // what to have to swap
        address _pool,
        uint256 _gem,
        // what you are willing to swap it for
        address[] memory _pools,
        uint256[] memory _gems,
        bool acceptCounterOffers,
        uint256 _references
    ) external payable returns (uint256 _id);

    // unregister an offer
    function unregisterOffer(uint256 _id) external returns (bool success);

    // is an active offer
    function isOffer(uint256 _id) external view returns (bool success);

    // list all offers
    function listOffers() external view returns (uint256[] memory _ids);

    // get details of an offer
    function getOfferDetails(uint256 _id)
        external
        view
        returns (
            address _owner,
            address _pool,
            uint256 _gem,
            address[] memory _pools,
            uint256[] memory _gems
        );

    // accept an offer
    function acceptOffer(uint256 _id, uint256[] memory _gems)
        external
        payable
        returns (bool success);

    function withdrawFees(address _receiver) external;

    function updateListingFee(uint256 _fee) external;

    function updateAcceptFee(uint256 _fee) external;
}
