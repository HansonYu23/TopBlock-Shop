// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract UserManagement {

    // struct to contain item information
    struct Item {
        uint256 id;          //item index value
        string name;         //item name
        uint256 lowPrice;    //lowest expected price
        uint256 highPrice;   //high of price range
        string desc;         //description of item
        string category;    // type of item (tech, fashion, etc)
        address owner;       //addr of owner
        uint256 currBid;     //value of currBid price
        address highestBidder;  //addr of curr highest bid
        uint256 timePosted;  //block.timestamp of when item is listed
    }

    // struct to contain user information
    struct User {
        uint8 role = 0;         // role for user 0: unregistered, 1: registered, 2: admin (possibly unneeded)
        uint256 balance = 0;    // balance for user
        Item[] items = []; // array of items that the user owns, each item in the array is an Item struct
        uint256 numCart = 0;   // number of items in cart
        uint256 numSale = 0;   //number of items in market
        uint256 currBids = 0;   //number of items w user as highest bidder
    }

    address private admin; // address of admin

    uint256 private itemIndex = 1;  //global counter for item idx

    uint256 public constant saleTime = 2 weeks;   //how long items can remain in store for


    //maps an address to a User
    mapping(address => User) private users;

    // array of all items in Market, will work as a heap with items sorted by earliest post date
    Item[] private market;

    mapping(uint256 => uint256) private spotInStore;  // keeps track of location in market for each item

    constructor() {
        // set user as admin
        users[msg.sender].role = 2;
        
        // create dummy item for default item in market to connect to
        Item memory item = Item({
            id: 0,
            name: "empty item",
            lowPrice: 0,
            highPrice: 0,
            desc: "empty",
            itemType: 0,
            owner: address(0),
            currBid: 0,
            highestBidder: address(0),
            timePosted: block.timestamp
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

    // removes balance to user
    function removeBalance(uint256 amount) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            if(users[msg.sender].balance >= amount) {
                users[msg.sender].balance -= amount;
                return true;
            }
            else{
                return false;
            }
        } else {
            return false;
        }
    }



    // adds item to user
    function addItem(string itemName, uint256 lowEnd, uint256 highEnd, string itemDesc, string itemType) public {
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
