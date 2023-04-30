// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import {Slots} from "./SlotManipulate.sol";
import {BasicProxy} from "./BasicProxy.sol";

contract Transparent is Slots, BasicProxy {
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    constructor(address _implementation) BasicProxy(_implementation) {
        // TODO: set admin address to Admin slot
        _setSlotToAddress(ADMIN_SLOT, msg.sender);
    }

    modifier onlyAdmin() {
        if (msg.sender == _getSlotToAddress(ADMIN_SLOT)) {
            // only admin can call proxy's function
            _;
        } else {
            _fallback(); // others will call fallback function
        }
    }

    function upgradeTo(address _newImpl) public override onlyAdmin {
        // TODO: rewriet upgradeTo
        super.upgradeTo(_newImpl);
    }

    function upgradeToAndCall(address _newImpl, bytes memory data) public override onlyAdmin {
        // TODO: rewriet upgradeToAndCall
        super.upgradeToAndCall(_newImpl, data);
    }

    function _fallback() internal {
        address impl = _getSlotToAddress(IMPL_SLOT);
        _delegate(impl);
    }

    fallback() external payable override {
        // rewrite fallback
        require(msg.sender != _getSlotToAddress(ADMIN_SLOT), "admin cannot fallback");
        _fallback();
    }
}
