#!/bin/sh

geth --testnet attach << EOF

loadScript('contractInfo.js');


console.log(JSON.stringify(nftContract.symbol()));

var deployer = eth.accounts[1];
// var owner = "0x07fb31ff47Dc15f78C5261EEb3D711fb6eA985D1";
var owner = deployer;
console.log("Deployer " + deployer + " has balance " + eth.getBalance(deployer).shift(-18));

if (true) {
  // Mint one
  var mint1Tx = nftContract.mint(owner, "avatar", "Princess", "Princess Leia Peach Rainbow Vomit Cat", {from: deployer, gas: 2000000});
  console.log(JSON.stringify(eth.getTransaction(mint1Tx)));
  while (eth.getTransactionReceipt(mint1Tx) == null) {
  }
  console.log(JSON.stringify(eth.getTransactionReceipt(mint1Tx)));
}

// Get last minted
var tokens = nftContract.balanceOf(owner);
console.log("Last minted tokens: " + tokens);

// Last minted tokenId
if (tokens > 0) {
  var tokenId = nftContract.tokenOfOwnerByIndex(owner, tokens - 1);
  console.log("tokenId of last minted token: " + tokenId);
}


if (true) {
  var addURI1Tx = nftContract.addAttribute(tokenId, "uri", "https://placekitten.com/300/300", {from: deployer, gas: 2000000});
  console.log(JSON.stringify(eth.getTransaction(addURI1Tx)));
  while (eth.getTransactionReceipt(addURI1Tx) == null) {
  }
  console.log(JSON.stringify(eth.getTransactionReceipt(addURI1Tx)));
}

if (true) {
  var location = {
    space: "2",
    tr: {
      pos: { x: 1, y: 2, z: 3 },
      rot: { x: 1, y: 2, z: 3 },
      scl: { x: 1, y: 2, z: 3 },
    }
  };
  console.log(JSON.stringify(location));
  var addLocation1Tx = nftContract.addAttribute(tokenId, "location", JSON.stringify(location), {from: deployer, gas: 2000000});
  console.log(JSON.stringify(eth.getTransaction(addLocation1Tx)));
  while (eth.getTransactionReceipt(addLocation1Tx) == null) {
  }
  console.log(JSON.stringify(eth.getTransactionReceipt(addLocation1Tx)));
}

EOF
