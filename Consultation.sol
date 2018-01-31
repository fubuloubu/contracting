pragma solidity ^0.4.19;

contract Consultation
{
    /* Parties
     * @dev `consultant` is advising `client`
     * @dev `consultant` chooses `arbiter` for arbitration of
     * @dev this agrement, to which `client` agrees to by accepting it
     */
    address public consultant;
    address public client;
    address public arbiter;

    /* Payment Details
     * @dev `client` is providing `payment` for services
     * @dev `deposit` for retaining consultant is non-refundable
     */
    uint256 public payment;
    uint256 public deposit;

    /* State of the contract
     * @dev Client can accept terms, setting `accepted` state
     * @dev Consultant provides services, setting `provided` state
     * @dev Client can dispute provision, setting `disputed` state
     */
    bool public accepted;
    bool public provided;
    bool public disputed;

    /* Contract creation
     *
     * Consultant (the creator of this contract) sets this
     * agreement to a specific client, defining the payment
     * expected, a deposit to retain services, and an arbiter
     * for the arbitration clause
     */
    function Consultation(address _client,
                          address _arbiter,
                          uint256 _payment,
                          uint256 _deposit)
        public
    {
        consultant = msg.sender;
        client = _client;
        arbiter = _arbiter;

        payment = _payment;
        deposit = _deposit;

        accepted = false;
        provided = false;
        disputed = false;
    }

    /* Nullification of this agreement
     *
     * Consultant may, at any time, nullify this agreement
     * returning all funds provided to the client    
     */
    function nullify()
        public
    {
        // Only consultant can nullify contract
        require(msg.sender == consultant);

        // Return all funds to client
        selfdestruct(client);
    }

    /* Acceptance clause
     *
     * Client accepts this agreement by sending
     * the specified amount of Ether to this address
     */
    function accept()
        public
        payable
    {
        // Contract has not be accepted yet
        require(!accepted);
        // Only client can accept
        require(msg.sender == client);
        // Client accepts by sending the requested payment
        // NOTE: Any amount above this payment will be refunded
        require(msg.value >= payment);
        accepted = true;
    }

    /* Refund clause
     *
     * Client can get a refund through this agreement
     * of their provided payment (less deposit), at any
     * point up until the services have been provided.
     */
    function refund()
        public
    {
        // Only client can get a refund
        require(msg.sender == client);
        // Contract has been accepted, but services not provided
        require(accepted);
        require(!provided);

        // Refund the client, less deposit
        // NOTE: Balance of this contract may be larger than payment
        //       so consultant only gets deposit.
        client.transfer(this.balance-deposit);
        assert(this.balance == deposit);

        // Destroy this agreement, giving the deposit to the consultant
        selfdestruct(consultant);
    }

    /* Provision of Services clause
     *
     * The consultant certifies that they have provided or will
     * provide services negotiated under this agreement. After
     * this point, the refund clause is no longer in effect,
     * but the arbitration clause will be.
     */
    function provide_services()
        public
    {
        // Only consultant can verify services are provided
        require(msg.sender == consultant);
        provided = true;
    }

    /*
     * Client confirms services were provided, releasing payment to the consultant
     */
    function confirm()
        public
    {
        // Only client can confirm provision of services
        require(msg.sender == client);
        // Contract has been accepted and services provided
        require(accepted);
        require(!provided);

        // Refund the client's additional payment (if provided)
        if (this.balance > payment)
            client.transfer(this.balance-payment);

        // Destroy this agreement, releasing full payment to consultant
        selfdestruct(consultant);
    }

    /* Arbitration clause
     *
     * After the services have been recorded as provided by the consultant,
     * the arbitration clause activates. Since both parties agreed to a 3rd party
     * arbiter of this agreement
     */
    function dispute()
        public
    {
        // Only client can dispute provision of services
        require(msg.sender == client);
        // Contract has been accepted and services provided
        require(accepted);
        require(provided);

        // Enable dispute resolution through arbiter
        disputed = true;
    }

    /*
     * Arbiter settles dispute in favor of the client or consultant,
     * depending on their determination of whether or not services were provided
     */
    function arbitrate(bool services_were_provided)
        public
    {
        // Only arbiter can settle dispute
        require(msg.sender == arbiter);

        if (services_were_provided)
        {
            // Consultant gets all funds
            selfdestruct(consultant);
        } else {
            // Client gets all funds
            selfdestruct(client);
        }
    }
}
