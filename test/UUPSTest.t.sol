// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";
import {ClockUUPS} from "../src/UUPSLogic/ClockUUPS.sol";
import {ClockUUPSV2} from "../src/UUPSLogic/ClockUUPSV2.sol";
import {ClockUUPSV3} from "../src/UUPSLogic/ClockUUPSV3.sol";

contract UUPSTest is Test {
    ClockUUPS public clock;
    ClockUUPSV2 public clockV2;
    ClockUUPSV3 public clockV3;
    UUPSProxy public uupsProxy;
    uint256 public alarm1Time;
    uint256 public constant initialAlarm1 = 123;
    uint256 public constant initialAlarm2 = 456;

    address admin;
    address user1;

    function setUp() public {
        admin = makeAddr("admin");
        user1 = makeAddr("noob");
        clock = new ClockUUPS();
        clockV2 = new ClockUUPSV2();
        clockV3 = new ClockUUPSV3();
        bytes memory data = abi.encodeWithSignature("initialize(uint256)", initialAlarm1);
        vm.prank(admin);
        // initialize UUPS proxy
        uupsProxy = new UUPSProxy(data, address(clock));
    }

    function testProxyWorks() public {
        // check Clock functionality is successfully proxied
        assertTrue(ClockUUPS(address(uupsProxy)).initialized());
        assertEq(ClockUUPS(address(uupsProxy)).alarm1(), initialAlarm1);
    }

    function testUpgradeToWorks() public {
        // check upgradeTo works aswell
        ClockUUPS(address(uupsProxy)).upgradeTo(address(clockV3));
        ClockUUPSV3(address(uupsProxy)).setAlarm2(initialAlarm2);
        assertEq(ClockUUPSV3(address(uupsProxy)).alarm2(), initialAlarm2);
    }

    function testCantUpgrade() public {
        // check upgradeTo should fail if implementation doesn't inherit Proxiable
        vm.expectRevert("not proxiable");
        ClockUUPS(address(uupsProxy)).upgradeTo(address(clockV2)); // ClockUUPSV2 doesn't inherit Proxiable
    }

    function testCantUpgradeIfLogicDoesntHaveUpgradeFunction() public {
        // check upgradeTo should fail if implementation doesn't implement upgradeTo
        ClockUUPS(address(uupsProxy)).upgradeTo(address(clockV3)); // ClockUUPSV3 doesn't implement upgradeTo
        bytes memory data = abi.encodeWithSignature("upgradeTo(address)", address(clock));
        vm.expectRevert();
        (bool success,) = address(uupsProxy).call(data); // revert, success will not be set
            // ClockUUPSV3(address(uupsProxy)).upgradeTo(address(clock)); // this line will cause compilation error, since V3 doesn' have upgradeTo
    }
}
