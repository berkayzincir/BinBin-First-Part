// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract BinBins is ReentrancyGuard {

 //DATA

 //Counter
using Counters for Counters.Counter;
  Counters.Counter private _counter;
 //Owner
address private owner;
 //totalPayments
 uint private totalPayments;

 //user Struct
 struct User {
    address walletAddress;
    string name;
    string lastname;
    uint rentedBinBinId;
    uint balance;
    uint debt;
    uint startTime;
 }

 //binbin struct

 struct BinBin {
    uint id;
    string name;
    string imgURL;
    Status status;
    uint rentFee;
    uint saleFee;
 }

 // enum indicate the status of the car
enum Status {
    Retired,
    InUse,
    Available
}


//events
event BinBinAdded(uint indexed id, string name, string imgUrl, uint rentFee, uint saleFee);
event BinBinMetadataEditeduint (uint indexed id, string name, string imgUrl, uint rentFee, uint saleFee);
event BinBinStatusEdited(uint indexed id, Status status);
event UserAdded(address indexed walletAddress, string name, string lastname);
event Deposit(address indexed walletAddress, uint amount);
event CheckOut(address indexed walletAddress, uint indexed BinBinid);
event CheckIn(address indexed walletAddress, uint indexed BinBinid);
event PaymentMade(address indexed walletAddress, uint amount);
event BalanceWithdraw(address indexed walletAddress, uint amount);

//user mapping
mapping(address => User) private users;

//BinBin mapping
mapping(uint => BinBin) private binbins;

//constructor
constructor() {
owner = msg.sender;
totalPayments = 0;
}

//MODIFIERS
//onlyOwners
modifier onlyOwner(){
    require(msg.sender == owner, "Only the owner call this function");
    _;
}


//FUNCTION
//Execute Functions
//setOwner #onlyOwner
function setOwner (address _owner) external onlyOwner {
    owner = _owner;
}

//addUser #nonExisting
function addUser(string calldata name, string calldata surname) external {
require(!isUser(msg.sender), "User already exists");
users[msg.sender] = User(msg.sender, name, surname,0,0,0,0);
emit UserAdded(msg.sender,users[msg.sender].name, users[msg.sender].lastname);
}

//addCar #onlyOwner #nonExistingCar
function addBinBin(string calldata name, string calldata img, uint rent, uint sale) external onlyOwner {
_counter.increment();
uint counter = _counter.current();
binbins[counter] = BinBin(counter, name, img,Status.Available,rent,sale);
emit BinBinAdded(counter, binbins[counter].name, binbins[counter].imgURL,binbins[counter].rentFee, binbins[counter].saleFee );
}



//editCarMetaData #onlyOwner #ExistingCar

function editBinBinMetaData(uint id, string calldata name, string calldata imgURL, uint rentFee, uint saleFee) external onlyOwner{
    require(binbins[id].id != 0, "There is not a binbin");
    BinBin storage binbin = binbins[id];
    if(bytes(name).length != 0){
    binbin.name = name;
    }
   if(bytes(imgURL).length != 0){
    binbin.imgURL = imgURL;
    }
     if(rentFee > 0){
    binbin.rentFee = rentFee;
    }
  if(saleFee > 0){
    binbin.saleFee = saleFee;
    }

    emit BinBinMetadataEditeduint(id, binbin.name, binbin.imgURL, binbin.rentFee, binbin.saleFee);
}

//editCarStatus #onlyOwner #ExistingCar
function editStatus(uint id, Status status) external onlyOwner {
    require(binbins[id].id != 0, "There is not a binbin");
    binbins[id].status = status;

    emit BinBinStatusEdited(id,status);
}

//Checkout #existingUser #isCarAvailable #userHasNotRentedACar #userHasNoDebt
function checkOut(uint id) external {
    require(isUser(msg.sender), "User does not exist");
    require(users[msg.sender].debt == 0, "You have a debt");
    require(binbins[id].status == Status.Available, "Binbin not available");
    require(users[msg.sender].rentedBinBinId==0, "User has already rent a car");
    users[msg.sender].startTime = block.timestamp;
    binbins[id].status == Status.InUse;
    users[msg.sender].rentedBinBinId = id;
    emit CheckOut(msg.sender, id);
}



//CheckIn #existingUser #userHasRentedACar
function checkIn() external {
    require(isUser(msg.sender), "User does not exist");
    uint rentedBinBinId = users[msg.sender].rentedBinBinId;
    require(rentedBinBinId != 0, "You are not rent a binbin");
    uint usedSeconds = block.timestamp - users[msg.sender].startTime;
    uint rentFee = binbins[rentedBinBinId].rentFee;
    users[msg.sender].debt += calculateDebt(usedSeconds, rentFee);
    users[msg.sender].rentedBinBinId = 0;
    users[msg.sender].startTime = 0;
    binbins[rentedBinBinId].status = Status.Available;
    
   emit CheckIn(msg.sender, rentedBinBinId);


}

//deposit #existingUser
function deposit() external payable {
require(isUser(msg.sender), "User does not exist");
    users[msg.sender].balance += msg.value;
emit Deposit(msg.sender, msg.value);
}
//makePayment #existingUser #existingDebt #suffiecientBalance
function makePayment() external {
require(isUser(msg.sender), "User does not exist");
uint debt = users[msg.sender].debt;
uint balance = users[msg.sender].balance;

require(debt>0, "user has not debt");
require(balance >=debt , "user has insufficient balance");

unchecked {
    users[msg.sender].balance -= debt;
}
totalPayments += debt;
users[msg.sender].debt = 0;

emit PaymentMade(msg.sender,debt);
}

//withdrawBalance #existingUser
function withdrawBalance (uint amount) external nonReentrant {
require(isUser(msg.sender), "User does not exist");
require(amount<=users[msg.sender].balance, "You dont have money enough");

unchecked {
users[msg.sender].balance = users[msg.sender].balance - amount;
}
(bool success,) = msg.sender.call{value: amount} ("");
require(success, "Transfer failed");

emit BalanceWithdraw(msg.sender,amount);

}


//withdrawOwnerBalance #onlyOwner
function withdrawOwnerBalance (uint amount) external onlyOwner {
require(amount<=totalPayments, "You dont have money enough");
(bool success,) = owner.call{value: amount} ("");
require(success, "Transfer failed");
unchecked {
    totalPayments -= amount;
}
}


//QueryFunction
//getOwner

function getOwner () external view returns (address){
    return owner;
}

//isUser
function isUser(address walletAddress) private view returns (bool){
return users[walletAddress].walletAddress != address(0);
}


//getUser #existingUser
function getUser (address walletAddress) external view returns (User memory) {
    require(isUser(walletAddress), "User does not exist");
    return users[walletAddress];
}

//getBinbin #existingBinbin
function getBinBin (uint id) external view returns (BinBin memory) {
     require(binbins[id].id != 0, "There is not a binbin");
     return binbins[id];
}


//getStatusByBinbin
function getBinBinByStatus (uint id) external view returns (Status status) {
    return binbins[id].status;
}
//getBinBinsByStatus
function getBinBinsByStatus (Status _status) external view returns (BinBin[] memory){
    uint count = 0;
    uint length = _counter.current();
    for(uint i = 1; i<length; i++){
        if(binbins[i].status == _status) {
            count++;
        }
    }
    BinBin[] memory binbinWithStatus = new BinBin[](count);
    count = 0;
for(uint i = 1; i<length; i++){
        if(binbins[i].status == _status) {
            binbinWithStatus[count] = binbins[i];
            count++;
        }
    }

    return binbinWithStatus;
}

//calculate debt
function calculateDebt (uint usedSeconds, uint rentFee) private pure returns (uint) {
uint usedMunites = usedSeconds / 60;
return usedMunites * rentFee;
}


//getCurrentCount

function getCurrentCount() external view returns(uint) {
    return _counter.current();
}

//getContractBalance #onlyOwner
function getContractBalance () external view onlyOwner returns(uint){
return address(this).balance;
}

//getTotalPayment #onlyOwner
function getTotalPayment () external view onlyOwner returns(uint){
return totalPayments;
}

}
