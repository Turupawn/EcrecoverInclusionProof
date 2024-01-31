import dotenv from "dotenv"
import fs from "fs"
import cors from "cors"
import express from "express"
import { ethers } from 'ethers';

const app = express()
dotenv.config();
app.use(cors())

const JSON_CONTRACT_PATH = "./json_abi/CommentVerifier.json"
const PORT = 8080
var contract
var provider
var signer

const { RPC_URL, COMMENT_VERIFIER_ADDRESS, RELAYER_PRIVATE_KEY, RELAYER_ADDRESS } = process.env;

const loadContract = async (data) => {
  data = JSON.parse(data);
  contract = new ethers.Contract(COMMENT_VERIFIER_ADDRESS, data, signer);
}

async function initAPI() {
  provider = new ethers.JsonRpcProvider(RPC_URL);
  signer = new ethers.Wallet(RELAYER_PRIVATE_KEY, provider);

  fs.readFile(JSON_CONTRACT_PATH, 'utf8', function (err,data) {
    if (err) {
      return console.log(err);
    }
    loadContract(data)
  });

  app.listen(PORT, () => {
    console.log(`Listening to port ${PORT}`)
  })
}

async function relayMessage(proof, hashedMessage, comment)
{
  const transaction = {
    from: RELAYER_ADDRESS,
    to: COMMENT_VERIFIER_ADDRESS,
    value: '0',
    gasPrice: "700000000", // 0.7 gwei
    nonce: await provider.getTransactionCount(RELAYER_ADDRESS),
    chainId: "534351",
    data: contract.interface.encodeFunctionData(
      "sendProof",[proof, hashedMessage, comment]
    )
  };
  const signedTransaction = await signer.populateTransaction(transaction);
  const transactionResponse = await signer.sendTransaction(signedTransaction);
  console.log('🎉 The hash of your transaction is:', transactionResponse.hash);
}

app.get('/relay', (req, res) => {
  var proof = req.query["proof"]
  var hashedMessage = req.query["hashedMessage"].split(',')
  var comment = req.query["comment"]

  relayMessage(proof, hashedMessage, comment)

  res.setHeader('Content-Type', 'application/json');
  res.send({
    "message": "the proof was relayed"
  })
})
initAPI()