

## To test this smart contract, you can use a json-rpc provider &  foundry to fork mainnet : 

```
FORK_URL=http://-your-alchemy/infura-rpc-url-endpoint

forge test --fork-url $FORK_URL  --match-path test/UniswapV2FlashSwap.test.sol  -vvv

```