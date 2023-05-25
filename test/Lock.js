const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

const BinBin = artifacts.require("BinBins");

contract("BinBins", accounts => {
let binbin;
const owner = accounts[0];
const user1 = accounts[1];

beforeEach(async()=>{
  binbin = await BinBin.new();
})

describe("Add user and car", () => {
it("adds new user", async()=>{
await binbin.addUser("Berkay", "Zincir",{from:user1});
const user = await binbin.getUser(user1);
assert.equal(user.name,"Berkay", "there is a error on name");
assert.equal(user.lastname,"Zincir", "there is a error on surname");

it("add new binbin", async()=>{
  const url = "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.binbin.tech%2F&psig=AOvVaw3C0Tjvp48W1PK8-nDeOKmc&ust=1684854754803000&source=images&cd=vfe&ved=0CBEQjRxqFwoTCNiYrZubif8CFQAAAAAdAAAAABAr";
await binbin.addBinBin("Binbin Bike", url,"5","500000",{from:owner})
const binbin = await binbin.getBinbin(1);
assert.equal(binbin.name,"Binbin Bike","there is a error on name" );
assert.equal(binbin.imgURL,url, "there is a error on URL");
assert.equal(binbin.rentFee,5, "there is a error on rentFee");
assert.equal(binbin.saleFee,500000, "there is a error on saleFee");
})})})
 

describe("check Out and Check In", ()=>{
it("check out test", async()=>{
  await binbin.addUser("Berkay", "Zincir",{from:user1});
  await binbin.addBinBin("Binbin Bike","url","5","500000",{from:owner})
  await binbin.checkOut(1, {from:user1})
  const user = await binbin.getUser(user1);
  assert.equal(user.rentedBinBinId,1,"There is a error on check out");
})

it("check in test", async()=>{
  await binbin.addUser("Berkay", "Zincir",{from:user1});
  await binbin.addBinBin("Binbin Bike", "url","5","500000",{from:owner})
  await binbin.checkOut(1, {from:user1})
  await new Promise((resolve)=> setTimeout(resolve,20000)); //5 seconds
  await binbin.checkIn({from:user1});
  const user = await binbin.getUser(user1);
  assert.equal(user.rentedBinBinId,0, "User coult not chech in the car");
  assert.equal(user.debt,0,"There is a error on dept calculate");
})
})

describe("deposit and make payment",()=>{
it("deposit check",async()=>{
  await binbin.addUser("Berkay", "Zincir",{from:user1});
  await binbin.deposit({from: user1, value:100});
  const user = await binbin.getUser(user1);
  assert.equal(user.balance,100, "There is a error on deposit");

it("make payment check", async()=>{
  await binbin.addUser("Berkay", "Zincir",{from:user1});
  await binbin.addBinBin("Binbin Bike", url,"5","500000",{from:owner})
  await binbin.checkOut(1, {from:user1})
  await new Promise((resolve)=> setTimeout(resolve,40000)); //5 seconds
  await binbin.checkIn({from:user1});
  await binbin.deposit({from: user1, value:5});
  await binbin.makePayment({from:user1})
  const user = await binbin.getUser(user1);
  assert.equal(user.debt,0,"there is a error on payment check");
});
});
});

describe("edit binbin", () => {
  it("edit binbin", async () => {
    await binbin.addBinBin("Binbin1", "exampleurl", 100, 2, {
      from: owner,
    });
    const newName = "Binbin2";
    const newUrl = "exampleurl2";
    const newRent = 20;
    const newSaleFee = 100000;
    await binbin.editBinBinMetaData(
      1,
      newName,
      newUrl,
      newRent,
      newSaleFee,
      { from: owner }
    );

    const binbins = await binbin.getBinBin(1);
    assert.equal(binbins.name, newName, "binbin name is not correct");
    assert.equal(binbins.imgURL, newUrl, "binbin url is not correct");
    assert.equal(binbins.rentFee, newRent, "binbin rent is not correct");
    assert.equal(binbins.saleFee, newSaleFee, "binbin sale is not correct");
  });

  it("edit an existing binbin's status", async () => {
    await binbin.addBinBin("binbin1", "exampleurl", 100, 2, {
      from: owner,
    });
    const newStatus = 0;
    await binbin.editStatus(1, newStatus, { from: owner });
    const binbins = await binbin.getBinBin(1);
    assert.equal(binbins.status, newStatus, "Binbin status is not correct");
  });
});

describe("withdraw balance", async()=>{
it("to the user",async()=>{
  await binbin.addUser("Berkay", "Zincir",{from:user1});
  await binbin.deposit({from:user1, value:100});
  await binbin.withdrawBalance(50,{from:user1});
  const user = await binbin.getUser(user1);
  assert.equal(user.balance,50,"there is a error on withdraw ")
});
})
});
