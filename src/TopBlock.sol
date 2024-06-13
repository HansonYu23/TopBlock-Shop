// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract TopBlock {

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
        address highestBidder;  //addr of curr highest 
        uint256 timePosted;  //block.timestamp of when item is listed
    }

    struct PrintItem {
        uint256 id;
        string name;
        string desc;
        string category;
        uint256 lowPrice;
        uint256 highPrice;
    }

    // struct to contain user information
    struct User {
        uint8 role;         // role for user 0: unregistered, 1: registered, 2: admin (possibly unneeded)
        uint256 balance;    // balance for user
        Item[] items;       // array of items that the user owns, each item in the array is an Item struct
        uint256 numCart;    // number of items in cart
        uint256 numSale;    // number of items in market
        uint256 currBids;   // number of items w user as highest bidder
    }

    address private admin; // address of admin

    uint256 private itemIndex = 1;  //global counter for item idx

    uint256 private actionCounter = 0; 

    uint256 public constant saleTime = 10;   //how long items can remain in store for


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
            category: "none",
            owner: address(0),
            currBid: 0,
            highestBidder: address(0),
            timePosted: block.timestamp
        });
        market.push(item);
    }


    //REGISTRATION
    // registers the user of they are unregistered
    function registerUser() public returns (bool) {
        if (users[msg.sender].role == 0) {
            users[msg.sender].role = 1;
            actionCounter++;
            return true;
        }
        return false;
    }
    // view role of user
    function viewRole() public view returns (uint8) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            return users[msg.sender].role;
        }
        else {
            return 0;
        }
    }


    // BALANCES
    // adds balance to user
    function addBalance(uint256 amount) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            require(users[msg.sender].balance + amount >= users[msg.sender].balance, "Overflow detected");
            users[msg.sender].balance += amount;
            return true;
        } else {
            return false;
        }
    }

    // removes balance to user
    function withdrawBalance(uint256 amount) public returns (bool) {
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

    // view balance of user
    function viewBalance() public view returns (uint256) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            return users[msg.sender].balance;
        } else {
            return 0;
        }
    }


    //CART MANAGEMENT
    // view cart size of user
    function viewCartSize() public view returns (uint256) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            return users[msg.sender].numCart;
        } else {
            return 0;
        }
    }

    //view items in cart
    function viewItemsInCart() public view returns (PrintItem[] memory) {
        uint256 length = users[msg.sender].items.length;
        PrintItem[] memory cartItems = new PrintItem[](length);

        for (uint256 i = 0; i < length; i++) {
            cartItems[i] = PrintItem(
                users[msg.sender].items[i].id,
                users[msg.sender].items[i].name,
                users[msg.sender].items[i].desc,
                users[msg.sender].items[i].category,
                users[msg.sender].items[i].lowPrice,
                users[msg.sender].items[i].highPrice
            );
        }
        return cartItems;
    }

    function viewCartItem(uint256 index) public view returns (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) {
        for (uint256 i = 0; i < users[msg.sender].items.length; i++) {
            if (users[msg.sender].items[i].id == index) {
                Item memory item = users[msg.sender].items[i];
                return (
                    item.id,
                    item.name,
                    item.desc,
                    item.category,
                    item.lowPrice,
                    item.highPrice
                );
            }
        }
        return (0, "", "", "", 0, 0);
    }

    // adds item to user
    function addItem(string memory itemName, uint256 lowEnd, uint256 highEnd, string memory itemDesc, string memory itemType, uint256 quantity) public returns (bool) {
        
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            if(users[msg.sender].numCart + quantity < 100){
                
                for(uint256 i = 0; i < quantity; i++){
                    // Create a new Item
                    Item memory newItem = Item({
                        id: itemIndex,
                        name: itemName,
                        lowPrice: lowEnd,
                        highPrice: highEnd,
                        desc: itemDesc,
                        category: itemType,
                        owner: msg.sender,
                        currBid: 0,
                        highestBidder: address(0),
                        timePosted: 0
                    });

                    //increment global counter
                    itemIndex++;

                    // Add the item to the user's items array and increment number of items in user cart
                    users[msg.sender].items.push(newItem);
                    users[msg.sender].numCart++;
                }
                return true;   //successfull addition of n similar items
            }
            else{
                return false;    //too many items in cart
            }
        }
        else {
            return false;  //unregistered user
        }
    }

    function editLowPrice(uint256 index, uint256 newLow) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            for(uint256 i = 0; i < users[msg.sender].items.length; i++) {
                if(users[msg.sender].items[i].id == index) {
                    users[msg.sender].items[i].lowPrice = newLow;
                    return true;
                }
            }
            return false; //item idx not in cart
        }
        else {
            return false; //unregistered user
        }
    }
    function editHighPrice(uint256 index, uint256 newHigh) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            for(uint256 i = 0; i < users[msg.sender].items.length; i++) {
                if(users[msg.sender].items[i].id == index) {
                    users[msg.sender].items[i].highPrice = newHigh;
                    return true;
                }
            }
            return false; //item idx not in cart
        }
        else {
            return false; //unregistered user
        }
    }
    function editDescr(uint256 index, string memory newDesc) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            for(uint256 i = 0; i < users[msg.sender].items.length; i++) {
                if(users[msg.sender].items[i].id == index) {
                    users[msg.sender].items[i].desc = newDesc;
                    return true;
                }
            }
            return false; //item idx not in cart
        }
        else {
            return false; //unregistered user
        }
    }
    function editName(uint256 index, string memory newName) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            for(uint256 i = 0; i < users[msg.sender].items.length; i++) {
                if(users[msg.sender].items[i].id == index) {
                    users[msg.sender].items[i].name = newName;
                    return true;
                }
            }
            return false; //item idx not in cart
        }
        else {
            return false; //unregistered user
        }
    }
    function editType(uint256 index, string memory newType) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            for(uint256 i = 0; i < users[msg.sender].items.length; i++) {
                if(users[msg.sender].items[i].id == index) {
                    users[msg.sender].items[i].category = newType;
                    return true;
                }
            }
            return false; //item idx not in cart
        }
        else {
            return false; //unregistered user
        }
    }

    // deletes an item from the user's items array
    function deleteItem(uint256 index) public returns (bool) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            for (uint256 i = 0; i < users[msg.sender].items.length; i++) {
                if (users[msg.sender].items[i].id == index) {
                    // remove item by swapping it with last element and popping array
                    users[msg.sender].items[i] = users[msg.sender].items[users[msg.sender].items.length - 1];
                    users[msg.sender].items.pop();
                    users[msg.sender].numCart--;
                    return true;
                }
            }
            return false; //item idx not in cart
        }
        else {
            return false; //unregistered user
        }
    }

    //LISTING
    // view number of items for sale by user
    function viewSaleCount() public view returns (uint256) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            return users[msg.sender].numSale;
        } else {
            return 0;
        }
    }

    function handleExpiredItems() external {
        for (uint256 i = market.length - 1; i > 1; i--) {
            if (actionCounter - market[i].timePosted > saleTime || actionCounter < market[i].timePosted) {  // 
                if (market[i].currBid == 0 || market[i].highestBidder == address(0)) {
                    // Item has no bids, return it to the owner's cart

                    Item memory itemToCart = market[i];
                    market[i] = market[market.length - 1];
                    spotInStore[market[i].id] = i;
                    market.pop();

                    itemToCart.timePosted = 0;
                    itemToCart.highestBidder = address(0);
                    itemToCart.currBid = 0;

                    users[itemToCart.owner].items.push(itemToCart);
                    users[itemToCart.owner].numCart++;
                    users[itemToCart.owner].numSale--;
                    spotInStore[itemToCart.id] = 0;
                } 
                else {
                    // Item has a highest bid
                    //check adequeate balance
                    // Item has a highest bid
                    
                    Item memory itemToCart = market[i];
                    if(users[itemToCart.highestBidder].balance >= itemToCart.currBid){
                        //sufficient balance
                        market[i] = market[market.length - 1];
                        spotInStore[market[i].id] = i;
                        market.pop();

                        users[itemToCart.owner].numSale--;
                        users[itemToCart.owner].balance += itemToCart.currBid;
                        users[itemToCart.highestBidder].balance -= itemToCart.currBid;

                        itemToCart.owner = itemToCart.highestBidder;
                        itemToCart.timePosted = 0;
                        itemToCart.highestBidder = address(0);
                        itemToCart.currBid = 0;

                        users[itemToCart.owner].items.push(itemToCart);
                        users[itemToCart.owner].numCart++;
                        users[itemToCart.owner].currBids--;
                        spotInStore[itemToCart.id] = 0;
                    }
                    else {
                        // not enough balance, send back to og owner
                        market[i] = market[market.length - 1];
                        spotInStore[market[i].id] = i;
                        market.pop();

                        users[itemToCart.highestBidder].currBids--;
                        itemToCart.timePosted = 0;
                        itemToCart.highestBidder = address(0);
                        itemToCart.currBid = 0;

                        users[itemToCart.owner].items.push(itemToCart);
                        users[itemToCart.owner].numCart++;
                        users[itemToCart.owner].numSale--;
                        spotInStore[itemToCart.id] = 0;
                    }
                }
            }
        }
    }

    //list item in market
    function listCartItemToMarket(uint256 idx) public returns (bool) {
        this.handleExpiredItems();
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            if(users[msg.sender].numSale < 50) {

                for (uint256 i = 0; i < users[msg.sender].items.length; i++) {
                    if (users[msg.sender].items[i].id == idx) {

                        //find and remove item from cart
                        Item memory itemToMarket = users[msg.sender].items[i];
                        users[msg.sender].items[i] = users[msg.sender].items[users[msg.sender].items.length - 1];
                        users[msg.sender].items.pop();
                        users[msg.sender].numCart--;

                        itemToMarket.timePosted = actionCounter;  //set time
                        market.push(itemToMarket);
                        spotInStore[itemToMarket.id] = market.length - 1;
                        users[msg.sender].numSale++;
                        actionCounter += 2;
                        return true;
                    }
                }
                return false; //idx not in user cart
            }
            else{
                return false;  //too many items for sale already
            }
        }
        else{
            return false;  //unregistered user
        }
    }

    //return to cart from market, cancel sale
    function unlistItemFromMarket(uint256 index) public returns (bool) {
        this.handleExpiredItems();
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            uint256 spot = spotInStore[index];
            if (spot > 0 && spot < market.length && market[spot].owner == msg.sender) {
                Item memory itemToCart = market[spot];
                market[spot] = market[market.length - 1];
                spotInStore[market[spot].id] = spot;
                market.pop();

                itemToCart.timePosted = 0;
                itemToCart.highestBidder = address(0);
                itemToCart.currBid = 0;

                users[msg.sender].items.push(itemToCart);
                users[msg.sender].numCart++;
                users[msg.sender].numSale--;
                spotInStore[index] = 0;
                actionCounter++;
                return true;
            }
            else{
                return false;   //item not in market, or not owner
            }
        }
        else{
            return false;      //unregistered user
        }
    }

    //BUYING
    // view number of active bids by user
    function viewNumActiveBids() public view returns (uint256) {
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            return users[msg.sender].currBids;
        } else {
            return 0;
        }
    }

    function viewMarket() public view returns (PrintItem[] memory) {
        uint256 length = market.length - 1;
        PrintItem[] memory marketItems = new PrintItem[](length);

        for (uint256 i = 1; i < market.length; i++) {
            marketItems[i - 1] = PrintItem(
                market[i].id,
                market[i].name,
                market[i].desc,
                market[i].category,
                market[i].lowPrice,
                market[i].highPrice
            );
        }
        return marketItems;
    }
    function viewMarketItem(uint256 index) public view returns (uint256, string memory, string memory, string memory, uint256, uint256, uint256) {
        uint256 spot = spotInStore[index];
        require(spot > 0 && spot < market.length, "Item not found in market");
        Item memory item = market[spot];
        return (
            item.id,
            item.name,
            item.desc,
            item.category,
            item.lowPrice,
            item.highPrice,
            item.timePosted
        );
    }

    // bid on an item
    function placeBid(uint256 bidAmount, uint256 index) public returns (bool) {
        this.handleExpiredItems();
        if (users[msg.sender].role == 1 || users[msg.sender].role == 2) {
            uint256 spot = spotInStore[index];
            if (spot > 0 && spot < market.length) {
                Item storage item = market[spot];

                // check if bid amount is greater than current bid
                if (bidAmount >= item.lowPrice && msg.sender != item.owner && users[msg.sender].currBids < 15) {
                    if (users[msg.sender].balance >= bidAmount){


                        //Update highest bidder and bid amount 
                        if (item.highestBidder != address(0x0)){
                            users[item.highestBidder].currBids--;
                        }
                        item.highestBidder = msg.sender;
                        item.currBid = bidAmount;
                        item.lowPrice = bidAmount + 1;
                        uint256 newHighPrice = (bidAmount + 1) * 6 / 5;
                        item.highPrice = item.highPrice > newHighPrice ? item.highPrice : newHighPrice;
                        users[msg.sender].currBids++;
                        actionCounter += 2;
                        return true;
                    }
                    else{
                        return false;    //not enough balance to cover
                    }
                }
                else{
                    return false;    // not highest bid or owner bid on their own
                }
            }
            else{
                return false;  //item not in market
            }
        }
        else {
            return false; //unregistered user
        }
    }
}
