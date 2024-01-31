import { BarretenbergBackend } from '@noir-lang/backend_barretenberg';
import { Noir } from '@noir-lang/noir_js';
import circuit from '../circuit/target/circuit.json';

const NETWORK_ID = process.env.CHAIN_ID

const METADA_API_URL = "http://localhost:8080"

const COMMENT_VERIFIER_ADDRESS = process.env.COMMENT_VERIFIER_ADDRESS;

const MY_CONTRACT_ABI_PATH = "../json_abi/CommentVerifier.json"
var my_contract

var accounts
var web3

function metamaskReloadCallback() {
  window.ethereum.on('accountsChanged', (accounts) => {
    document.getElementById("web3_message").textContent="Se cambió el account, refrescando...";
    window.location.reload()
  })
  window.ethereum.on('networkChanged', (accounts) => {
    document.getElementById("web3_message").textContent="Se el network, refrescando...";
    window.location.reload()
  })
}

const getWeb3 = async () => {
  return new Promise((resolve, reject) => {
    if(document.readyState=="complete")
    {
      if (window.ethereum) {
        const web3 = new Web3(window.ethereum)
        window.location.reload()
        resolve(web3)
      } else {
        reject("must install MetaMask")
        document.getElementById("web3_message").textContent="Error: Please connect to Metamask";
      }
    }else
    {
      window.addEventListener("load", async () => {
        if (window.ethereum) {
          const web3 = new Web3(window.ethereum)
          resolve(web3)
        } else {
          reject("must install MetaMask")
          document.getElementById("web3_message").textContent="Error: Please install Metamask";
        }
      });
    }
  });
};

const getContract = async (web3, address, abi_path) => {
  const response = await fetch(abi_path);
  const data = await response.json();
  
  const netId = await web3.eth.net.getId();
  var contract = new web3.eth.Contract(
    data,
    address
    );
  return contract
}

async function loadDapp() {
  metamaskReloadCallback()
  document.getElementById("web3_message").textContent="Please connect to Metamask"
  var awaitWeb3 = async function () {
    web3 = await getWeb3()
    web3.eth.net.getId((err, netId) => {
      if (netId == NETWORK_ID) {
        var awaitContract = async function () {
          my_contract = await getContract(web3, COMMENT_VERIFIER_ADDRESS, MY_CONTRACT_ABI_PATH)
          document.getElementById("web3_message").textContent="You are connected to Metamask"
          onContractInitCallback()
          web3.eth.getAccounts(function(err, _accounts){
            accounts = _accounts
            if (err != null)
            {
              console.error("An error occurred: "+err)
            } else if (accounts.length > 0)
            {
              onWalletConnectedCallback()
              document.getElementById("account_address").style.display = "block"
            } else
            {
              document.getElementById("connect_button").style.display = "block"
            }
          });
        };
        awaitContract();
      } else {
        document.getElementById("web3_message").textContent="Please connect to Scroll Sepolia";
      }
    });
  };
  awaitWeb3();
}

async function connectWallet() {
  await window.ethereum.request({ method: "eth_requestAccounts" })
  accounts = await web3.eth.getAccounts()
  onWalletConnectedCallback()
}
window.connectWallet=connectWallet;

const onContractInitCallback = async () => {
  var commentCount = await my_contract.methods.commentCount().call()
  var contract_state = "commentCount: " + commentCount
  
  var maxMsgPerPage = 5;
  var pageIterator = 0;
  var commentsElement = document.getElementById("comments");

  for(var i=parseInt(commentCount);i>0;i--)
  {
    var comment = await my_contract.methods.comments(i-1).call()
    var paragraph = document.createElement("p");
    paragraph.textContent = "- " + comment;
    commentsElement.appendChild(paragraph);
    pageIterator++
    if(pageIterator >= maxMsgPerPage)
    {
      break
    }
  }
  document.getElementById("contract_state").textContent = contract_state;
}

const onWalletConnectedCallback = async () => {
}

document.addEventListener('DOMContentLoaded', async () => {
    loadDapp()
});

function splitIntoPairs(str) {
  return str.match(/.{1,2}/g) || [];
}

const sendProof = async (comment) => {
  document.getElementById("web3_message").textContent="Please sign the message ✍️";

  const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
  await provider.send("eth_requestAccounts", []);
  const signer = provider.getSigner();
  const signderAddress = await signer.getAddress();

  const signature = await signer.signMessage(comment);
  var hashedMessage = ethers.utils.hashMessage(comment)
  var publicKey = ethers.utils.recoverPublicKey(
    hashedMessage,
    signature)

  publicKey = publicKey.substring(4)

  let pub_key_x = publicKey.substring(0, 64);
  let pub_key_y = publicKey.substring(64);
  
  var sSignature = Array.from(ethers.utils.arrayify(signature))
  sSignature.pop()
  
  const backend = new BarretenbergBackend(circuit);
  const noir = new Noir(circuit, backend);

  let merkleTree = [
    {
      value: "0x707e55a12557E89915D121932F83dEeEf09E5d70",
      index: "0",
      hashPath: ["0x000000000000000000000000bef34f2FCAe62dC3404c3d01AF65a7784c9c4A19","0x00000000000000000000000008966BfFa14A7d0d7751355C84273Bb2eaF20FC3"],
    },
    {
      value: "0xbef34f2FCAe62dC3404c3d01AF65a7784c9c4A19",
      index: "1",
      hashPath: ["0x000000000000000000000000707e55a12557E89915D121932F83dEeEf09E5d70","0x00000000000000000000000008966BfFa14A7d0d7751355C84273Bb2eaF20FC3"],
    },
    {
      value: "0x08966BfFa14A7d0d7751355C84273Bb2eaF20FC3",
      index: "2",
      hashPath: ["0x00000000000000000000000008966BfFa14A7d0d7751355C84273Bb2eaF20FC3","0x1476e5c502f3a532e7c36640e88eebf769ae99d6c50f3be65279ca937b795a3d"],
    }
  ]

  let index = null
  let hashPath = null
  for(let i=0; i<merkleTree.length; i++) {
    if(merkleTree[i].value == signderAddress) {
      index = merkleTree[i].index
      hashPath = merkleTree[i].hashPath
    }
  }
  if(index == null || index == hashPath) {
    console.log("Could not find the signer on the merkle tree")
    return;
  }

  console.log(index)
  console.log(hashPath)
  
  const input = {
    hash_path: hashPath,
    index: index,
    root: "0x2a550743aa7151b3324482a03b2961ec4b038672a701f8ad0051b2c9d2e6c4c0",
    pub_key_x: Array.from(ethers.utils.arrayify("0x"+pub_key_x)),
    pub_key_y: Array.from(ethers.utils.arrayify("0x"+pub_key_y)),
    signature: sSignature,
    hashed_message: Array.from(ethers.utils.arrayify(hashedMessage))
  };

  document.getElementById("web3_message").textContent="Generating proof... ⌛";
  var proof = await noir.generateFinalProof(input);
  document.getElementById("web3_message").textContent="Generating proof... ✅";
  
  proof = "0x" + ethereumjs.Buffer.Buffer.from(proof.proof).toString('hex')

  var tHashedMessage = splitIntoPairs(hashedMessage.substring(2))

  for(var i=0; i<tHashedMessage.length; i++)
  {
    tHashedMessage[i] = "0x00000000000000000000000000000000000000000000000000000000000000" + tHashedMessage[i]
  }

  tHashedMessage.push("0x2a550743aa7151b3324482a03b2961ec4b038672a701f8ad0051b2c9d2e6c4c0")

  console.log("tHashedMessage2")
  console.log(tHashedMessage)


  await updateMetadata(proof, tHashedMessage, comment)

  /*
  const result = await my_contract.methods.sendProof(proof, tHashedMessage, title, text)
  .send({ from: accounts[0], gas: 0, value: 0 })
  .on('transactionHash', function(hash){
    document.getElementById("web3_message").textContent="Executing...";
  })
  .on('receipt', function(receipt){
    document.getElementById("web3_message").textContent="Success.";    })
  .catch((revertReason) => {
    console.log("ERROR! Transaction reverted: " + revertReason.receipt.transactionHash)
  });
  */


}

const updateMetadata = async (proof, hashedMessage, comment) => {
  fetch(METADA_API_URL + "/relay?proof=" + proof + "&hashedMessage=" + hashedMessage + "&comment=" + comment)
  .then(res => res.json())
  .then(out =>
    console.log(out))
  .catch();
}


window.sendProof=sendProof;