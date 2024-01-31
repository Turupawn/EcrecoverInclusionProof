# On-chain Privacy DApp Demo

This demo showcases all the parts needed to create a privacy preserving DApp with good UX which are:
* A circuit
* A smart contract
* A relayer
* A webapp

On this example we do a simple anonymous message board but it can be extended for other DApps in other fields such as DeFi, voting & governance, identity, etc..

![Privacy zkDApp screenshot](https://raw.githubusercontent.com/Turupawn/PrivacyDAppDemo/master/screenshot.png)

## ⭐Features

| Feature | Supported |
|----------|------------ |
| Aztec Noir circuit | ✅ |
| Solidity verifier | ✅ |
| ECDSA verification circuit | ✅ |
| EIP712 enabled | ✅ |
| Prover on browser (WASM) | ✅ |
| Ethers.js 6.9 relayer | ✅ |
| MIT license | ✅ |

## 🚀How to launch

### Step 1. Generate and deploy the Solidity verifier

Make sure you installed Nargo `0.22.0` as detailed below:

<details>
<summary>On Linux</summary>
  
```bash
mkdir -p $HOME/.nargo/bin && \
curl -o $HOME/.nargo/bin/nargo-x86_64-unknown-linux-gnu.tar.gz -L https://github.com/noir-lang/noir/releases/download/v0.22.0/nargo-x86_64-unknown-linux-gnu.tar.gz && \
tar -xvf $HOME/.nargo/bin/nargo-x86_64-unknown-linux-gnu.tar.gz -C $HOME/.nargo/bin/ && \
echo 'export PATH=$PATH:$HOME/.nargo/bin' >> ~/.bashrc && \
source ~/.bashrc
```
</details>

<details>
<summary>On MAC</summary>
  
```bash
mkdir -p $HOME/.nargo/bin && \
curl -o $HOME/.nargo/bin/nargo-x86_64-apple-darwin.tar.gz -L https://github.com/noir-lang/noir/releases/download/v0.22.0/nargo-x86_64-apple-darwin.tar.gz && \
tar -xvf $HOME/.nargo/bin/nargo-x86_64-apple-darwin.tar.gz -C $HOME/.nargo/bin/ && \
echo '\nexport PATH=$PATH:$HOME/.nargo/bin' >> ~/.zshrc && \
source ~/.zshrc
```
</details>

Now generate the Solidity verifier.

```bash
cd circuit
nargo codegen-verifier
```

This will generate a Solidity file located at `circuit/contract/circuit/plonk_vk.sol`. Deploy it on an EVM on-chain.

### Step 2. Deploy the verifier contract

Now deploy the `CommentVerifier` contract located at `contracts/CommentVerifier.sol`. Pass the Verifier contract you just generated as constructor parameter.

### Step 3. Launch the Relayer

Let's launch the relayer first. Fill the `.env` file based on `.env.example` on the `relayer/` directory and run the following.

```bash
cd relayer
npm install
npm start
```

### Setp 4. Launch the webapp and verify a  proof

Open a new terminal and launch the webapp. Now fill the `.env` file based on `.env.example` on the `webapp/`, the run the following.

```bash
cd webapp
npm install
npm start
```

The webapp will automatically open on your browser. Now you will be able to generate proofs on your browser and send them to the relayer for on-chain verification.

## ⚠️Known issues (PRs welcome)

* We need to compress the hashed message params to reduce L1 fees on L2s. We should use [this](https://github.com/Bank-of-JubJub/base/blob/2a0247a441463a6619cc8d5f13d81717d166b770/hardhat/contracts/UsingAccountControllers.sol#L158) and [this](https://github.com/Bank-of-JubJub/base/blob/master/circuits/change_eth_signer/src/main.nr)
