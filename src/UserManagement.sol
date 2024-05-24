// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract UserManagemnet {

    // struct used to better organize an invoice
    struct Invoice {
        uint256 amount;          // total amount requested by the host
        uint256 remainingAmount; // remaining amount that the guest needs to pay; 0 means fully paid out
        address host;            // the host that sends the invoice
        address guest;           // the guest that receives the invoice
    }

    address private admin;        // address of admin

    // maps an address to one of the following roles:
    //   - 0: unregistered users
    //   - 1: admin, the one that deploy the contract; do not use
    //   - 2: host
    //   - 3: guest
    //   - others: invalid; do not use
    mapping(address => uint8) private roles;

    // maps an address to its balance
    mapping(address => uint256) private balances;

    // array of all invoices
    Invoice[] private invoices;

    // maps an address to its existing invoice id
    // the invoice id can be used as index to access the `invoices` array
    mapping(address => uint256) private addr2invoice;

    constructor() {
        roles[msg.sender] = 1;
        // create dummy invoice for default invoice to connect to
        Invoice memory invoice = Invoice({
            amount: 0,
            remainingAmount: 0,
            host: address(0),
            guest: address(0)
        });
        invoices.push(invoice);
    }

    // Add balance to the caller's account
    // Args:
    //   - amount (uint256): the amout to add
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only registered users (admin/host/guest) add balance; otherwise, return false
    function addBalance(uint256 amount) public returns (bool) {
        // registered user only
        if (roles[msg.sender] == 1 || roles[msg.sender] == 2 || roles[msg.sender]==3) {
            balances[msg.sender] += amount;
            return true;
        } else {
            return false;
        }
    }

    // Check the balance of the caller 
    // Rets:
    //   - (uint256): balance of the caller's account
    // Specs:
    //   - everyone (including non-registered users) can call this function
    function viewBalance() public view returns (uint256) {
        // for all users
        return balances[msg.sender];
    }

    // Check the role of the caller
    // Rets:
    //   - (uint8): role of the caller
    // Specs:
    //   - check role definitions near the `roles` data structure
    function viewRole() public view returns (uint8) {
        // ============================
        // add your implementation here
        // ============================
        return roles[msg.sender];
    }

    // Register the caller as a host
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only unregistered users can register; otherwise, return false
    //   - a user can only register once; otherwise, return false
    function registerHost() public returns (bool) {
        // ============================
        // add your implementation here
        // ============================
        if (roles[msg.sender] == 0) {
            roles[msg.sender] = 2;
            return true;
        }
        return false;
    }

    // Register the caller as a guest
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only unregistered users can register; otherwise, return false
    //   - a user can only register once; otherwise, return false
    function registerGuest() public returns (bool) {
        // ============================
        // add your implementation here
        // ============================
        if (roles[msg.sender] == 0) {
            roles[msg.sender] = 3;
            return true;
        }
        return false;
    }

    // Send out an invoice to a guest
    // Args:
    //   - toAddr (address): guest address that you want to send the invoice to
    //   - amount (uint256): amount requested
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only host can send an invoice; otherwise, return false
    //   - an invoice can only be sent to a guest; otherwise, return false
    //   - the host cannot send an invoice if the host has an existing invoice that 
    //     has not been fully paid out yet; in this case, return false
    function sendInvoice(address toAddr, uint256 amount) public returns (bool) {
        // ============================
        // add your implementation here
        // ============================
        if (roles[msg.sender] == 2 && roles[toAddr] == 3) {
            if (addr2invoice[msg.sender] == 0 || invoices[addr2invoice[msg.sender]].remainingAmount == 0) {
                Invoice memory newInvoice = Invoice(amount, amount, msg.sender, toAddr);
                invoices.push(newInvoice);
                uint256 newId = invoices.length - 1;
                addr2invoice[msg.sender] = newId;
                addr2invoice[toAddr] = newId;
                return true;
            }
        }
        return false;
    }

    // View the latest invoice
    // Rets:
    //   - (uint256, uint256, address, address): a 4-tuple indicating total amount requested,
    //     remaining amount that the guest needs to pay, host that sends the invoice, and guest
    //     that receives the invoice
    // Specs:
    //   - only registered users can view invoice; otherwise return (0, 0, address(0), address(0))
    //   - if (for the guest) no invoice has been received before or (for the host) no invoice has
    //     been sent out before, simply return (0, 0, address(0), address(0))
    function viewInvoice() public view returns (uint256, uint256, address, address) {
        // ============================
        // add your implementation here
        // ============================
        if (roles[msg.sender] == 1 || roles[msg.sender] == 2 || roles[msg.sender] == 3) {
            uint256 invoiceId = addr2invoice[msg.sender];
            if (invoiceId > 0) {
                Invoice memory invoice = invoices[invoiceId];
                return (invoice.amount, invoice.remainingAmount, invoice.host, invoice.guest);
            }
        }
        return (0, 0, address(0), address(0));
    }

    // Pay the invoice
    // Args:
    //   - amount (uint256): the amount that the guest wants to pay
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only guest can pay invoice; otherwise return false
    //   - if the amount to pay is more than the guest's balance, return false
    //   - if the amount to pay is less than the remaining amout of the invoice,
    //     pay the amount to the corresponding host and update the remaining amount
    //     on the invoice
    //   - if the amount to pay is more than the remaining amount of the invoice,
    //     pay the remaining amout the the corresponding host and update the invoice
    //     to "paid out" by setting the remaining amount to 0
    //   - don't forget to deduce the actually paid amount from the guest's balance
    function payInvoice(uint256 amount) public returns (bool) {
        // ============================
        // add your implementation here
        // ============================
        uint256 invoiceId = addr2invoice[msg.sender];
        if (roles[msg.sender] == 3 && invoiceId > 0) {
            Invoice storage invoice = invoices[invoiceId];
            if (amount <= balances[msg.sender] && amount > 0) {
                uint256 toPay;
                if (amount > invoice.remainingAmount) {
                    toPay = invoice.remainingAmount;
                }
                else {
                    toPay = amount;
                }
                balances[msg.sender] -= toPay;
                invoice.remainingAmount -= toPay;
                balances[invoice.host] += toPay;
                return true;
            }
        }
        return false;
    }

}
