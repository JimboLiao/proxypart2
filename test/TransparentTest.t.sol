// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Transparent} from "../src/Transparent.sol";
import {Clock} from "../src/Logic/Clock.sol";
import {ClockV2} from "../src/Logic/ClockV2.sol";

contract TransparentTest is Test {
    Clock public clock;
    ClockV2 public clockV2;
    Transparent public transparentProxy;
    uint256 public alarm1Time;
    uint256 constant initialAlarm1 = 123;
    uint256 constant initialAlarm2 = 456;

    address admin;
    address user1;

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }

    function setUp() public {
        admin = makeAddr("admin");
        user1 = makeAddr("noobUser");
        clock = new Clock();
        clockV2 = new ClockV2();
        vm.prank(admin);
        transparentProxy = new Transparent(address(clock));
    }

    function testProxyWorks(uint256 _alarm1) public {
        // check Clock functionality is successfully proxied
        Clock(address(transparentProxy)).initialize(_alarm1);
        assertEq(_alarm1, Clock(address(transparentProxy)).alarm1());
    }

    function testUpgradeToOnlyAdmin(uint256 _alarm1, uint256 _alarm2) public {
        // check upgradeTo could be called only by admin
        // user1 -- call --> "transparentProxy" -- delegatecall --> "clock" upgradeTo(), this function does not exist and no fallback in clock -> revert
        vm.prank(user1);
        vm.expectRevert();
        transparentProxy.upgradeTo(address(1));

        vm.prank(admin);
        transparentProxy.upgradeTo(address(clockV2));
        bytes32 implementationSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(bytes32ToAddress(vm.load(address(transparentProxy), implementationSlot)), address(clockV2));
        ClockV2(address(transparentProxy)).setAlarm1(_alarm1);
        ClockV2(address(transparentProxy)).setAlarm2(_alarm2);

        assertEq(_alarm1, ClockV2(address(transparentProxy)).alarm1());
        assertEq(_alarm2, ClockV2(address(transparentProxy)).alarm2());
    }

    function testUpgradeToAndCallOnlyAdmin(uint256 _alarm1) public {
        // check upgradeToAndCall could be called only by admin
        vm.prank(user1);
        vm.expectRevert();
        transparentProxy.upgradeToAndCall(address(1), "");

        bytes memory data = abi.encodeWithSignature("initialize(uint256)", _alarm1);
        vm.prank(admin);
        transparentProxy.upgradeToAndCall(address(clockV2), data);
        assertEq(ClockV2(address(transparentProxy)).alarm1(), _alarm1);
        assertTrue(ClockV2(address(transparentProxy)).initialized());
    }

    function testFallbackShouldRevertIfSenderIsAdmin(uint256 _alarm1) public {
        // check admin shouldn't trigger fallback
        vm.expectRevert("admin cannot fallback");
        vm.prank(admin);
        Clock(address(transparentProxy)).setAlarm1(_alarm1);
    }

    function testFallbackShouldSuccessIfSenderIsntAdmin(uint256 _alarm1) public {
        vm.prank(user1);
        Clock(address(transparentProxy)).setAlarm1(_alarm1);
        assertEq(Clock(address(transparentProxy)).alarm1(), _alarm1);
    }
}
