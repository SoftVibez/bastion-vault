// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";

/// @notice Deploys Vault with msg.sender (the deployer key) set as owner.
/// Usage:
///   forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify -vvvv
contract Deploy is Script {
    function run() external returns (Vault vault) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);
        vault = new Vault(deployer);
        vm.stopBroadcast();

        console.log("Vault deployed at:", address(vault));
        console.log("Owner:", deployer);
    }
}
