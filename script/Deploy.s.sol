// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";

/// @notice Deploys Vault with msg.sender (the deployer key) set as owner,
/// holding the USDT token at USDT_ADDRESS.
/// Usage:
///   forge script script/Deploy.s.sol:Deploy --rpc-url $POLYGON_RPC_URL --broadcast --verify -vvvv
contract Deploy is Script {
    // (PoS) Tether USD on Polygon — https://polygonscan.com/token/0xc2132D05D31c914a87C6611C10748AEb04B58e8F
    address constant USDT_ADDRESS = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    function run() external returns (Vault vault) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);
        vault = new Vault(deployer, USDT_ADDRESS);
        vm.stopBroadcast();

        console.log("Vault deployed at:", address(vault));
        console.log("Owner:", deployer);
        console.log("Token (USDT):", USDT_ADDRESS);
    }
}
