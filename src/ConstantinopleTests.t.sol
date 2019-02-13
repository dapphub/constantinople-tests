pragma solidity ^0.5.2;

import "ds-test/test.sol";

import "./ConstantinopleTests.sol";

contract ConstantinopleTestsTest is DSTest {
    ConstantinopleTests tests;

    function setUp() public {
        tests = new ConstantinopleTests();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
