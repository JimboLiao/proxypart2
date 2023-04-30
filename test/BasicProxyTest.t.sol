// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Clock} from "../src/Logic/Clock.sol";
import {ClockV2} from "../src/Logic/ClockV2.sol";
import {BasicProxy} from "../src/BasicProxy.sol";

contract BasicProxyTest is Test {
    Clock public clock;
    ClockV2 public clockV2;
    BasicProxy public basicProxy;
    uint256 public alarm1Time;
    uint256 constant initialAlarm1 = 123;
    uint256 constant initialAlarm2 = 456;

    function setUp() public {
        clock = new Clock();
        clockV2 = new ClockV2();
        basicProxy = new BasicProxy(address(clock));
    }

    function testProxyWorks() public {
        // TODO: check Clock functionality is successfully proxied
        assertEq(block.timestamp, Clock(address(basicProxy)).getTimestamp());
    }

    function testInitialize() public {
        // TODO: check initialize works
        assertEq(Clock(address(basicProxy)).alarm1(), 0);
        Clock(address(basicProxy)).initialize(initialAlarm1);
        assertEq(Clock(address(basicProxy)).alarm1(), initialAlarm1);
        assertTrue(Clock(address(basicProxy)).initialized());
    }

    function testUpgrade() public {
        // TODO: check Clock functionality is successfully proxied
        address _owner = Clock(address(basicProxy)).owner();
        bool _ini = Clock(address(basicProxy)).initialized();
        uint256 _alarm2 = Clock(address(basicProxy)).alarm2();
        Clock(address(basicProxy)).setAlarm1(initialAlarm1);
        assertEq(initialAlarm1, Clock(address(basicProxy)).alarm1());

        // upgrade Logic contract to ClockV2
        basicProxy.upgradeTo(address(clockV2));
        // check state hadn't been changed
        assertEq(initialAlarm1, ClockV2(address(basicProxy)).alarm1());
        assertEq(_owner, ClockV2(address(basicProxy)).owner());
        assertEq(_ini, ClockV2(address(basicProxy)).initialized());
        assertEq(_alarm2, ClockV2(address(basicProxy)).alarm2());
        // check new functionality is available
        ClockV2(address(basicProxy)).setAlarm2(initialAlarm2);
        assertEq(initialAlarm2, ClockV2(address(basicProxy)).alarm2());
    }

    function testUpgradeAndCall() public {
        // TODO: calling initialize right after upgrade
        // check state had been changed according to initialize
        assertEq(Clock(address(basicProxy)).alarm1(), 0);
        bytes memory data = abi.encodeWithSignature("initialize(uint256)", initialAlarm1);
        basicProxy.upgradeToAndCall(address(clockV2), data);
        assertEq(ClockV2(address(basicProxy)).alarm1(), initialAlarm1);
        assertTrue(ClockV2(address(basicProxy)).initialized());
    }

    function testChangeOwnerWontCollision() public {
        // TODO: call changeOwner to update owner
        // check Clock functionality is successfully proxied
        address newOwner = address(1);
        Clock(address(basicProxy)).changeOwner(newOwner);
        assertEq(Clock(address(basicProxy)).owner(), newOwner);
    }
}
