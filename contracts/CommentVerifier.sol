// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUltraVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

abstract contract Utils {
    // ADDRESS TO STRING
    // From 0age on Stackoverflow
    //https://ethereum.stackexchange.com/questions/63908/address-checksum-solidity-implementation
    function toChecksumString( address account) internal pure returns (string memory asciiString) {
      // convert the account argument from address to bytes.
      bytes20 data = bytes20(account);

      // create an in-memory fixed-size bytes array.
      bytes memory asciiBytes = new bytes(40);

      // declare variable types.
      uint8 b;
      uint8 leftNibble;
      uint8 rightNibble;
      bool leftCaps;
      bool rightCaps;
      uint8 asciiOffset;

      // get the capitalized characters in the actual checksum.
      bool[40] memory caps = _toChecksumCapsFlags(account);

      // iterate over bytes, processing left and right nibble in each iteration.
      for (uint256 i = 0; i < data.length; i++) {
        // locate the byte and extract each nibble.
        b = uint8(uint160(data) / (2**(8*(19 - i))));
        leftNibble = b / 16;
        rightNibble = b - 16 * leftNibble;

        // locate and extract each capitalization status.
        leftCaps = caps[2*i];
        rightCaps = caps[2*i + 1];

        // get the offset from nibble value to ascii character for left nibble.
        asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

        // add the converted character to the byte array.
        asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

        // get the offset from nibble value to ascii character for right nibble.
        asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

        // add the converted character to the byte array.
        asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
      }

      return string(asciiBytes);
    }

    function _toChecksumCapsFlags(address account) internal pure returns (bool[40] memory characterCapitalized) {
      // convert the address to bytes.
      bytes20 a = bytes20(account);

      // hash the address (used to calculate checksum).
      bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

      // declare variable types.
      uint8 leftNibbleAddress;
      uint8 rightNibbleAddress;
      uint8 leftNibbleHash;
      uint8 rightNibbleHash;

      // iterate over bytes, processing left and right nibble in each iteration.
      for (uint256 i; i < a.length; i++) {
        // locate the byte and extract each nibble for the address and the hash.
        rightNibbleAddress = uint8(a[i]) % 16;
        leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
        rightNibbleHash = uint8(b[i]) % 16;
        leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

        characterCapitalized[2 * i] = (
          leftNibbleAddress > 9 &&
          leftNibbleHash > 7
        );
        characterCapitalized[2 * i + 1] = (
          rightNibbleAddress > 9 &&
          rightNibbleHash > 7
        );
      }
    }

    function _getAsciiOffset(uint8 nibble, bool caps) internal pure returns (uint8 offset) {
      // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
      if (nibble < 10) {
        offset = 48;
      } else if (caps) {
        offset = 55;
      } else {
        offset = 87;
      }
    }


    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data) internal pure returns (string memory asciiString) {
      // create an in-memory fixed-size bytes array.
      bytes memory asciiBytes = new bytes(40);

      // declare variable types.
      uint8 b;
      uint8 leftNibble;
      uint8 rightNibble;

      // iterate over bytes, processing left and right nibble in each iteration.
      for (uint256 i = 0; i < data.length; i++) {
        // locate the byte and extract each nibble.
        b = uint8(uint160(data) / (2 ** (8 * (19 - i))));
        leftNibble = b / 16;
        rightNibble = b - 16 * leftNibble;

        // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
        asciiBytes[2 * i] = bytes1(leftNibble + (leftNibble < 10 ? 48 : 87));
        asciiBytes[2 * i + 1] = bytes1(rightNibble + (rightNibble < 10 ? 48 : 87));
      }

      return string(asciiBytes);
    }

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
    function concatenateHexArray(bytes32[] memory hexArray) internal pure returns (bytes32) {
        bytes32 result;
        for (uint256 i = 0; i < hexArray.length; i++) {
            result = result << 8 | hexArray[i];
        }
        return result;
    }
}

contract CommentVerifier is Utils {
    uint public commentAmount;
    mapping(uint commentId => string title) public titles;
    mapping(uint commentId => string text) public texts;
    IUltraVerifier ultraVerifier;

    string public myAddress;
    string public messageHeader;
    string public messagePrefix;
    string public messageMiddlefix;
    string public messageSuffix;

    constructor(address verifierAddress) {
        ultraVerifier = IUltraVerifier(verifierAddress);

        myAddress = toChecksumString(address(this));
        messageHeader = "\x19Ethereum Signed Message:\n";
        messagePrefix = string(abi.encodePacked(
                "{\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"Comment\":[{\"name\":\"title\",\"type\":\"string\"},{\"name\":\"text\",\"type\":\"string\"}]},\"primaryType\":\"Comment\",\"domain\":{\"name\":\"Anon Message Board\",\"version\":\"1\",\"chainId\":534351,\"verifyingContract\":\"0x",
                myAddress,
                "\"},\"message\":{\"title\":\""));
        messageMiddlefix = "\",\"text\":\"";
        messageSuffix = "\"}}";
    }

    function isValidHash(bytes32 hash, string memory title, string memory text) public view returns(bool) {
        string memory jsonMessage = string(abi.encodePacked(messagePrefix, title, messageMiddlefix, text, messageSuffix));
        return hash == keccak256(abi.encodePacked(
            messageHeader,
            toString(bytes(jsonMessage).length),
            jsonMessage));
    }

    function sendProof(bytes calldata _proof, bytes32[] calldata _publicInputs, string memory title, string memory text) public
    {
        require(isValidHash(concatenateHexArray(_publicInputs), title, text), "Invalid message hash");
        ultraVerifier.verify(_proof, _publicInputs);
        titles[commentAmount] = title;
        texts[commentAmount] = text;
        commentAmount+=1;
    }
}
