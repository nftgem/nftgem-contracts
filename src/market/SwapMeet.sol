// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/ISwapMeet.sol";

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";

import "../interfaces/INFTComplexGemPoolData.sol";

import "../interfaces/INFTGemFeeManager.sol";

import "../libs/UInt256Set.sol";

contract SwapMeet is ISwapMeet, Controllable {
    uint256 private feesBalance;

    INFTGemFeeManager private feeManager;
    INFTGemMultiToken private multitoken;

    uint256 public constant listingFeeHash =
        uint256(keccak256("swapMeetListingFee"));
    uint256 public constant acceptFeeHash =
        uint256(keccak256("swapMeetAcceptFee"));

    using UInt256Set for UInt256Set.Set;

    mapping(uint256 => Offer) private offers;

    mapping(address => Offer[]) private offersByOwner;

    UInt256Set.Set private offerIds;

    constructor(address _multitoken, address _feeManager) {
        _addController(msg.sender);
        multitoken = INFTGemMultiToken(_multitoken);
        feeManager = INFTGemFeeManager(_feeManager);
    }

    // register a new offer
    function registerOffer(
        // what to have to swap
        address _pool,
        uint256 _gem,
        // what you are willing to swap it for
        address[] calldata _pools,
        uint256[] calldata _gems,
        uint256[] calldata _quantities,
        uint256 references
    ) external payable override returns (Offer memory _offer) {
        // get the listing fee - the service is a flat fee
        uint256 listingFee = INFTGemFeeManager(feeManager).fee(listingFeeHash);
        listingFee = listingFee == 0 ? 0.01 ether : listingFee;

        // basic sanity checks
        require(!offerIds.exists(_gem), "gem already registered");
        require(_gems.length == _pools.length, "mismatched gem quantities");
        require(msg.value >= listingFee, "insufficient listing fee");

        // make sure they own the gem they wanna trade
        require(
            IERC1155(address(multitoken)).balanceOf(msg.sender, _gem) > 0,
            "insufficient gem balance"
        );

        // make sure the gem is of the specified pool
        INFTGemMultiToken.TokenType tt = INFTComplexGemPoolData(_pool)
            .tokenType(_gem);

        // require that the gem be from this pool
        require(tt == INFTGemMultiToken.TokenType.GEM, "invalid token type");

        // make sure the pool addresses are valid and that
        // the token quantities are all valid
        for (uint256 i = 0; i < _quantities.length; i++) {
            if (_gems[i] == 0) {
                // if any gem, then check to see that this pool is valid
                try INFTComplexGemPoolData(_pools[i]).symbol() returns (
                    string memory _symbol
                ) {
                    require(bytes(_symbol).length > 0, "invalid pool");
                } catch {
                    require(false, "invalid pool");
                }
            } else {
                // if a specific gem, then check to make sure the gem is from this pool
                try
                    INFTComplexGemPoolData(_pools[i]).tokenType(_gems[i])
                returns (INFTGemMultiToken.TokenType _tokenType) {
                    require(
                        _tokenType == INFTGemMultiToken.TokenType.GEM,
                        "not a gem from this pool"
                    );
                } catch {
                    require(false, "invalid pool");
                }
            }

            require(_quantities[i] > 0, "invalid token quantity");
        }

        // create the offer
        offers[_gem] = Offer(
            msg.sender,
            _pool,
            _gem,
            _pools,
            _gems,
            _quantities,
            listingFee,
            0,
            references,
            false
        );

        // add the offer to the offers mapping
        offerIds.insert(_gem);
        offersByOwner[msg.sender].push(offers[_gem]);

        // return offer
        _offer = offers[_gem];

        // emit the event
        emit OfferRegistered(
            msg.sender,
            _gem,
            _pool,
            _gem,
            _pools,
            _gems,
            _quantities,
            references,
            listingFee
        );
    }

    // unregister an offer
    function unregisterOffer(uint256 _id)
        external
        override
        returns (bool success)
    {
        // // ensure the offer is registered
        require(offerIds.exists(_id) == true, "offer not registered");

        // ensure the offer is the message sender
        require(offers[_id].owner == msg.sender, "caller not owner");

        // get the listing fee of the offer
        uint256 _listingFee = offers[_id].listingFee;

        // find out if they are penalized for missing tokens
        bool penalty = offers[_id].missingTokenPenalty;

        // get the offer owner
        address offerOwner = offers[_id].owner;

        // remove offer from offers mapping
        offerIds.remove(_id);
        delete offers[_id];

        // remove offer from owner's offers mapping
        for (
            uint256 offerIndex = 0;
            offerIndex < offersByOwner[offerOwner].length;
            ++offerIndex
        ) {
            if (offersByOwner[offerOwner][offerIndex].gem == _id) {
                offersByOwner[offerOwner][offerIndex] = offersByOwner[
                    offerOwner
                ][offersByOwner[offerOwner].length - 1];
                offersByOwner[offerOwner].pop();
            }
        }

        // give them their fees back if they arent penalized
        if (!penalty) {
            // refund listing fee to the owner
            payable(offerOwner).transfer(_listingFee);
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
        returns (Offer[] memory offersOut)
    {
        offersOut = new Offer[](offerIds.keyList.length);
        for (
            uint256 offerIndex = 0;
            offerIndex < offerIds.keyList.length;
            ++offerIndex
        ) {
            offersOut[offerIndex] = offers[offerIds.keyList[offerIndex]];
        }
    }

    // list all offer ids
    function listOfferIds()
        external
        view
        override
        returns (uint256[] memory _offerIds)
    {
        _offerIds = offerIds.keyList;
    }

    // list all offers by owner
    function listOffersByOwner(address ownerAddress)
        external
        view
        override
        returns (Offer[] memory _ids)
    {
        _ids = offersByOwner[ownerAddress];
    }

    // get details of an offer
    function getOffer(uint256 _id)
        external
        view
        override
        returns (Offer memory)
    {
        require(offerIds.exists(_id), "offer not registered");
        return offers[_id];
    }

    // accept an offer
    function acceptOffer(uint256 _id, uint256[] memory _gems)
        external
        payable
        override
        returns (bool success)
    {
        uint256 acceptFee = INFTGemFeeManager(feeManager).fee(acceptFeeHash);
        acceptFee = acceptFee == 0 ? 0.01 ether : acceptFee;

        // check that the offer is valid
        require(offerIds.exists(_id), "offer not registered");
        require(_gems.length <= offers[_id].gems.length, "too many gems");
        require(msg.value >= acceptFee, "insufficient accept fee");

        // iterate over the gem pools and swap the gems
        for (uint256 i = 0; i < offers[_id].pools.length; i++) {
            address pool = offers[_id].pools[i]; // get the pool
            // get the gem or 0 for any gem in pool
            uint256 gem = offers[_id].gems.length > i ? offers[_id].gems[i] : 0;
            if (gem == 0) {
                gem = _gems[i]; // if any gem get the one passed in
            } else {
                _gems[i] = gem;
            }
            // require sender owns the gem
            require(
                IERC1155(address(multitoken)).balanceOf(msg.sender, gem) >=
                    offers[_id].quantities[i],
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
        }

        // check that the offer owner has the token to swap
        // and penalize them if they do mot have it.
        if (
            IERC1155(address(multitoken)).balanceOf(
                offers[_id].owner,
                offers[_id].gem
            ) == 0
        ) {
            // penalize the owner for not having the token
            offers[_id].missingTokenPenalty = true;
            success = false;
            // refund the accepter
            payable(msg.sender).transfer(acceptFee);
            return success;
        }

        // add the fees to our withdrawable balance
        feesBalance += acceptFee + offers[_id].listingFee;

        // swap the gems
        IERC1155(address(multitoken)).safeBatchTransferFrom(
            msg.sender,
            offers[_id].owner,
            _gems,
            offers[_id].quantities,
            ""
        );

        // swap the gem
        IERC1155(address(multitoken)).safeTransferFrom(
            offers[_id].owner,
            msg.sender,
            offers[_id].gem,
            1,
            ""
        );

        // remove the offer
        offerIds.remove(_id);
        delete offers[_id];

        emit OfferAccepted(_id, msg.sender, _gems, acceptFee);

        return true;
    }

    // withdraw accrued fees
    function withdrawFees(address _receiver) external override onlyController {
        require(feesBalance > 0, "no fees to withdraw");
        uint256 balanceToWithdraw = feesBalance;
        feesBalance = 0;
        payable(_receiver).transfer(balanceToWithdraw);
        emit SwapMeetFeesWithdrawn(_receiver, balanceToWithdraw);
    }

    function proxies(address input) external pure returns (address) {
        return input;
    }
}
