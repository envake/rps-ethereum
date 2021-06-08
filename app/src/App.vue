<template>
  <div class="info">{{ addressInfo }}</div>
  <!--<div class="left">Player 1 address: {{ player1Address }} </div>
  <div class="left">Player 2 address: {{ player2Address }} </div>
  
  <div class="left">Secret: {{ secret }} </div>-->
  <h1>ROCK PAPER SCISSORS</h1>
  <h4>on Ethereum</h4>
  <div class="app">
    <start v-if="showStart" @start="start"></start>
    <commit v-if="showCommit" @commit-choice="commit"></commit>
    <reveal v-if="showReveal" @reveal-choice="reveal"></reveal>
    <end v-if="showEnd" v-bind:result=result @payout-game="payout"></end>
    <wait v-if="showWait" v-bind:message=status v-bind:showLoadingAnimation=statusLoading v-bind:anotherMessage=anotherStatus></wait>
  </div>
</template>

<script>

// CONFIG
const factoryContractAddress = "0x...";

// vue components
import Wait from "./components/Wait.vue";
import Start from "./components/Start.vue";
import Commit from "./components/Commit.vue";
import Reveal from "./components/Reveal.vue";
import End from "./components/End.vue";

// contract ABIs
const gameABI = require("./contracts/Game.json");
const factoryABI = require("./contracts/Factory.json");

// libraries
import { ethers } from "ethers";

// globals for etherjs 
let signer;
let factoryContract;
let gameContract;

export default {
  name: 'App',
  components: {
    Start,
    Wait,
    Commit,
    Reveal,
    End
  },
  data() {
    return {
      addressInfo: " ",
      showStart: true,
      showWait: false,
      showCommit: false,
      showReveal: false,
      showEnd: false,
      selectedAddress: "",
      player1Address: "",
      player2Address: "",
      status: "",
      anotherStatus: "",
      statusLoading: true,
      result: "",
      choice: "",
      secret: ""
      //signer: null,
      //factoryContract: null,
      //gameContract: null
    }
  },
  beforeMount() {
    // check for MetaMask
    if (typeof window.ethereum !== 'undefined' && window.ethereum.isMetaMask) {
      // initialize contract instance
      let provider = new ethers.providers.Web3Provider(window.ethereum);
      signer = provider.getSigner();
      //console.log(signer);
      factoryContract = new ethers.Contract(factoryContractAddress, factoryABI, signer);
      this.selectedAddress = window.ethereum.selectedAddress;

      // connect account
      window.ethereum.request({ method: 'eth_requestAccounts' });
    }
    else {
      alert("This App requires MetaMask. (https://metamask.io/)");
    }

    // event handlers
    window.ethereum.on("accountsChanged", (accounts) => {
      console.log("account changed to " + accounts[0]);
      this.selectedAddress = accounts[0];
    });

    factoryContract.on("MatchFound", (p1Address, p2Address, contractAddress) => {
      console.log(this);
      console.log("Your game contract is at: " + contractAddress)
      this.player1Address = p1Address;
      this.player2Address = p2Address;
      gameContract = new ethers.Contract(contractAddress, gameABI, signer);
      this.showWait = false;
      this.showCommit = true;

      // event handlers for game contract
      gameContract.on("CommitPhaseOver", () => {
        console.log(this);
        this.showWait = false;
        this.showReveal = true;
      });
      gameContract.on("RevealPhaseOver", () => {
        console.log(this);
        this.status = "picking Winner...";
        gameContract.pickWinner();
      });
      gameContract.on("WinnerIs", (_result) => {
        console.log(this);
        this.showWait = false;
        this.result = _result;
        switch(_result) {
          case 1:
            this.result = "Draw!";
            break;
          case 2:
            this.result = "Player 1 wins!";
            break;
          case 3:
            this.result = "Player 2 wins!";
            break;
          default:
            this.result = "Couldn't retrieve the game result :("
            console.log("Couldn't retrieve the game result.");
            console.log("Address of your game contract: " + contractAddress);
        }
        this.showEnd = true;
      });
      gameContract.on("GameOver", () => {
        console.log(this);
        this.showEnd = false;
        this.showStart = true;
      });
    });
  },
  methods: {
    start() {
      console.log("using address: " + this.selectedAddress)
      if (this.selectedAddress == null) {
        throw new Error("failed to get MetaMask address");
      }
      // set player address
      this.addressInfo = this.selectedAddress;

      // request game
      var promise = factoryContract.requestGame();
      var self = this;
      promise.then(function(result) {
        console.log(result);
        self.anotherStatus = "";
        self.status = "waiting for confirmation...";
        self.statusLoading = true;
        self.showStart = false;
        self.showWait = true;

        var _promise = result.wait(1);
        _promise.then(function(_result) {
          self.statusLoading = false;
          self.anotherStatus = "Confirmed in Block #" + _result.blockNumber;
          self.status = "Lets wait for a worthy opponent!";
        
        });
      });
    },
    commit(_choice, _secret) {

      this.choice = _choice;
      this.secret = _secret;

      // set gas and value
      let overrides = {
        gasPrice: 6000000000,
        gasLimit: 80000,
        value: ethers.utils.parseUnits("0.01", "ether")
      }

      // calculate secret choice
      let secretChoice = ethers.utils.solidityKeccak256([ "string", "string" ], [ _choice, _secret ]);
      // call contract method
      console.log("secret choice: " + secretChoice);
      var promise = gameContract.commit(secretChoice, overrides);
      var self = this;
      promise.then(function(result) {
        console.log(result);
        // hier------------------------------------------------
        self.showCommit = false;
        self.anotherStatus = "";
        self.status = "waiting for confirmation...";
        self.statusLoading = true;
        self.showWait = true;

        var _promise = result.wait(1);
        _promise.then(function(_result) {
          self.statusLoading = false;
          self.anotherStatus = "Confirmed in Block #" + _result.blockNumber;
          self.status = "waiting for your opponent...";
        });
      });
    },
    reveal() {
      console.log(this.choice);
      console.log(this.secret);
      // call contract method
      var promise = gameContract.reveal(this.choice, this.secret);
      var self = this;
      promise.then(function(result){
        console.log(result);
        self.showReveal = false;
        self.anotherStatus = "";
        self.status = "waiting for confirmation...";
        self.statusLoading = true;
        self.showWait = true;

        var _promise = result.wait(1);
        _promise.then(function(_result) {
          self.statusLoading = false;
          self.anotherStatus = "Confirmed in Block #" + _result.blockNumber;
          self.status = "waiting for your opponent...";
        });
      });
    },
    pickWinner() {
      var self = this;
      var promise = gameContract.pickWinner();
      promise.then(function(result){
        console.log(result);
        self.anotherStatus = "";
        self.status = "waiting for confirmation...";
        self.statusLoading = true;
        self.showWait = true;

        var _promise = result.wait(1);
        _promise.then(function(_result) {
          self.statusLoading = false;
          self.anotherStatus = "Confirmed in Block #" + _result.blockNumber;
          self.status = "waiting for smart contract...";
        });
      });
    },
    payout() {
      var promise = gameContract.payout();
      promise.then(function(result){
        console.log(result);
      });
    }
  }
};
</script>

<style>

@font-face {
  font-family: "DejaVu Sans";
  src: url("assets/webfonts/DejaVuSans.ttf");
}

#app {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #D8DEE9;
  background-color: #1A1D23;
  font-family: "DejaVu Sans";
}
.info {
  text-align: left;
  font-size: 0.6em;
}
button {
  padding: 1em;
  width: 12em;
}
input[type=text] {
  padding: 1em;
  width: 18.7em;
}
.app button, input:not([type=radio]) {
  margin-left: 0.5em;
  /*padding: 0.3em;*/
  border-style: solid;
  border-color: #E23767;
  background-color: #1A1D23;
  color: white;
  min-width: 10em;
}
button:hover {
  background-color: #E23767;
}
h1 {
  margin-top: 2em;
}
h4 {
  margin-top: -1em;
  margin-bottom: 6em;
}
input:focus {
  border-color: #E23767;
}
html {
  background-color: #1A1D23;
}

.part {
  margin-top: 2em;
}
</style>
