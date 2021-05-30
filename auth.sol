pragma solidity ^0.6.12; // #####  SPDX-License-Identifier: None
import 'IBEP20.sol';
abstract contract auth {
    address _owner; address gov;
    mapping (address => bool) _whiteList;
    mapping (address => bool) _adminList;
    mapping (address => bool) _blackList;
    constructor() public{ 
        _owner = msg.sender; 
        _whiteList[msg.sender] = true;
        _adminList[msg.sender] = true;
    }
        function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }    
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
    
    function isGovern(address account) public view returns (bool) {
    return account == gov;
    }
        
    function isAdmin(address account) public view returns (bool) {
        return _adminList[account];
    }
    
    
    function isAuth(address account) public view returns (bool) {
        return _whiteList[account];
    }

    function isBanned(address account) public view returns (bool) {
        return _blackList[account];
    }
    
    modifier govern() {
    require(isOwner(_msgSender()) || isGovern(_msgSender())
    ); _;    
    }
        
    modifier admin() {
    require(isOwner(_msgSender()) || isAdmin(_msgSender())
    ); _;    
    }
    modifier onlyOwner() {
        require(isOwner(_msgSender())); _;
    }
    modifier _auth() {
        require(_whiteList[_msgSender()] == true); _;
    }
    modifier _banCheck() {
        require(_blackList[_msgSender()] == false); _;
    }
    function whiteList(address adr) public onlyOwner {
        _whiteList[adr] = true;
    }
    function unwhiteList(address adr) external onlyOwner {
        _whiteList[adr] = false;
    }
   function blackList(address adr) public onlyOwner {
        _blackList[adr] = true;
    }
    function unBlackList(address adr) external onlyOwner {
        _blackList[adr] = false;
    }
    function makeAdmin(address adr) public onlyOwner {
        _adminList[adr] = true;
    }
    function takeAdmin(address adr) public onlyOwner {
        _adminList[adr] = false;
    }
    function transferOwnership(address payable adr) public onlyOwner {
        _owner = adr;
    }
}
