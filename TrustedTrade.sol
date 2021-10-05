// SPDX-License-Identifier: UNLICENSED 
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TrustedTrade
 * 
 */

contract TrustedTrade {
    
    enum contractState {Null, Set, Deal, Lock, Approve}
    enum contractOwner {Seller, Buyer, Notary}

    struct vehicleContract  {
        string plateNumber;
        string vinNumber;
        uint licenseId;
        address seller;
        address buyer;
        address notary;
        uint fee;
        bytes32 sellerPasscode;
        bytes32 buyerPasscode;
        contractState state;
    }
    
    mapping(address => vehicleContract) vehicleContracts;
    
    address owner;
    constructor() {
        owner = msg.sender;
    }
    
    fallback() external payable {}
    receive() external payable {}
    
    modifier contractStateModifier (contractState state) {
      require(vehicleContracts[owner].state == state);
      _;
    }
    
    function getContract(address seller) external view returns (vehicleContract memory) {
        return vehicleContracts[seller]; 
    }
    
    function setContract( string memory platenumber,
                          string memory vinnumber,
                          uint licenseid,
                          uint fee,
                          string  memory passcode ) external contractStateModifier(contractState.Null) {

        vehicleContracts[msg.sender].plateNumber = platenumber;
        vehicleContracts[msg.sender].vinNumber = vinnumber; 
        vehicleContracts[msg.sender].licenseId = licenseid;
        vehicleContracts[msg.sender].seller = msg.sender;
        vehicleContracts[msg.sender].fee = fee;
        vehicleContracts[msg.sender].sellerPasscode = sha256(bytes(passcode));
        vehicleContracts[msg.sender].state = contractState.Set;
    }
    
    function dealContract( address seller, string  memory passcode ) payable external contractStateModifier(contractState.Set) {
        if(msg.value != vehicleContracts[seller].fee)
        {
            revert();
        }
        vehicleContracts[seller].buyer = msg.sender;
        vehicleContracts[seller].buyerPasscode = sha256(bytes(passcode));
        vehicleContracts[seller].state = contractState.Deal;
    }
    
    function lockContract( address seller, 
                           address buyer, 
                           string  memory sellerpasscode, 
                           string  memory buyerpasscode ) external contractStateModifier(contractState.Deal) {
        if( vehicleContracts[seller].seller != seller ||
            vehicleContracts[seller].buyer != buyer ||
            vehicleContracts[seller].sellerPasscode != sha256(bytes(sellerpasscode)) ||
            vehicleContracts[seller].buyerPasscode != sha256(bytes(buyerpasscode)) )
        {
            revert();
        }
        vehicleContracts[seller].notary = msg.sender;
        vehicleContracts[seller].state = contractState.Lock;
    }
    
    function aproveContract( address payable seller, 
                             address buyer, 
                             string  memory sellerpasscode, 
                             string  memory buyerpasscode ) external contractStateModifier(contractState.Lock) {
        if( vehicleContracts[seller].seller != seller ||
            vehicleContracts[seller].buyer != buyer ||
            vehicleContracts[seller].notary != msg.sender ||
            vehicleContracts[seller].sellerPasscode != sha256(bytes(sellerpasscode)) ||
            vehicleContracts[seller].buyerPasscode != sha256(bytes(buyerpasscode)) )
        {
            revert();
        }
        
        seller.transfer(vehicleContracts[seller].fee);
        vehicleContracts[seller].state = contractState.Approve;
    }
    
    function cancelContractbySeller(string  memory sellerpasscode) external contractStateModifier(contractState.Set) {
        if( vehicleContracts[msg.sender].seller != msg.sender ||
            vehicleContracts[msg.sender].sellerPasscode != sha256(bytes(sellerpasscode)) )
        {
            revert();
        }
        vehicleContracts[msg.sender].state = contractState.Null;
    }
    
    function cancelContractbyBuyer(address seller, 
                                   address payable buyer,
                                   string  memory buyerpasscode) external contractStateModifier(contractState.Deal) {
        if( vehicleContracts[seller].buyer != msg.sender ||
            vehicleContracts[seller].buyerPasscode != sha256(bytes(buyerpasscode)) )
        {
            revert();
        }
        buyer.transfer(vehicleContracts[seller].fee);
        vehicleContracts[seller].state = contractState.Null;
    }
    
    function cancelContractbyNotary(address seller, 
                                    address payable buyer,
                                    string  memory sellerpasscode,
                                    string  memory buyerpasscode) external contractStateModifier(contractState.Lock) {
        if( vehicleContracts[seller].notary != msg.sender ||
            vehicleContracts[seller].sellerPasscode != sha256(bytes(sellerpasscode)) ||
            vehicleContracts[seller].buyerPasscode != sha256(bytes(buyerpasscode)) )
        {
            revert();
        }
        buyer.transfer(vehicleContracts[seller].fee);
        vehicleContracts[seller].state = contractState.Null;
    }
}