// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract UserManagement {

    // struct to contain item information
    struct Item {
        string name;
        uint256 value;
        address owner;
    }

    // struct to contain user information
    struct User {
        uint8 role;         // role for user 0: unregistered, 1: registered, 2: admin (possibly unneeded)
        uint256 balance;    // balance for user
        Item[] items;       // array of items that the user owns, each item in the array is an Item struct
    }

    address private admin; // address of admin

    //maps an address to a User
    mapping(address => User) public users;

    // array of all items in Market
    Item[] private market;

    constructor() {
        // set user as admin
        roles[msg.sender] = 2;
        
        // create dummy item for default item in market to connect to
        Item memory item = Item({
            name: "dummy item",
            value: 0,
            owner: address(0)
        });
        market.push(item);
    }

    // initialize the user with unregistered role, 0 initial balance, and no items
    function initializeUser(address userAddress) public {
        users[userAddress] = User(0, 0, new Item[](0));
    }

    // registers the user of they are unregistered
    function registerUser() public returns (bool) {
        if (roles[msg.sender] == 0) {
            roles[msg.sender] = 1;
            return true;
        }
        return false;
    }

    // adds balance to user
    function addBalance(uint256 amount) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            users[msg.sender].balance += amount;
            return true;
        } else {
            return false;
        }
    }

    // adds item to user
    function addItemToUser(address userAddress, string memory itemName, uint256 itemValue) public {
        // Create a new Item
        Item memory newItem = Item(itemName, itemValue, userAddress);

        // Add the item to the user's items array
        users[userAddress].items.push(newItem);
    }
    
    // view role of user
    function viewRole() public view returns (uint8) {
        return users[msg.sender].role;
    }

    // view balance of user
    function viewBalance() public view returns (uint256) {
        return users[msg.sender].balance;
    }

    // view all items that user owns
    function viewItems() public view returns (Item[] memory) {
        return users[msg.sender].items;
    }


    // transfer balance from user to receiver 
    function transferBalance(address receiverAddress, uint256 amount) public returns (bool){
        if (users[msg.sender].balance >= amount){
            users[msg.sender].balance -= amount;
            users[receiverAddress].balance += amount;
            return true;
        }
        else{
            return false;
        }
    }

}
