const express = require('express');
const router = express.Router();


const app = express();

const port = 3000;

app.get('/', (req, res) => {
    res.json({ message: 'Aurora NFT Mint API Version 1' });
});

// POST Route to mint a new NFT
app.post("/MintNFT", async (req, res) => {
    try {
      const user = {
        name: req.body.name,
        img: req.body.img,
        ethAddress: req.body.ethAddress,
        description: req.body.description,
      };
  
      if (!user.name || !user.ethAddress || !user.img || !user.description) {
        throw "Missing required parameters.";
      }
  
      console.log("NFT Mint Request Sent!");
    } catch (err) {
      console.log(err);
      res.status(400).send({ message: err });
    }
  });
  

app.listen(port, () => console.log(`LISTNEING : ${port}!`))