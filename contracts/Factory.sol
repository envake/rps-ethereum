//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './CloneFactory.sol';

contract Factory is CloneFactory {
    
    // some variables
    address payable public owner;
    Game[] public games;
    address gameContract;
    address public playerQueue;
    
    // constructor needs "blueprint" that gets cloned
    constructor(address _gameContract){
        gameContract = _gameContract;
        owner = msg.sender;
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    
    // event that gets fired when 2 players are ready to play
    event MatchFound(address _player1, address _player2, address _gameContract);

    // frontends can request a game and wait for the MatchFound-event
    function requestGame() external {
        // if queue is not empty
        if (playerQueue != address(0x0)) {
            // if the same player requests again -.-
            if (playerQueue == msg.sender) {
                revert("allready queued");
            }
            // clone the blueprint
            Game game = Game(createClone(gameContract));
            // instead of constructor for game contract we use init() to set players and the bet amount
            game.init(address(uint160(playerQueue)), msg.sender, 0.01 ether);
            games.push(game);
            // fire event
            emit MatchFound(playerQueue, msg.sender, address(game));
            // clear queue
            playerQueue = address(0x0);
        }
        // if queue is empty -> fill it with the requesting address
        else {
            playerQueue = msg.sender;
        }
    }
    
    function getGames() external view returns(Game[] memory) {
        return games;
    }
    
    // send balance to owner
    function withdraw() external isOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        assert (success);
    }
    
    function destroy() external isOwner {
        selfdestruct(owner);
    }
}

contract Game {
    
    // parameters for initialization
    address payable public owner;
    bool private initialized;
	uint public bet;
    
    // possible choices for a player
    enum Choices { none, rock, paper, scissors }
    // possible results of the game
    enum Results { none, draw, player1Wins, player2Wins }

	// address and timestamp from first reveal
	address payable public firstRevealedPlayer;
	uint private revealTime;
	
	// timestamp from first commit
	uint private commitTime;

    // player addresses
    address payable public player1;
    address payable public player2;

    // player secret choices(hashes)
    bytes32 private player1SecretChoice;
    bytes32 private player2SecretChoice;
    
    // player choices
    Choices public player1Choice;
    Choices public player2Choice;
    
    // safe payout state
    bool private player1CanPayout = false;
    bool private player2CanPayout = false;
    
    // result of the game
    Results private result;

    //////////////////////////////////////////////////////////////////////////////////
    
    modifier notInitialized() {
        require(initialized == false);
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier isRegistered() {
        require (msg.sender == player1 || msg.sender == player2, "player not registered");
        _;
    }
    modifier commitFinished() {
        require(
            (player1SecretChoice != 0x0 && player2SecretChoice != 0x0) ||
            (commitTime != 0 && block.timestamp > commitTime + 10 minutes)
        );
        _;
    }
    modifier revealFinished() {
        require(
        	(player1Choice != Choices.none && player2Choice != Choices.none) ||
        	(revealTime != 0 && block.timestamp > revealTime + 10 minutes)
        );
        _;
    }
    modifier gameFinished() {
        require (result != Results.none, "game hasn't finished yet");
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////
    
    event CommitPhaseOver();
    event RevealPhaseOver();
    event WinnerIs(Results _result);

    function init(address payable _player1, address payable _player2, uint _bet) external notInitialized {
        initialized = true;
        owner = msg.sender;
        bet = _bet;
        player1 = _player1;
        player2 = _player2;
    }

    // play the game by commiting a secret choice and paying the bet, returns true on success
    function commit(bytes32 secretChoice) public payable isRegistered {
        if (msg.value < bet) {
            revert("not enough ether");
        }
        // set commitTime to current timestamp
        if (commitTime == 0) {
            commitTime = block.timestamp;
        }
        if (msg.sender == player1 && player1SecretChoice == 0x0) {
            player1SecretChoice = secretChoice;
        } else if (msg.sender == player2 && player2SecretChoice == 0x0) {
            player2SecretChoice = secretChoice;
        } else {
            revert("allready commited");
        }
        // fire event when both players commited a choice
        if (player1SecretChoice != 0x0 && player2SecretChoice != 0x0) {
            emit CommitPhaseOver();
        }
    }

    // reveal the secret choice by providing the secret, returns true on success
    function reveal(string memory choice, string memory secret) public isRegistered commitFinished {
        // check for valid choice input
        Choices c;
        bytes32 input = keccak256(abi.encodePacked(choice));
        
        if (input == keccak256(abi.encodePacked("rock"))) {
            c = Choices.rock;
        }
        else if (input == keccak256(abi.encodePacked("paper"))) {
            c = Choices.paper;
        }
        else if (input == keccak256(abi.encodePacked("scissors"))) {
            c = Choices.scissors;
        }
        else {
            revert("invalid choice");
        }
        
        // calculate hash
        bytes32 revealedChoice = keccak256(abi.encodePacked(choice, secret));
        
        // check for valid secret
        if (player1SecretChoice == revealedChoice) {
            // if hashes match for player 1, his clear choice is saved
            player1Choice = c;
        } else if (player2SecretChoice == revealedChoice) {
            // if hashes match for player 2, his clear choice is saved
            player2Choice = c;
        } else {
            // otherwise the secret was not valid
            revert("invalid secret");
        }

        // check if it was the first player that revealed his choice
        if (firstRevealedPlayer == address(0x0)) {
            // save his address
            firstRevealedPlayer = msg.sender;
            // save the timestamp
            revealTime = block.timestamp;
        }
        
        if (player1Choice != Choices.none && player2Choice != Choices.none) {
            emit RevealPhaseOver();
            
        }
    }

    // sets the game result
    function pickWinner() public revealFinished {
        
        // check for draw
    	if (player1Choice == player2Choice) {
    	    result = Results.draw;
    	    player1CanPayout = true;
    	    player2CanPayout = true;
        // check if player1 wins 
        } else if ((player1Choice == Choices.rock && player2Choice == Choices.scissors) ||
                    (player1Choice == Choices.paper && player2Choice == Choices.rock) ||
                    (player1Choice == Choices.scissors && player2Choice == Choices.paper) ||
                    (player1Choice != Choices.none && player2Choice == Choices.none)) {
            result = Results.player1Wins;
            player1CanPayout = true;
        // player 2 wins
        } else {
            result = Results.player2Wins;
            player2CanPayout = true;
        }
        // fire event with result for frontends
        emit WinnerIs(result);
    }
    
    // pays the sender and eventually destroys the contract
    function payout() public gameFinished {
        // player1
        if (msg.sender == player1 && player1CanPayout) {
            player1CanPayout = false;
            // payout draw
            if (result == Results.draw) {
                (bool success,) = player1.call{value: bet * 95 / 100}("");
                assert (success);
            }
            // payout player 1 if player2 never commited something
            else if(player2Choice == Choices.none) {
                (bool success,) = player1.call{value: bet * 95 / 100}("");
                assert (success);
            }
            // payout player1
            else {
                (bool success,) = player1.call{value: 2 * bet * 95 / 100}("");
                assert (success);
            }
        // player2
        } else if (msg.sender == player2 && player2CanPayout) {
            player2CanPayout = false;
            // payout draw
            if (result == Results.draw) {
                (bool success,) = player2.call{value: bet * 95 / 100}("");
                assert (success);
            }
            // payout player2 if player1 never commited something
            else if(player1Choice == Choices.none) {
                (bool success,) = player2.call{value: bet * 95 / 100}("");
                assert (success);
            }
            // payout player2
            else {
                (bool success,) = player2.call{value: 2 * bet * 95 / 100}("");
                assert (success);
            }
        }
        else {
            revert("sender cant get any payout");
        }
        
        // destroy contract and send balance to factory
        if (player1CanPayout == false && player2CanPayout == false) {
            selfdestruct(owner);
        }
    }
}