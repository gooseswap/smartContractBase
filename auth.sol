pragma solidity ^0.7.4;

abstract contract Auth {
    address payable _owner;
    mapping (address => bool) _authorizations;
    
    constructor() { 
        _owner = msg.sender; 
        _authorizations[msg.sender] = true;
    }
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
    modifier owned() {
        require(isOwner(msg.sender)); _;
    }
    modifier authorized() {
        require(_authorizations[msg.sender] == true); _;
    }
    function authorize(address adr) public authorized {
        _authorizations[adr] = true;
    }
    function unauthorize(address adr) external owned {
        _authorizations[adr] = false;
    }
    function transferOwnership(address payable adr) public owned() {
        _owner = adr;
    }
}
