pragma solidity ^0.7.4;

abstract contract auth {
    address payable _owner;
    mapping (address => bool) _whiteList;
    mapping (address => bool) _blackList;
    
    constructor() { 
        _owner = msg.sender; 
        _whiteList[msg.sender] = true;
    }
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }
    modifier auth() {
        require(_whiteList[msg.sender] == true); _;
    }
    modifier banList() {
        require(_blackList[msg.sender] == false); _;
    }
    function authorize(address adr) public owned {
        _whitelist[adr] = true;
    }
    function unauthorize(address adr) external owned {
        _whitelist[adr] = false;
    }
   function blackList(address adr) public owned {
        _blackList[adr] = true;
    }
    function unBlackList(address adr) external owned {
        _blackList[adr] = false;
    }
    function transferOwnership(address payable adr) public owned {
        _owner = adr;
    }
}
