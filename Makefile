-include .env
FACTORY_ADDRESS=0x0000000000FFe8B47B3e2130213B802212439497
DEPLOY_RPC_URL=${POLYGON_RPC_URL}
VERIFIER_URL=https://api.polygonscan.com/api/# https://api-sepolia.etherscan.io/api
optimizer_runs=1000000
registrarAddress=0x00000000d6903Acf970564473F1b072c8df5Af7d

ADDRESS_LOCAL=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PRIVATE_KEY_LOCAL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
FACTORY_ADDRESS_LOCAL=0x5FbDB2315678afecb367f032d93F642f64180aa3
DEPLOY_RPC_URL_LOCAL=127.0.0.1:8545
registrarLocal=0x00000b840759d2BC57F1C81b7658C540b820DE29

hookFileName=SimpleCash
deploy-local:
	constructorArgs=$$(cast abi-encode "constructor(address)" ${registrarLocal}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/$(hookFileName).sol/$(hookFileName).json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS_LOCAL} --init-code $${bytecode} --starts-with 000 --caller ${ADDRESS_LOCAL} 2>&1 | tee salts/$(hookFileName).salt.txt ; \
	salt=$$(cat salts/$(hookFileName).salt.txt | grep "Salt: " | awk '{print $$2}') ; \
	hookAddress=$$(cat salts/$(hookFileName).salt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS_LOCAL} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} ;

# No salt mining
deploy-local-simple:
	forge create contracts/hooks/${hookFileName}.sol:${hookFileName} --broadcast --private-key ${PRIVATE_KEY_LOCAL} --optimizer-runs ${optimizer_runs} --constructor-args ${registrarLocal} --rpc-url ${DEPLOY_RPC_URL_LOCAL};

# $$(cast abi-encode "f(string,string,string,string)" "test1" "test2" "test3" "test4");

writeSelector="write(address,uint256,uint256,address,address,bytes)"
currency=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
escrow=100
instant=0
owner=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
hook=0x000666c6e79cb1895D00E19f9Ed57F7a74913536
write-local:
	cast send ${currency} "mint(address,uint256)" ${ADDRESS_LOCAL} ${escrow} --private-key ${PRIVATE_KEY_LOCAL} -- --broadcast --rpc-url ${DEPLOY_RPC_URL_LOCAL}; \
	cast send ${currency} "approve(address,uint256)" ${registrarLocal} ${escrow} --private-key ${PRIVATE_KEY_LOCAL} -- --broadcast --rpc-url ${DEPLOY_RPC_URL_LOCAL}; 
	hookData=$$(cast abi-encode "write(string,string,string,string)" "test1" "test2" "test3" "test4"); \
	cast send ${registrarLocal} ${writeSelector} ${currency} ${escrow} ${instant} ${owner} ${hook} $${hookData} --private-key ${PRIVATE_KEY_LOCAL} -- --broadcast --rpc-url ${DEPLOY_RPC_URL_LOCAL};

######################################################################################################################################################
#    																	Mainnet																		 #	
######################################################################################################################################################
hookFileName=SimpleCash
deploy:
	forge build --optimizer-runs ${optimizer_runs} --use 0.8.24

	constructorArgs=$$(cast abi-encode "constructor(address)" ${registrarAddress}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	echo "Constructor Args: "$${constructorArgs} ; \
	bytecode=$$(jq -r '.bytecode.object' out/$(hookFileName).sol/$(hookFileName).json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 000000 --caller ${ADDRESS} 2>&1 | tee salts/$(hookFileName).salt.txt ; \
	echo "\n\n" ; \
	salt=$$(cat salts/$(hookFileName).salt.txt | grep "Salt: " | awk '{print $$2}') ; \
	hookAddress=$$(cat salts/$(hookFileName).salt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} --gas-price 90000000000; \
	echo "Address deployed on blockchain.\nVerifying...\n\n" ; \
	sleep 10 ; \
	forge verify-contract --compiler-version v0.8.24 --num-of-optimizations ${optimizer_runs} --watch \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	--constructor-args $${constructorArgs} \
	$${hookAddress} \
	contracts/hooks/$(hookFileName).sol:$(hookFileName) ; \
	echo "Contract verified."

verify:
	hookAddress=$$(cat salts/$(hookFileName).salt.txt | grep "Address: " | awk '{print $$2}') ; \
	forge verify-contract \
	--constructor-args 00000000000000000000000000000000d6903acf970564473f1b072c8df5af7d \
	--compiler-version v0.8.24 --num-of-optimizations ${optimizer_runs} --watch \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	$${hookAddress} \
	contracts/hooks/$(hookFileName).sol:$(hookFileName);

# single quotes
# attributes=",{'trait_type':'Proof of Work','value':'True'},{'trait_type':'Consensus Role','value':'Validator'},{'trait_type':'Governance Power','display_type':'number','value':'100'},{'trait_type':'Trust Score','display_type':'number','value':'95'},{'trait_type':'Reputation Level','value':'Diamond Hand'},{'trait_type':'Community Role','value':'Core Contributor'},{'trait_type':'DAO Membership','value':'Active'},{'trait_type':'Protocol Access Level','value':'Alpha'},{'trait_type':'Verification Status','value':'Fully Verified'}"
# keyValues=",'description':'Trusted validator with proven track record in protocol governance','external_url':'https://polygonscan.com/address/0x000c3F29102f404E9FAdb91B2912dfd62Ff58F9A','proof_hash':'0x123...','signature':'0x456...','image':'ipfs://QmZggzufh74uDrvzGDzGeepkiwxahuNodo8XJVr32Dgc3S','social_graph':{'followers':1000,'following':500,'influence_score':85},'governance_stats':{'proposals_created':12,'votes_cast':156,'delegation_power':10000},'verification_proofs':{'kyc':'verified','identity':'verified','funds':'verified'},'contribution_history':{'commits':235,'reviews':189,'bounties':45},'community_badges':['early_adopter','core_contributor','governance_participant']"
# double quotes (JSON compliant but doesn't work)
# attributes=',{"trait_type":"Proof of Work","value":"True"},{"trait_type":"Consensus Role","value":"Validator"},{"trait_type":"Governance Power","display_type":"number","value":"100"},{"trait_type":"Trust Score","display_type":"number","value":"95"},{"trait_type":"Reputation Level","value":"Diamond Hand"},{"trait_type":"Community Role","value":"Core Contributor"},{"trait_type":"DAO Membership","value":"Active"},{"trait_type":"Protocol Access Level","value":"Alpha"},{"trait_type":"Verification Status","value":"Fully Verified"}'
# keyValues=',"description":"Trusted validator with proven track record in protocol governance","external_url":"https://polygonscan.com/address/0x000c3F29102f404E9FAdb91B2912dfd62Ff58F9A","proof_hash":"0x123...","signature":"0x456...","image":"ipfs://QmZggzufh74uDrvzGDzGeepkiwxahuNodo8XJVr32Dgc3S","social_graph":{"followers":1000,"following":500,"influence_score":85},"governance_stats":{"proposals_created":12,"votes_cast":156,"delegation_power":10000},"verification_proofs":{"kyc":"verified","identity":"verified","funds":"verified"},"contribution_history":{"commits":235,"reviews":189,"bounties":45},"community_badges":["early_adopter","core_contributor","governance_participant"]'
# hookData=$$(cast abi-encode "write(string,string)" ${attributes} ${keyValues})
# # hookData="0x0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000002072c7b2774726169745f74797065273a2750726f6f66206f6620576f726b272c2776616c7565273a2754727565277d2c7b2774726169745f74797065273a27436f6e73656e73757320526f6c65272c2776616c7565273a2756616c696461746f72277d2c7b2774726169745f74797065273a27476f7665726e616e636520506f776572272c27646973706c61795f74797065273a276e756d626572272c2776616c7565273a27313030277d272c7b2774726169745f74797065273a2754727573742053636f7265272c27646973706c61795f74797065273a276e756d626572272c2776616c7565273a273935277d2c7b2774726169745f74797065273a2752657075746174696f6e204c6576656c272c2776616c7565273a274469616d6f6e642048616e64277d2c7b2774726169745f74797065273a27436f6d6d756e69747920526f6c65272c2776616c7565273a27436f726520436f6e7472696275746f72277d2c7b2774726169745f74797065273a2744414f204d656d62657273686970272c2776616c7565273a27416374697665277d2c7b2774726169745f74797065273a2750726f746f636f6c20416363657373204c6576656c272c2776616c7565273a27416c706861277d2c7b2774726169745f74797065273a27566572696669636174696f6e20537461747573272c2776616c7565273a2746756c6c79205665726966696564277d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024f2c276465736372697074696f6e273a27547275737465642076616c696461746f7220776974682070726f76656e20747261636b207265636f726420696e2070726f746f636f6c20676f7665726e616e6365272c2765787465726e616c5f75726c273a2768747470733a2f2f65746865727363616e2e696f2f616464726573732f30782e2e2e272c2770726f6f665f68617368273a2730783132332e2e2e272c277369676e6174757265273a2730783435362e2e2e272c27697066735f636f6e74656e74273a27516d2e2e2e272c27736f6369616c5f6772617068273a7b27666f6c6c6f77657273273a313030302c27666f6c6c6f77696e67273a3530302c27696e666c75656e63655f73636f7265273a38357d2c27676f7665726e616e63655f7374617473273a7b2770726f706f73616c735f63726561746564273a31322c27766f7465735f63617374273a3135362c2764656c65676174696f6e5f706f776572273a31303030307d2c27766572696669636174696f6e5f70726f6f6673273a7b276b7963273a277665726966696564272c276964656e74697479273a277665726966696564272c2766756e6473273a277665726966696564277d2c27636f6e747269627574696f6e5f686973746f7279273a7b27636f6d6d697473273a3233352c2772657669657773273a3138392c27626f756e74696573273a34357d2c27636f6d6d756e6974795f626164676573273a5b276561726c795f61646f70746572272c27636f72655f636f6e7472696275746f72272c27676f7665726e616e63655f7061727469636970616e74275d0000000000000000000000000000000000"
# write-local:
# 	echo "" ; \
#     cast send ${registrarLocal} ${writeSelector} ${currency} ${escrow} ${instant} ${owner} ${hook} "${hookData}" --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} -- --broadcast;

# currency=0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 # deployed token address
# escrow=0
# instant=1
# owner=${ADDRESS}
# hook=0x0000000D19464521F1e7D591c2e3e619EbBf60EC
# hookData=$$(cast abi-encode "write(string,string,string,string)" "test" "test2" "test3" "test4")
# # Need to add instant and escrow to approve total amount
# write:
# 	cast send ${currency} "approve(address,uint256)" ${registrarAddress} ${instant} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
# 	cast send ${registrarAddress} ${writeSelector} ${currency} ${escrow} ${instant} ${owner} ${hook} ${hookData} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ;
