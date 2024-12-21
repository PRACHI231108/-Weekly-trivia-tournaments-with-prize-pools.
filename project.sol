// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeeklyTrivia {
    address public owner;
    uint256 public prizePool;
    uint256 public participationFee;
    uint256 public currentWeek;
    
    struct Participant {
        address participantAddress;
        uint256 score;
    }

    Participant[] public participants;
    mapping(address => uint256) public scores;

    event ParticipantJoined(address participant);
    event TriviaCompleted(uint256 week, address winner, uint256 prize);

    constructor(uint256 _participationFee) {
        owner = msg.sender;
        participationFee = _participationFee;
        currentWeek = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier isNotOwner() {
        require(msg.sender != owner, "Owner cannot participate");
        _;
    }

    function joinTrivia() external payable isNotOwner {
        require(msg.value == participationFee, "Incorrect participation fee");

        participants.push(Participant({participantAddress: msg.sender, score: 0}));
        scores[msg.sender] = 0;
        prizePool += msg.value;

        emit ParticipantJoined(msg.sender);
    }

    function submitScore(address participant, uint256 score) external onlyOwner {
        require(scores[participant] == 0, "Score already submitted");

        scores[participant] = score;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i].participantAddress == participant) {
                participants[i].score = score;
                break;
            }
        }
    }

    function finalizeWeek() external onlyOwner {
        require(participants.length > 0, "No participants this week");

        address winner;
        uint256 highestScore = 0;

        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i].score > highestScore) {
                highestScore = participants[i].score;
                winner = participants[i].participantAddress;
            }
        }

        require(winner != address(0), "No winner this week");

        uint256 prize = prizePool;
        prizePool = 0;

        (bool sent, ) = winner.call{value: prize}("");
        require(sent, "Failed to send prize");

        emit TriviaCompleted(currentWeek, winner, prize);

        delete participants;
        currentWeek++;
    }

    function updateParticipationFee(uint256 newFee) external onlyOwner {
        participationFee = newFee;
    }

    function getParticipants() external view returns (Participant[] memory) {
        return participants;
    }
}
