// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/ISwapMeet.sol";

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";

import "../interfaces/INFTComplexGemPoolData.sol";

import "../libs/UInt256Set.sol";

contract SwapMeet is ISwapMeet, Controllable {
    uint256 private feesBalance;

    uint256 private listingFee;
    uint256 private acceptFee;

    INFTGemMultiToken private multitoken;
    using UInt256Set for UInt256Set.Set;

    mapping(uint256 => Offer) private offers;
    mapping(address => Offer[]) private offersByOwner;

    UInt256Set.Set private offerIds;

    constructor(address _multitoken) {
        _addController(msg.sender);
        multitoken = INFTGemMultiToken(_multitoken);
        listingFee = 1 ether;
        acceptFee = 1 ether;
    }

    // register a new offer
    function registerOffer(
        // what to have to swap
        address _pool,
        uint256 _gem,
        // what you are willing to swap it for
        address[] memory _pools,
        uint256[] memory _gems,
        uint256 references
    ) external payable override returns (uint256 _id) {
        require(!offerIds.exists(_gem), "gem already registered");
        require(_gems.length <= _pools.length, "too many gems");
        require(msg.value >= listingFee, "insufficient listing fee");
        // make sure they own the gem they wanna trade
        require(
            IERC1155(address(multitoken)).balanceOf(msg.sender, _gem) == 1,
            "insufficient gem balance"
        );

        // make sure the gem is of the specified pool
        INFTGemMultiToken.TokenType tt = INFTComplexGemPoolData(_pool)
            .tokenType(_gem);
        // require that the gem be from this pool
        require(tt == INFTGemMultiToken.TokenType.GEM, "invalid token type");

        // require that the message sender have enough tokens
        require(
            IERC1155(address(multitoken)).balanceOf(msg.sender, _gem) >= 1,
            "insufficient gem balance"
        );

        // create the offer
        Offer memory offer = Offer(
            msg.sender,
            _pool,
            _gem,
            _pools,
            _gems,
            listingFee,
            references,
            false
        );

        // add the offer to the offers mapping
        offers[_gem] = offer;
        offerIds.insert(_gem);
        offersByOwner[msg.sender].push(offer);

        // return offer id
        _id = _gem;

        // emit the event
        emit OfferRegistered(
            msg.sender,
            _id,
            _pool,
            _gem,
            _pools,
            _gems,
            references
        );
    }

    // unregister an offer
    function unregisterOffer(uint256 _id)
        external
        override
        returns (bool success)
    {
        // ensure caller is the owner of the offer
        require(msg.sender == offers[_id].owner, "not owner");

        // ensure the offer is registered
        require(offerIds.exists(_id), "offer not registered");

        // get the listing fee of the offer
        uint256 _listingFee = offers[_id].listingFee;

        // find out if they are penalized for missing tokens
        bool penalty = offers[_id].missingTokenPenalty;

        // remove offer from offers mapping
        offerIds.remove(_id);
        delete offers[_id];

        // remove offer from owner's offers mapping
        for (
            uint256 offerIndex = 0;
            offerIndex < offersByOwner[msg.sender].length;
            ++offerIndex
        ) {
            if (offersByOwner[msg.sender][offerIndex].gem == _id) {
                offersByOwner[msg.sender][offerIndex] = offersByOwner[
                    msg.sender
                ][offersByOwner[msg.sender].length - 1];
                offersByOwner[msg.sender].pop();
            }
        }

        // give them their fees back if they arent penalized
        if (!penalty) {
            // refund listing fee to the owner
            payable(msg.sender).transfer(_listingFee);
        }

        // emit the unregistered event
        emit OfferUnregistered(_id);

        return true;
    }

    // is an active offer
    function isOffer(uint256 _id)
        external
        view
        override
        returns (bool success)
    {
        return offerIds.exists(_id);
    }

    // list all offers
    function listOffers()
        external
        view
        override
        returns (uint256[] memory _ids)
    {
        _ids = offerIds.keyList;
    }

    // list all offers
    function listOffersByOwner(address ownerAddress)
        external
        view
        override
        returns (Offer[] memory _ids)
    {
        _ids = offersByOwner[ownerAddress];
    }

    // get details of an offer
    function getOfferDetails(uint256 _id)
        external
        view
        override
        returns (
            address _owner,
            address _pool,
            uint256 _gem,
            address[] memory _pools,
            uint256[] memory _gems,
            uint256 _references
        )
    {
        require(offerIds.exists(_id), "offer not registered");
        Offer memory offer = offers[_id];
        _owner = offer.owner;
        _pool = offer.pool;
        _gem = offer.gem;
        _pools = offer.pools;
        _gems = offer.gems;
        _references = offer.references;
    }

    // accept an offer
    function acceptOffer(uint256 _id, uint256[] memory _gems)
        external
        payable
        override
        returns (bool success)
    {
        // check that the offer is valid
        require(offerIds.exists(_id), "offer not registered");
        require(_gems.length <= offers[_id].gems.length, "too many gems");
        require(msg.value >= acceptFee, "insufficient accept fee");

        // get the offer
        Offer memory offer = offers[_id];

        uint256[] memory gemQUantities = new uint256[](_gems.length);
        // iterate over the gem pools and swap the gems
        for (uint256 i = 0; i < offer.pools.length; i++) {
            address pool = offer.pools[i]; // get the pool
            // get the gem or 0 for any gem in pool
            uint256 gem = offer.gems.length > i ? offer.gems[i] : 0;
            if (gem == 0) {
                gem = _gems[i]; // if any gem get the one passed in
            } else {
                _gems[i] = gem;
            }
            // require sender owns the gem
            require(
                IERC1155(address(multitoken)).balanceOf(msg.sender, gem) >= 1,
                "insufficient gem balance"
            );
            // get the token type of gem for pool
            INFTGemMultiToken.TokenType tt = INFTComplexGemPoolData(pool)
                .tokenType(gem);
            // require that the gem be from this pool
            require(
                tt == INFTGemMultiToken.TokenType.GEM,
                "invalid token type"
            );
            gemQUantities[i] = 1;
        }

        // check that the offer owner has the token to swap
        // and penalize them if they do mot have it.
        if (
            IERC1155(address(multitoken)).balanceOf(offer.owner, offer.gem) == 0
        ) {
            // penalize the owner for not having the token
            offer.missingTokenPenalty = true;
            success = false;
            // refund the accepter
            payable(msg.sender).transfer(acceptFee);
            return success;
        }

        // swap the gems
        IERC1155(address(multitoken)).safeBatchTransferFrom(
            msg.sender,
            offer.owner,
            _gems,
            gemQUantities,
            ""
        );

        // swap the gem
        IERC1155(address(multitoken)).safeTransferFrom(
            offer.owner,
            msg.sender,
            offer.gem,
            1,
            ""
        );

        // remove the offer
        offerIds.remove(_id);
        delete offers[_id];

        feesBalance += acceptFee + listingFee;

        emit OfferAccepted(_id, msg.sender, _gems);

        return true;
    }

    function withdrawFees(address _receiver) external override onlyController {
        require(feesBalance > 0, "no fees to withdraw");
        uint256 balanceToWithdraw = feesBalance;
        feesBalance = 0;
        payable(_receiver).transfer(balanceToWithdraw);
    }

    function updateListingFee(uint256 _fee) external override onlyController {
        listingFee = _fee;
    }

    function updateAcceptFee(uint256 _fee) external override onlyController {
        acceptFee = _fee;
    }

    function proxies(address input) external pure returns (address) {
        return input;
    }
}
