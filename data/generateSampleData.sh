#!/bin/sh

geth --testnet attach << EOF

loadScript('contractInfo.js');


console.log(JSON.stringify(nftContract.symbol()));

var deployer = eth.accounts[1];
// var owner = "0x07fb31ff47Dc15f78C5261EEb3D711fb6eA985D1";
var owner = deployer;
var gasPrice = web3.toWei(10, "gwei");
console.log("Deployer " + deployer + " has balance " + eth.getBalance(deployer).shift(-18));

if (false) {
  if (true) {
    // Mint one
    var mint1Tx = nftContract.mint(deployer, "avatar", "Princess", "Princess Leia Peach Rainbow Vomit Cat", {from: deployer, gas: 500000, gasPrice: gasPrice});
    console.log(JSON.stringify(eth.getTransaction(mint1Tx)));
    while (eth.getTransactionReceipt(mint1Tx) == null) {
    }
    console.log(JSON.stringify(eth.getTransactionReceipt(mint1Tx)));
  }

  // Get last minted
  var tokens = nftContract.balanceOf(deployer);
  console.log("Last minted tokens: " + tokens);

  // Last minted tokenId
  if (tokens > 0) {
    var tokenId = nftContract.tokenOfOwnerByIndex(deployer, tokens - 1);
    console.log("tokenId of last minted token: " + tokenId);
  }


  if (true) {
    var addURI1Tx = nftContract.addAttribute(tokenId, "uri", "https://placekitten.com/300/300", {from: deployer, gas: 500000, gasPrice: gasPrice});
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
    var addLocation1Tx = nftContract.addAttribute(tokenId, "location", JSON.stringify(location), {from: deployer, gas: 500000, gasPrice: gasPrice});
    console.log(JSON.stringify(eth.getTransaction(addLocation1Tx)));
    while (eth.getTransactionReceipt(addLocation1Tx) == null) {
    }
    console.log(JSON.stringify(eth.getTransactionReceipt(addLocation1Tx)));
  }
}

// SpaceTemplate
if (true) {
  if (false) {
    // Mint one
    var mint1Tx = nftContract.mint(deployer, "space_template", "SpaceTemplate#0000001", "SpaceTemplate #0000001", {from: deployer, gas: 500000, gasPrice: gasPrice});
    console.log(JSON.stringify(eth.getTransaction(mint1Tx)));
    while (eth.getTransactionReceipt(mint1Tx) == null) {
    }
    console.log(JSON.stringify(eth.getTransactionReceipt(mint1Tx)));
  }

  // Get last minted
  var tokens = nftContract.balanceOf(deployer);
  console.log("Last minted tokens: " + tokens);

  // Last minted tokenId
  if (tokens > 0) {
    var tokenId = nftContract.tokenOfOwnerByIndex(deployer, tokens - 1);
    console.log("tokenId of last minted token: " + tokenId);
  }


  if (true) {
    var spaceTemplate = {
      entities: [
        {
          "id": "earnable_media_panel_1",
          "name": "Advertisement Media Panel 1",  /// Open Sea standard
          "description": "Default description",   /// Open Sea standard
          "tr": {
              "pos": {"x": -1.6, "y": 1.6,  "z": 0.5},
              "rot": {"x":  0.0, "y": 90.0, "z": 0.0},
              "scl": {"x":  1.0, "y": 1.0,  "z": 1.0}
          },
          "extra_properties": [
            {
              "type": "advert_media",
              "value": {
                "uri": "https://gazecoin-metaverse-prototype-static.s3-ap-southeast-2.amazonaws.com/media/denzel_sidechain_2d_lowres_preview.mp4",
                "media_type": "video",
                "is_live_stream": false,
                "projection_mode": "planar",
                "duration": -1
              }
            }
          ],
        },
        {
          "id": "vip_media_panel_1",
          "name": "Vip Media Panel 1",
          "description": "Default description",
          "tr": {
            "pos": {"x": -1.6, "y": 1.6,  "z": 1.8},
            "rot": {"x": 0.0,  "y": 90.0, "z": 0.0},
            "scl": {"x": 1.0,  "y": 1.0,  "z": 1.0}
          },
          "extra_properties": [
            {
              "type": "preview_media",
              "value": {
                "uri": "https://gazecoin-metaverse-prototype-static.s3-ap-southeast-2.amazonaws.com/media/scene3a_dance_2d_lowres_preview.mp4",
                "media_type": "video",
                "is_live_stream": false,
                "projection_mode": "planar",
                "duration": 36.0
              }
            },
            {
              "type": "premium_media", /// VIP Media
              "value": {
                "uri": "https://gazecoin-metaverse-prototype-static.s3-ap-southeast-2.amazonaws.com/media/scene3a_dance_360_hires_full.mp4",
                "media_type": "video",
                "is_live_stream": false,
                "projection_mode": "pano_360",
                "duration": -1
              }
            }
          ]
        }
      ],
    };
    console.log(JSON.stringify(spaceTemplate));
    var addLocation1Tx = nftContract.addAttribute(tokenId, "template", JSON.stringify(spaceTemplate), {from: deployer, gas: 1000000, gasPrice: gasPrice});
    console.log(JSON.stringify(eth.getTransaction(addLocation1Tx)));
    while (eth.getTransactionReceipt(addLocation1Tx) == null) {
    }
    console.log(JSON.stringify(eth.getTransactionReceipt(addLocation1Tx)));
  }
}


EOF
