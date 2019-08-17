#!/bin/sh

scripts/solidityFlattener.pl --contractsdir=contracts --mainsol=GazeCoinGoobers.sol --outputsol=flattened/GazeCoinGoobers_flattened.sol --verbose --remapdir "contracts/zeppelin-solidity/contracts=openzeppelin230"
