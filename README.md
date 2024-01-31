Message board with limited anonymity set.

# On-chain Privacy DApp Demo using inclusion proofs

This demo showcases all the parts needed to create a privacy preserving DApp with good UX which are:
* A circuit
* A smart contract
* A relayer
* A webapp

## ⭐Features

| Feature | Supported |
|----------|------------ |
| Aztec Noir circuit | ✅ |
| Solidity verifier | ✅ |
| ECDSA verification circuit | ✅ |
| Merkle tree membership proof | ✅ |
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

### Before you continue

Make sure you generate your anonymity set. Usually you may want to generate them on a library provided by Aztec that has the implementation of Pedersen hashing method that matches their prover library. However that library has not been released yet. So for the sake of compatibility we'll use the following circuit to print the merkle tree.

```
use dep::std::ecdsa_secp256k1::verify_signature;
use dep::std;
use dep::std::scalar_mul;
use dep::std::hash;

fn main(index : Field,
  leafLeft: Field,
  leafRight: Field
) {
    let root = std::merkle::compute_merkle_root(leafLeft, index, [leafRight]);
    std::println(root);
}
```

In this example we'll use the following merkle tree with a few ethereum accounts I control. When you generate your own merkle tree make sure to update the `sendProof` function on the `app.js` file. And also, when you launch your `CommentVerifier` contract pass as paramater your merkle root.

```
└─ 0x2a550743aa7151b3324482a03b2961ec4b038672a701f8ad0051b2c9d2e6c4c0
   ├─ 0x1476e5c502f3a532e7c36640e88eebf769ae99d6c50f3be65279ca937b795a3d
   │  ├─ 0x000000000000000000000000707e55a12557E89915D121932F83dEeEf09E5d70
   │  └─ 0x000000000000000000000000bef34f2FCAe62dC3404c3d01AF65a7784c9c4A19
   └─ 0x00000000000000000000000008966BfFa14A7d0d7751355C84273Bb2eaF20FC3
      └─ 0x00000000000000000000000008966BfFa14A7d0d7751355C84273Bb2eaF20FC3
```

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

* This demo uses normal wallet signatures hence proofs are not nullifiable. See [plume](https://github.com/plume-sig/zk-nullifier-sig)