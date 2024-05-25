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
        mapping(uint256 => Item) items; // array of items that the user owns, each item in the array is an Item struct
        uint256 numItems;   // number of items the user currently owns
    }

    address private admin; // address of admin

    //maps an address to a User
    mapping(address => User) public users;

    // array of all items in Market
    Item[] private market;

    constructor() {
        // set user as admin
        users[msg.sender].role = 2;
        
        // create dummy item for default item in market to connect to
        Item memory item = Item({
            name: "dummy item",
            value: 0,
            owner: address(0)
        });
        market.push(item);
    }

    // registers the user of they are unregistered
    function registerUser() public returns (bool) {
        if (users[msg.sender].role == 0) {
            users[msg.sender].role = 1;
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
        Item memory newItem = Item({name: itemName, value: itemValue, owner: userAddress});

        // Add the item to the user's items array and increment number of items user owns
        users[userAddress].items[users[userAddress].numItems] = newItem;
        users[userAddress].numItems += 1;
    }
    
    // view role of user
    function viewRole() public view returns (uint8) {
        return users[msg.sender].role;
    }

    // view balance of user
    function viewBalance() public view returns (uint256) {
        return users[msg.sender].balance;
    }

    // function to get item details by item index
    function getItem(address userAddress, uint256 itemIndex) public view returns (Item memory) {
        require(itemIndex < users[userAddress].numItems, "Item index out of bounds");
        return users[userAddress].items[itemIndex];
    }

    // function to return all items of a user
    function getAllItems(address userAddress) public view returns (Item[] memory) {
        Item[] memory items = new Item[](users[userAddress].numItems);
        for (uint256 i = 0; i < users[userAddress].numItems; i++) {
            items[i] = getItem(userAddress, i);
        }
        return items;
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
