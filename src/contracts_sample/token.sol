pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public rate;
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender]    = balances[msg.sender].sub(_value);
        balances[_to]           = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from]               = balances[_from].sub(_value);
        balances[_to]                 = balances[_to].add(_value);
        allowed[_from][msg.sender]    = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract BurnableToken is BasicToken, Ownable {
    bool public burningFinished = false;

    event Burn(address indexed burner, uint256 value);
    event BurnFinished();

    modifier canBurn() {
        require(!burningFinished);
        _;
    }

    function _burn(address _who, uint256 _value) internal returns (bool) {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
        return true;
    }

    function finishBurning() onlyOwner canBurn public returns (bool) {
        burningFinished = true;
        emit BurnFinished();
        return true;
    }
}

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */





/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */



/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {

    uint public originalSupply;

    /** Interface marker */
    function isUpgradeAgent() public constant returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;

}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {

    /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
    address public upgradeMaster;

    /** The next contract where the tokens will be migrated. */
    UpgradeAgent public upgradeAgent;

    /** How many tokens we have upgraded by now. */
    uint256 public totalUpgraded;

    /**
     * Upgrade states.
     *
     * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
     * - WaitingForAgent: Token allows upgrade, but we don't have a new agent yet
     * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
     * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
     *
     */
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

    /**
     * Somebody has upgraded some of his tokens.
     */
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    /**
     * New upgrade agent available.
     */
    event UpgradeAgentSet(address agent);

    /**
     * Do not allow construction without upgrade master set.
     */
    function UpgradeableToken(address _upgradeMaster) {
        upgradeMaster = _upgradeMaster;
    }

    /**
     * Allow the token holder to upgrade some of their tokens to a new contract.
     */
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
            // Called in a bad state
            throw;
        }

        // Validate input value.
        if (value == 0) throw;

        balances[msg.sender] = safeSub(balances[msg.sender], value);

        // Take tokens out from circulation
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);

        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

    /**
     * Set an upgrade agent that handles
     */
    function setUpgradeAgent(address agent) external {

        if(!canUpgrade()) {
            // The token is not yet in a state that we could think upgrading
            throw;
        }

        if (agent == 0x0) throw;
        // Only a master can designate the next agent
        if (msg.sender != upgradeMaster) throw;
        // Upgrade has already begun for an agent
        if (getUpgradeState() == UpgradeState.Upgrading) throw;

        upgradeAgent = UpgradeAgent(agent);

        // Bad interface
        if(!upgradeAgent.isUpgradeAgent()) throw;
        // Make sure that token supplies match in source and target
        if (upgradeAgent.originalSupply() != totalSupply) throw;

        UpgradeAgentSet(upgradeAgent);
    }

    /**
     * Get the state of the token upgrade.
     */
    function getUpgradeState() public constant returns(UpgradeState) {
        if(!canUpgrade()) return UpgradeState.NotAllowed;
        else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

    /**
     * Change the upgrade master.
     *
     * This allows us to set a new owner for the upgrade mechanism.
     */
    function setUpgradeMaster(address master) public {
        if (master == 0x0) throw;
        if (msg.sender != upgradeMaster) throw;
        upgradeMaster = master;
    }

    /**
     * Child contract can enable to provide the condition when the upgrade can begun.
     */
    function canUpgrade() public constant returns(bool) {
        return true;
    }

}

//contract MintableToken is UpgradeableToken, Ownable {
//    bool public mintingFinished = false;
//
//    event Mint(address indexed to, uint256 amount);
//    event MintFinished();
//
//    modifier canMint() {
//        require(!mintingFinished);
//        _;
//    }
//
//    function mint(uint256 _amount) onlyOwner canMint public returns (bool) {
//        _mint(msg.sender, _amount);
//    }
//
//    function _mint(address _to, uint256 _amount) canMint internal returns (bool) {
//        totalSupply_  = totalSupply_.add(_amount);
//        balances[_to] = balances[_to].add(_amount);
//        emit Mint(_to, _amount);
//        emit Transfer(address(0), _to, _amount);
//        return true;
//    }
//
//    function finishMinting() onlyOwner canMint public returns (bool) {
//        mintingFinished = true;
//        emit MintFinished();
//        return true;
//    }
//}

contract ReleasableToken is ERC20, Ownable {
    address public releaseAgent;
    bool public released = false;
    mapping (address => bool) public transferAgents;

    modifier canTransfer(address _sender) {

        if(!released) {
            if(!transferAgents[_sender]) {
                throw;
            }
        }

        _;
    }

    modifier inReleaseState(bool releaseState) {
        if(releaseState != released) {
            throw;
        }
        _;
    }

    modifier onlyReleaseAgent() {
        if(msg.sender != releaseAgent) {
            throw;
        }
        _;
    }

    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
        releaseAgent = addr;
    }

    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        transferAgents[addr] = state;
    }

    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract MintableTokenExt is UpgradeableToken, Ownable {
    using SafeMathLibExt for uint;

    bool public mintingFinished = false;
    mapping (address => bool) public mintAgents;

    event MintingAgentChanged(address addr, bool state);

    struct ReservedTokensData {
        uint256 reservedTokenAmount;
        bool isReserved;
        bool isDistributed;
    }

    mapping (address => ReservedTokensData) public reservedTokensList;
    address[] public reservedTokensDestinations;
    bool reservedTokensDestinationsAreSet = false;

    modifier onlyMintAgent() {
        if(!mintAgents[msg.sender]) {
            throw;
        }
        _;
    }

    modifier canMint() {
        if(mintingFinished) throw;
        _;
    }

    function finalizeReservedAddress(address addr) public onlyMintAgent canMint {
        ReservedTokensData storage reservedTokensData = reservedTokensList[addr];
        reservedTokensData.isDistributed = true;
    }

    function isAddressReserved(address addr) public constant returns (bool isReserved) {
        return reservedTokensList[addr].isReserved;
    }

    function areTokensDistributedForAddress(address addr) public constant returns (bool isDistributed) {
        return reservedTokensList[addr].isDistributed;
    }

    function getReservedTokenAmount(address addr) public constant returns (uint256 reservedTokenAmount) {
        return reservedTokensList[addr].reservedTokenAmount;
    }

    function setReservedTokensListMultiple(address[] addrs, uint[] reservedTokenAmountList) public canMint onlyOwner {
        assert(!reservedTokensDestinationsAreSet);
        assert(addrs.length == reservedTokenAmountList.length);

        for (uint i=0; iterator < addrs.length; iterator++) {
            if (addrs[i] != address(0)) {
                setReservedTokensList(addrs[i], reservedTokenAmountList[i]);
            }
        }
        reservedTokensDestinationsAreSet = true;
    }

    function mint(address receiver, uint amount) onlyMintAgent canMint public {
        totalSupply = totalSupply.plus(amount);
        balances[receiver] = balances[receiver].plus(amount);
        Transfer(0, receiver, amount);
    }

    function setMintAgent(address addr, bool state) onlyOwner canMint public {
        mintAgents[addr] = state;
        MintingAgentChanged(addr, state);
    }

    function setReservedTokensList(address addr, uint256 reservedTokenAmount) private canMint onlyOwner {
        assert(addr != address(0));
        if (!isAddressReserved(addr)) {
            reservedTokensDestinations.push(addr);
        }

        reservedTokensList[addr] = ReservedTokensData({
            reservedTokenAmount: reservedTokenAmount,
            isReserved: true,
            isDistributed: false
            });
    }
}

contract ToriToken is MintableTokenExt, BurnableToken {
    address internal wallet_;

    event ChangedWallet(address indexed who, address indexed newWho);

    constructor() public {
        name         = "Bond Token";
        symbol       = "BND";
        decimals     = 18;
        rate         = 1;
        totalSupply_ = 0;
        wallet_      = address(this);
    }

    function changeWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        emit ChangedWallet(wallet_, _wallet);
        wallet_ = _wallet;
    }
}

contract ToriTokenEx is ToriToken {
    using SafeMath for uint256;

    uint256 timelock_ = 5 * 60;
    enum DepositState { Deposited, Returned }

    struct DepositTx {
        uint256 id;
        uint256 time;
        uint256 initAmount;
        uint256 balanceAmount;
        uint256 timelock;
        address owner;
        DepositState state;
    }

    DepositTx[] public depositList;
    mapping (address => uint256[]) public userDepositList;

    event Deposited(address indexed who, uint256 deposit_id, uint256 value);
    event Returned(address indexed who, uint256 deposit_id, uint256 value);
    event ChangedTimelock(uint256 timelock, uint256 newTimelock);

//    constructor(address _wallet) public BondToken(_wallet) {
//    }

    function() public payable {
        deposit();
    }

    function deposit() public payable returns (uint256 _depositTxId) {
        require(msg.value > 0);

        uint256 weiValue    = msg.value;
        uint256 tokenAmount = _getTokenAmount(weiValue);

        DepositTx memory depositTx = DepositTx({
            id: depositList.length,
            time: uint256(now),
            initAmount: tokenAmount,
            balanceAmount: tokenAmount,
            timelock : timelock_,
            owner: msg.sender,
            state: DepositState.Deposited
            });

        depositList.push(depositTx);
        userDepositList[msg.sender].push(depositTx.id);

        _mint(msg.sender, tokenAmount);
        bool result = wallet_.send(weiValue);
        require(result);
        emit Deposited(msg.sender, depositTx.id, weiValue);

        if(!result)
            return 0;

        return depositTx.id;
    }

    function totalDepositCount() public view returns (uint256) {
        return depositList.length;
    }

    function myDepositCount() public view returns (uint256) {
        return userDepositList[msg.sender].length;
    }

    function myDepositList() public view returns (uint256[]) {
        return userDepositList[msg.sender];
    }


    // 노출여부
    function totalDepositBalance() public view returns (uint256) {
        return wallet_.balance;
    }

    modifier onlyOnwer(uint256 _deposit_id) {
        require(depositList[_deposit_id].owner == msg.sender);
        _;
    }

    modifier checkTimelock(uint256 _deposit_id) {
        require(depositList[_deposit_id].timelock + depositList[_deposit_id].time <= uint256(now));
        _;
    }

    modifier canReturn(uint256 _amount) {
        require(balances[msg.sender] >= _amount);
        _;
    }

    function claim(uint256 _deposit_id) public onlyOnwer(_deposit_id) returns (bool) {
        require(depositList[_deposit_id].state == DepositState.Deposited
        && depositList[_deposit_id].balanceAmount > 0
        && balances[msg.sender] >= depositList[_deposit_id].balanceAmount);

        depositList[_deposit_id].balanceAmount = 0;
        depositList[_deposit_id].state = DepositState.Returned;

        uint256 claimTokenAmount = depositList[_deposit_id].balanceAmount;
        uint256 claimWeiValue = _getWeiValue(depositList[_deposit_id].balanceAmount);

        balances[msg.sender] = balances[msg.sender].sub(claimTokenAmount);
        _burn(msg.sender, claimWeiValue);

        bool result = msg.sender.send(claimWeiValue);
        require(result);
        emit Returned(msg.sender, _deposit_id, claimWeiValue);
        return result;
    }

    function claimPartially(uint256 _deposit_id, uint256 _weiValue) public onlyOnwer(_deposit_id) canReturn(_weiValue) returns (bool) {
        require(depositList[_deposit_id].state == DepositState.Deposited
        && depositList[_deposit_id].balanceAmount >= _weiValue);

        depositList[_deposit_id].balanceAmount = depositList[_deposit_id].balanceAmount.sub(_weiValue);
        if ( depositList[_deposit_id].balanceAmount == 0) {
            depositList[_deposit_id].state = DepositState.Returned;
        }

        uint256 claimTokenAmount = _getTokenAmount(_weiValue);
        balances[msg.sender] = balances[msg.sender].sub(claimTokenAmount);

        bool result = msg.sender.send(_weiValue);
        require(result);
        return result;
    }

    function totalDepositValue() public view returns (uint256) {
        // need to implement
        uint256 _depositCount = totalDepositCount();
        uint256 totalValue;
        for (uint256 i=0; i < _depositCount; i++) {
            totalValue = totalValue.add(depositList[i].initAmount);
        }
        return totalValue;
    }

    function myDepositValue() public view returns (uint256) {
        uint256 count = myDepositCount();
        uint256 totalValue;
        for (uint256 i=0; i<count; i++) {
            totalValue = totalValue.add(depositList[userDepositList[msg.sender][i]].initAmount);
        }
        return totalValue;
    }

    function myDepositBalance() public view returns (uint256) {
        uint256 count = myDepositCount();
        uint256 totalValue;
        for (uint256 i=0; i<count; i++) {
            totalValue = totalValue.add(depositList[userDepositList[msg.sender][i]].balanceAmount);
        }
        return totalValue;
    }

    function totalReturnedCount() public view returns (uint256) {
        uint256 _depositCount = totalDepositCount();
        uint256 count;
        for (uint256 i=0; i < _depositCount; i++) {
            if ( depositList[i].state == DepositState.Returned ) {
                count++;
            }
        }
        return count;
    }

    function myReturnedCount() public view returns (uint256) {
        uint256 _myDepositCount = myDepositCount();
        uint256 count;
        for (uint256 i=0; i < _myDepositCount; i++) {
            if ( depositList[userDepositList[msg.sender][i]].state == DepositState.Returned) {
                count++;
            }
        }
        return count;
    }

    function changeTimelock(uint256 _timelock) public onlyOwner {
        require(_timelock > 5 * 60);
        emit ChangedTimelock(timelock_, _timelock);
        timelock_ = _timelock;
    }

    function _getTokenAmount(uint256 _weiValue) view private returns (uint256) {
        return _weiValue.mul(rate);
    }

    function _getWeiValue(uint256 _tokenAmount) view private returns (uint256) {
        return _tokenAmount.div(rate);
    }
}


// https://www.paybear.io/
// https://www.blockchain.com/
// https://ethereumbuilders.gitbooks.io/guide/content/en/ethereum_javascript_api.html
// https://www.npmjs.com/package/blockapps-js



//// upgradable, metamask 일때 서버사이드 일 때 시나리오.
