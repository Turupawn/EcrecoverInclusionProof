// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUltraVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

abstract contract Utils {
    // UINT TO STRING
    // From OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    // CONCATENATE HEX ARRAY
    // From ChatGPT
    function concatenateHexArray(bytes32[] memory hexArray, uint start, uint end) internal pure returns (bytes32) {
        bytes32 result;
        for (uint256 i = start; i < end; i++) {
            result = result << 8 | hexArray[i];
        }
        return result;
    }
}

contract CommentVerifier is Utils {
    uint public commentCount;
    mapping(uint commentCount => string comment) public comments;
    IUltraVerifier ultraVerifier;
    bytes32 merkleRoot;

    constructor(address verifierAddress, bytes32 _merkleRoot) {
        ultraVerifier = IUltraVerifier(verifierAddress);
        merkleRoot = _merkleRoot;
    }

    function hashCommentMessage(string memory comment) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n",
            toString(bytes(comment).length),
            comment));
    }

    function sendProof(bytes calldata _proof, bytes32[] calldata _publicInputs, string memory comment) public
    {
        require(concatenateHexArray(_publicInputs, 0, 32) == hashCommentMessage(comment), "Invalid message hash");
        require(_publicInputs[32] == merkleRoot, "Invalid merkle root");
        ultraVerifier.verify(_proof, _publicInputs);
        comments[commentCount] = comment;
        commentCount += 1;
    }
}
