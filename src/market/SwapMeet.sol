// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/ISwapMeet.sol";

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";

import "../interfaces/INFTComplexGemPoolData.sol";

import "../interfaces/INFTGemFeeManager.sol";

import "../libs/UInt256Set.sol";

import "hardhat/console.sol";

contract SwapMeet is ISwapMeet, Controllable {
    using UInt256Set for UInt256Set.Set;

    uint256 public constant listingFeeHash =
        uint256(keccak256("swapMeetListingFee"));
    uint256 public constant acceptFeeHash =
        uint256(keccak256("swapMeetAcceptFee"));
    uint256 public constant acceptVariableFeeHash =
        uint256(keccak256("swapMeetAcceptVariableFee"));

    bool internal open;

    INFTGemFeeManager internal feeManager;
    INFTGemMultiToken internal multitoken;

    // all the offers in this contract
    mapping(uint256 => Offer) internal offers;

    // all the offer but by owner
    mapping(address => Offer[]) internal offersByOwner;

    UInt256Set.Set internal offerIds;

    // proxy mapping manages alloewances w/o owner
    mapping(address => address) internal proxyList;

    constructor(address _multitoken, address _feeManager) {
        _addController(msg.sender);
        multitoken = INFTGemMultiToken(_multitoken);
        feeManager = INFTGemFeeManager(_feeManager);
        open = true;
    }

    // register a new offer
    function registerOffer(
        // what to have to swap
        address _pool,
        uint256 _gem,
        uint256 _quantity,
        // what you are willing to swap it for
        address[] calldata _pools,
        uint256[] calldata _gems,
        uint256[] calldata _quantities,
        uint256 references
    )
        external
        payable
        override
        returns (uint256 _offerId, Offer memory _offer)
    {
        require(open, "swap meet closed");

        // get the listing fee - the service is a flat fee
        uint256 listingFee = INFTGemFeeManager(feeManager).fee(listingFeeHash);
        listingFee = listingFee == 0 ? 0.5 ether : listingFee;

        // an offer is offerer address plus gem hash
        _offerId = uint256(keccak256(abi.encodePacked(msg.sender, _gem)));

        // basic sanity checks
        require(!offerIds.exists(_offerId), "gem already registered");
        require(_gems.length == _pools.length, "mismatched gem quantities");
        require(msg.value >= listingFee, "insufficient listing fee");
        require(_quantity > 0, "invalid quantity");

        // make sure they own the gem they wanna trade
        require(
            IERC1155(address(multitoken)).balanceOf(msg.sender, _gem) >=
                _quantity,
            "insufficient gem balance"
        );

        // make sure the gem is of the specified pool
        INFTGemMultiToken.TokenType tt = INFTComplexGemPoolData(_pool)
            .tokenType(_gem);

        // require that the gem be from this pool
        require(tt == INFTGemMultiToken.TokenType.GEM, "invalid token type");

        // validate the input gems list
        require(
            _validateInputGems(_pools, _gems, _quantities),
            "invalid input"
        );

        // create the offer
        offers[_offerId] = Offer(
            _offerId,
            msg.sender,
            _pool,
            _gem,
            _quantity,
            _pools,
            _gems,
            _quantities,
            listingFee,
            0,
            references,
            false
        );

        // add the offer to the offers mapping
        offerIds.insert(_offerId);
        offersByOwner[msg.sender].push(offers[_offerId]);

        // return offer
        _offer = offers[_offerId];

        _emitOffer(_offerId);
    }

    function _emitOffer(uint256 _offerId) internal {
        Offer memory offer = offers[_offerId];
        // emit the event
        emit OfferRegistered(
            offer.owner,
            _offerId,
            offer.pool,
            offer.gem,
            offer.quantity,
            offer.pools,
            offer.gems,
            offer.quantities,
            offer.references
        );
    }

    function _validateInputGems(
        address[] memory _pools,
        uint256[] memory _gems,
        uint256[] memory _quantities
    ) internal view returns (bool) {
        // make sure the pool addresses are valid and that
        // the token quantities are all valid
        for (uint256 i = 0; i < _quantities.length; i++) {
            // if no gems and no quantities, then it is a
            // gem to FTM swap and the quantity is the FTM amount
            // that the ggem is on sale for
            if (_gems.length == 0 && _pools.length == 0) {} else if (
                _gems[i] == 0
            ) {
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
        return true;
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
        // this is capitalism - so figure out our fee first
        uint256 acceptFee = INFTGemFeeManager(feeManager).fee(acceptFeeHash);
        acceptFee = acceptFee == 0 ? 0.5 ether : acceptFee;

        // check that the offer is valid
        require(offerIds.exists(_id), "offer not registered");
        require(msg.value >= acceptFee, "insufficient accept fee");

        // how many input pools' rquirements are met. Length of this must equal length of input pools
        uint256 foundInputPools = 0;

        // iterate through all incoming gems to account for them
        for (uint256 gemIndex = 0; gemIndex < _gems.length; gemIndex++) {
            //
            // we'll need to track the required quantity of each gem
            uint256 requiredQuantity = 0;
            uint256 theIncomingGem = _gems[gemIndex]; // the incoming gem we are validating
            uint256 foundBalance = 0;
            address thePool;

            // iterate through all input pool requirements for this offer
            for (
                uint256 poolIndex = 0;
                poolIndex < offers[_id].pools.length;
                poolIndex++
            ) {
                uint256 theGemRequirement = offers[_id].gems[poolIndex]; // the gem requirement for the above pool (or 0 if any gem)

                // determine if the gem we are validating is a member of this pool
                INFTGemMultiToken.TokenType tokenType = INFTComplexGemPoolData(
                    offers[_id].pools[poolIndex]
                ).tokenType(_gems[gemIndex]);

                // if it is then get the message senders balance of the gem
                // and add it to the balance we are tracking
                if (tokenType == INFTGemMultiToken.TokenType.GEM) {
                    //
                    // the gem pool from the offer
                    thePool = offers[_id].pools[poolIndex];

                    // if we have no balance yet its the first time we have seen the pool
                    // so increment the total count of input pools we have seen
                    if (foundBalance == 0) {
                        foundInputPools++;
                    }

                    // incement the pool gem balance
                    foundBalance += IERC1155(address(multitoken)).balanceOf(
                        msg.sender,
                        _gems[gemIndex]
                    );

                    // if the requirement is specific (not 'any') then this is the
                    // place to check if the gem the pool requires is the gem we are checking
                    if (theGemRequirement != 0) {
                        require(
                            theGemRequirement == theIncomingGem,
                            "gem mismatch"
                        );
                    }

                    // grab required quantity so we can see if we have enough
                    requiredQuantity = offers[_id].quantities[poolIndex];
                }
            }

            // if the balance is less than the required quantity then reject
            require(
                thePool != address(0) && foundBalance >= requiredQuantity,
                "Insufficient gem balance"
            );
            thePool = address(0);
        }
        // this tell us if this is is a gem to fantom swap
        bool isTokenSwap = (offers[_id].pools.length == 0 &&
            offers[_id].gems.length == 0 &&
            offers[_id].quantities.length == 1);

        // if this is not a gem to ftm swap
        if (!isTokenSwap) {
            // require that the number of pools we have seen is equal to the number of input pools
            require(
                offers[_id].pools.length == foundInputPools,
                "conditions unsatisfied"
            );
        }

        // check that the offer owner has the token to swap
        // and penalize them if they do mot have it.
        if (
            IERC1155(address(multitoken)).balanceOf(
                offers[_id].owner,
                offers[_id].gem
            ) < offers[_id].quantity
        ) {
            // penalize the owner for not having the token
            offers[_id].missingTokenPenalty = true;
            success = false;

            // refund the accepter all tokens
            // they sent for fees or to pay for gem
            require(payable(msg.sender).send(msg.value), "refund failed");
            return success;
        }

        console.log("acceptOffer: sender balance good");

        // if this is a gem to ftm swap
        if (isTokenSwap) {
            // fee is permillion - unite per million
            acceptFee = INFTGemFeeManager(feeManager).fee(
                acceptVariableFeeHash
            );
            acceptFee = acceptFee == 0 ? 3000 : acceptFee; // 1000 permillion is 0.1%

            // closing fee is x permillion of the cost of the swap
            acceptFee = (offers[_id].quantities[0] / 1000000) * acceptFee;
            require(
                msg.value >= offers[_id].quantities[0],
                "insufficient swap amount"
            );
        }

        address offerPool = offers[_id].pool;
        uint256 offerHash = offers[_id].gem;

        //if this is a gem to token swap, send the FTM minus fee to seller
        if (isTokenSwap) {
            require(
                payable(offers[_id].owner).send(
                    offers[_id].quantities[0] - acceptFee
                ),
                "swap failed"
            );
        } else {
            // swap the gems
            proxyList[msg.sender] = address(this);
            IERC1155(address(multitoken)).safeBatchTransferFrom(
                msg.sender,
                offers[_id].owner,
                _gems,
                offers[_id].quantities,
                ""
            );
            delete proxyList[msg.sender];
        }

        console.log("acceptOffer: transfer batch");

        // swap the gem
        proxyList[offers[_id].owner] = address(this);
        IERC1155(address(multitoken)).safeTransferFrom(
            offers[_id].owner,
            msg.sender,
            offers[_id].gem,
            offers[_id].quantity,
            ""
        );
        delete proxyList[offers[_id].owner];

        console.log("acceptOffer: transfer gem");

        // remove the offer
        offerIds.remove(_id);
        delete offers[_id];

        emit OfferAccepted(
            _id,
            offerPool,
            offerHash,
            msg.sender,
            _gems,
            acceptFee
        );

        return true;
    }

    // withdraw accrued fees
    function withdrawFees(address _receiver) external override onlyController {
        require(payable(address(this)).balance > 0, "no fees to withdraw");
        uint256 theBalance = payable(address(this)).balance;
        payable(_receiver).transfer(theBalance);
        emit SwapMeetFeesWithdrawn(_receiver, theBalance);
    }

    // set open state
    function setOpenState(bool openState) external override onlyController {
        open = openState;
        emit SwapMeetIsOpen(open);
    }

    // is the swap open
    function isOpen() external view override returns (bool) {
        return open;
    }

    // called by the multitoken when a swap is performed by the
    // swap meet - we temporarily set the operator of the token
    // via this proxy function, which is called from isApproved()
    function proxies(address input) external view returns (address) {
        return proxyList[input];
    }
}
