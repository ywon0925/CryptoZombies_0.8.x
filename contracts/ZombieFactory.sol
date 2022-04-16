// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract ZombieFactory is Ownable, VRFConsumerBase {

  event NewZombie(uint zombieId, string name, uint dna);

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint cooldownTime = 1 days;

  // using chainlink
  bytes32 public keyHash;
  uint256 public fee;
  uint256 public randomResult;
  
  // non need  to have constructor public, it's called only once at a creation
  constructor() VRFConsumerBase(
      0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
      0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
      
  ){
      keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
      fee = 100000000000000000;
  }

  struct Zombie {
    string name;
    uint dna;
    uint32 level;
    uint32 readyTime;
    uint16 winCount;
    uint16 lossCount;
  }

  Zombie[] public zombies;

  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) ownerZombieCount;

  function _createZombie(string memory _name, uint _dna) internal {
    // after 0.6.0 push no longer return the length, instead return the reference to the added element
    zombies.push(Zombie(_name, _dna, 1, uint32(block.timestamp + cooldownTime), 0, 0));
    uint id = zombies.length - 1;
    zombieToOwner[id] = msg.sender;
    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender] + 1;
    emit NewZombie(id, _name, _dna);
  }
  
  function getRandomNumber() public returns (bytes32 requestId) {
    return requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    randomResult = randomness;
  }

  function _generateRandomDna(string memory _str) private view returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(_str)));
    return rand % dnaModulus;
  }

  function createRandomZombie(string memory _name) public {
    require(ownerZombieCount[msg.sender] == 0);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 100;
    _createZombie(_name, randDna);
  }

}
