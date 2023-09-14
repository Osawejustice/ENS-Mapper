//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ENSMapper is Ownable {

    using Strings for uint256;

    ENS private ens;
    bytes32 public domainHash;
    mapping(bytes32 => mapping(string => string)) public texts;

    string public domainLabel = "trace";

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event RegisterSubdomain(address indexed registrar, string indexed label);

    constructor() {
        ens = ENS(0x70B4fa925Cfa8AD866ECa550933a21E69c22Cd2A);
        domainHash = getDomainHash();
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de //addr
        || interfaceID == 0x59d1d43c //text
        || interfaceID == 0x691f3431 //name
        || interfaceID == 0x01ffc9a7; //supportsInterface
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
        require(ens.recordExists(node), "Invalid address");
        return texts[node][key];
    }

    function name(bytes32 node) view public returns (string memory) {
        return ens.recordExists(node) ? string(abi.encodePacked(domainLabel, ".eth")) : "";
    }

    function domainMap(string calldata label) public view returns(bytes32) {
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));
        return ens.recordExists(big_hash) ? big_hash : bytes32(0x0);
    }

    function getDomainHash() private view returns (bytes32 namehash) {
        namehash = keccak256(abi.encodePacked(keccak256(abi.encodePacked('eth')), keccak256(abi.encodePacked(domainLabel))));
    }

    function setDomain(string calldata label) public {
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));
        require(!ens.recordExists(big_hash) || msg.sender == owner(), "sub-domain already exists");
        ens.setSubnodeRecord(domainHash, encoded_label, owner(), address(this), 0);
        emit RegisterSubdomain(msg.sender, label);
    }

    function setText(bytes32 node, string calldata key, string calldata value) external {
        require(ens.recordExists(node), "Invalid address");
        require(keccak256(abi.encodePacked(key)) != keccak256("avatar"), "cannot set avatar");
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    function setDomainLabel(string calldata label) public onlyOwner {
        domainLabel = label;
        domainHash = getDomainHash();
    }

    function setEnsAddress(address addy) public onlyOwner {
        ens = ENS(addy);
    }

    function renounceOwnership() public override onlyOwner {
        require(false, "Sorry - you cannot renounce ownership.");
        super.renounceOwnership();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
