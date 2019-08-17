#!/bin/sh

scripts/solidityFlattener.pl --contractsdir=contracts --mainsol=GazeCoinGoobers.sol --verbose --remapdir "contracts/zeppelin-solidity/contracts=openzeppelin230"
