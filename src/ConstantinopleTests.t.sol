pragma solidity ^0.5.2;

import "ds-test/test.sol";

import "./ConstantinopleTests.sol";

contract DeadCode {
    function dummy() external returns (bytes32);
}

contract ConstantinopleTestsTest is DSTest {

    ConstantinopleTests tests;
    // this 13 byte-long initcode simply returns 0xdeadbeef:
    // PUSH4  de     ad     be     ef     PUSH1  00     MSTORE PUSH1  04     PUSH1  00     RETURN
    // 63     de     ad     be     ef     60     00     52     60     04     60     00     f3
    bytes32 deadcode        = 0x63deadbeef60005260046000f300000000000000000000000000000000000000
    // this 25 byte-long initcode returns deadcode (but without the padding)
    // PUSH1  0d     PUSH1  0c     PUSH1  00     CODECO PUSH1  0d     PUSH1  00     RETURN deadcode
    // 60     0d     60     0c     60     00     39     60     0d     60     00     f3
    bytes32 deploysdeadcode = 0x600d600c600039600d6000f363deadbeef60005260046000f300000000000000

    function setUp() public {
        tests = new ConstantinopleTests();
    }

    // EXTCODEHASH of non-existent account is 0
    function test_extcodehash_1() public {
        uint256 h;
        assembly {
            h := extcodehash(0x0)
        }
        assertEq(h, 0);
    }
    // EXTCODEHASH of account with code 0x0 is 0
    function test_extcodehash_2() public {
        address a;
        uint256 h;
        assembly {
            a := create(0, 0, 0)
            h := extcodehash(a)
        }
        assertEq(h, 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
    // EXTCODEHASH of account with code 0xdeadbeef is keccak256(0xdeadbeef)
    function test_extcodehash_3() public {
        address a;
        uint256 h;

        assembly {
          let pos := mload(0x40)
          mstore(pos, deadcode)
          a := create(0, pos, 13)
          h := extcodehash(a)
        }
        assertEq(h, keccak256(0xdeadbeef));
    }

    // address of account created by CREATE2 is
    // keccak256(0xff + address + salt + keccak256(init_code))[12:]
    function test_create2_1() public {
        address a;
        bytes32 salt = 0xfacefeed
        assembly {
          let pos := mload(0x40)
          mstore(pos, deadcode)
          a := create2(0, pos, 13, salt)
        }

        address expected_a;

        assembly {
          let pos := mload(0x40)
          mstore(pos, deadcode)
          let inithash := keccak256(pos, 13)
          mstore(pos, 0xff)
          mstore(add(pos, 1), address)
          mstore(add(pos, 21), salt)
          mstore(add(pos, 53), inithash)
          expected_a := xor(keccak256(pos, 85), 0x0000000000000000000000001111111111111111111111111111111111111111)
        }

        assertEq(a, expected_a);
    }
    // calling a CREATE2 contract works as expected
    function test_create2_2() public {
        address a;
        bytes32 salt = 0xfacefeed
        assembly {
          let pos := mload(0x40)
          mstore(pos, deploysdeadcode)
          a := create2(0, pos, 25, salt)
        }

        assertEq(DeadCode(a).dummy(), 0xdeadbeef);
    }
    // TODO: test some SELFDESTRUCT properties of CREATE2
    // TODO: test EXTCODEHASH on self-destructed contract
    // TODO: test EXTCODEHASH on precompiled contracts
}
