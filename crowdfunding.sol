// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors; // mapping to keep track of contributors and their contributed amounts
    address public manager; // address of the manager who deployed the contract
    uint public minimumContribution; // minimum contribution amount required from each contributor
    uint public deadline; // deadline until which contributions can be made
    uint public target; // target amount to be raised through crowdfunding
    uint public raisedAmount; // total amount raised so far
    uint public noOfContributors; // number of unique contributors

    struct Request {
        // a structure to store details of requests for payment made by the manager
        string description; // description of the request
        address payable recipient; // address of the recipient who will receive the payment
        uint value; // amount to be paid to the recipient
        bool completed; // flag to indicate if the request has been completed or not
        uint noOfVoters; // number of contributors who have voted for the request
        mapping(address => bool) voters; // mapping to keep track of contributors who have voted for the request
    }

    mapping(uint => Request) public requests; // mapping to keep track of all the requests made by the manager

    uint public numRequests = 0; // number of requests made by the manager

    constructor(uint _target, uint _deadline) {
        // constructor to initialize the contract with target and deadline values
        target = _target; // set the target amount to be raised
        deadline = block.timestamp + _deadline; //_deadline must be in seconds (for e.g. 24 hours is equivalent to 86,000 seconds) // set the deadline for contributions
        minimumContribution = 100 wei; // set the minimum contribution amount required from each contributor
        manager = msg.sender; // set the address of the manager who deployed the contract
    }

    function sendEth() public payable {
        // function to accept contributions from contributors
        require(
            block.timestamp < deadline,
            "Deadline to contribute to this smartcontract has passed."
        ); // check if the deadline for contributions has passed
        require(
            msg.value >= minimumContribution,
            "Minimum Contribution is not met."
        ); // check if the contribution amount is greater than or equal to the minimum required

        if (contributors[msg.sender] == 0) {
            // if the contributor is contributing for the first time, increment the number of contributors
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value; // update the contribution amount of the contributor
        raisedAmount += msg.value; // update the total amount raised
    }

    function getContractBalance() public view returns (uint) {
        // function to get the current balance of the contract
        return address(this).balance;
    }

    function refund() public {
        // function to refund the contributions made by contributors in case the target is not met and the deadline has passed
        require(
            block.timestamp > deadline,
            "The deadline for this Crowdfunding is yet to reach."
        ); // check if the deadline for contributions has passed
        require(
            raisedAmount < target,
            "Refund is not possible as target has already reached."
        ); // check if the target amount has been reached

        require(
            contributors[msg.sender] > 0,
            "You are not elegible for refund."
        ); // check if the contributor has made any contribution

        address payable user = payable(msg.sender);

        user.transfer(contributors[msg.sender]); // transfer the contributed amount back to the contributor

        contributors[msg.sender] = 0; // reset the contribution amount of the contributor to zero
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function."); // Only the manager can call this function
        _;
    }

    function creaRequests(
        string memory _description,
        address payable _recipient,
        uint _value
    ) public onlyManager {
        Request storage newRequest = requests[numRequests]; // creates a new request and stores it in the requests mapping
        numRequests++; // increments the number of requests made

        newRequest.description = _description; // sets the description of the new request
        newRequest.recipient = _recipient; // sets the recipient of the new request
        newRequest.value = _value; // sets the value of the new request
        newRequest.completed = false; // sets the completion status of the new request to false
        newRequest.noOfVoters = 0; // sets the number of voters for the new request to 0
    }

    function voteForRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be a contributor"); // requires the voter to be a contributor

        Request storage thisRequest = requests[_requestNo]; // gets the request from the mapping using its number

        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted."
        ); // requires the voter to not have already voted
        thisRequest.voters[msg.sender] = true; // adds the voter to the list of voters for the request
        thisRequest.noOfVoters++; // increments the number of voters for the request
    }

    function makePayment(uint _requestNo) public payable onlyManager {
        require(raisedAmount >= target, "Target has not met yet."); // requires the target to have been met
        Request storage thisRequest = requests[_requestNo]; // gets the request from the mapping using its number
        require(
            thisRequest.completed == false,
            "The Request has been completed."
        ); // requires the request to not have already been completed
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "Not enough contributors have voted for this request."
        ); // requires more than half of the contributors to have voted for the request
        thisRequest.recipient.transfer(thisRequest.value); // transfers the value of the request to the recipient
        thisRequest.completed = true; // sets the completion status of the request to true
    }
}
