-include .env

hookFileName=BalanceOfConditionalCash
deploy:
	forge compile --optimizer-runs ${optimizer_runs}

	set -e ; \
	registrarAddress=$$(cat salts/registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	constructorArgs=$$(cast abi-encode "constructor(address)" $${registrarAddress}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	echo "Constructor Args: "$${constructorArgs} ; \
	bytecode=$$(jq -r '.bytecode.object' out/$(hookFileName).sol/$(hookFileName).json)$${constructorArgs} ; \
	echo $${bytecode} ; \
	echo "Bytecode Formatted.." ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee salts/$(hookFileName).txt ; \
	echo "\n\n" ; \
	salt=$$(cat salts/$(hookFileName).txt | grep "Salt: " | awk '{print $$2}') ; \
	hookAddress=$$(cat salts/$(hookFileName).txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} --gas-price 90000000000; \
	echo "Address deployed on blockchain.\nVerifying...\n\n" ; \
	sleep 10 ; \
	forge verify-contract --compiler-version v0.8.20+commit.a1b79de6 --num-of-optimizations ${optimizer_runs} --watch \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	--constructor-args $${constructorArgs} \
	$${hookAddress} \
	src/$(hookFileName).sol:$(hookFileName) ; \
	echo "Contract verified."