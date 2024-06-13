## TopBlock Shop

## Setup and Initialization

```shell
$ forge build
$ forge test
```

## Function Information

### viewTime()
**Use:** Shows the market's time counter value <br />
**In:** None <br />
**Out:** Returns the actionCounter value <br />

### registerUser()
**Use:** Register's the user <br />
**In:** None <br />
**Out:** Returns true if registered successfully, false otherwise <br />

### viewRole()
**Use:** Shows the user's role <br />
**In:** None <br />
**Out:** Returns the user's role (0 unregistered, 1 registered, 2 admin) <br />

### addBalance(uint256 amount)
**Use:** Add to the user's balance amount <br />
**In:** Amount to be withdrawn <br />
**Out:** Returns true if added successfully, returns false if unregistered <br />

### withdrawBalance(uint256 amount)
**Use:** Withdraw from the user's balance amount <br />
**In:** Amount to be withdrawn <br />
**Out:** Returns true if withdrawn successfully, returns false otherwise <br />

### viewBalance()
**Use:** Shows the user's balance amount <br />
**In:** None <br />
**Out:** Returns the user's balance, returns 0 if the caller is not registered <br />

### viewCartSize()
**Use:** Shows the number of items that the caller has in personal cart <br />
**In:** None <br />
**Out:** Returns the number of items that the caller has in cart, returns 0 if the caller is not registered <br />

### viewItemsInCart()
**Use:** View all items from the items array of the caller<br />
**In:** None <br />
**Out:** Returns (id, name, desc, category, lowPrice, and highPrice) of all items within the cart <br />

### viewCartItem(uint256 index)
**Use:** View an item from the items array of the caller<br />
**In:** Takes in the index of the item to be viewed <br />
**Out:** Returns (id, name, desc, category, lowPrice, and highPrice) of the item if it exists within the cart <br />

### addItem(string itemName, uint256 lowEnd, uint256 highEnd, string itemDesc, string itemType, uint256 quantity)
**Use:** Adds quantity amount of items into the items array of the caller with the corresponding item information <br />
**In:** Takes in the index of the item to be edited and the new value<br />
**Out:** Returns true if the items are successfully added, returns false if the items are unable to be added or if the caller is not registered <br />


### editLowPrice(uint256 index, uint256 newLow)
### editHighPrice(uint256 index, uint256 newHigh)
### editDescr(uint256 index, string newDesc)
### editName(uint256 index, string newName)
### editType(uint256 index, string newType)
**Use:** Edits an item in the items array of the caller <br />
**In:** Takes in the index of the item to be edited and the new value <br />
**Out:** Returns true if the item is successfully edited, returns false if the item is not found or if the caller is not registered <br />

### deleteItem(uint256 index)
**Use:** Deletes an item from the items array of the caller <br />
**In:** Takes in the index of the item to be deleted <br />
**Out:** Returns true if the item is successfully deleted, returns false if the item is not found or if the caller is not registered <br />

### viewSaleCount()
**Use:** Shows the number of items that the caller has for active sale <br />
**In:** None <br />
**Out:** Returns the number of items that the caller has for active sale, returns 0 if the caller is not registered <br />

### handleExpiredItems()
**Use:** Checks market for any expired listings and completes the transaction, items are sent back to the lister if 
there are no active bids or if the current highest bidder does not have sufficient balance to cover the transaction <br />
**In:** None <br />
**Out:** None <br />

### listCartItemToMarket(uint256 idx)
**Use:** Adds item owned by the caller to the market and calls handleExpiredItems() <br />
**In:** Takes in the user item array index of the item to be listed <br />
**Out:** Returns true if the item is successfully listed to the market, returns false if the item is not found, the user is unregistered, or the user has 50 items listed already <br />

### unlistItemFromMarket(uint256 index)
**Use:** Unlists an item owned by the caller from the market and returns the item to the user's collection and calls handleExpiredItems() <br />
**In:** Takes in the index of the item in the market list <br />
**Out:** Returns true if the item is unlisted successfully, returns false if the item is not found in the market, the caller does not own the item, or the caller is unregistered <br />

### viewNumActiveBids()
**Use:** Shows the number of active bids the caller has <br />
**In:** None <br />
**Out:** Returns the number of active bids the caller has, returns 0 if the caller is unregistered <br />

### viewMarket()
**Use:** Shows the items for sale in the market <br />
**In:** None <br />
**Out:** Returns a PrintItem array that contains the information of all items currently in the market list <br />

### viewMarketItem(uint256 index)
**Use:** Shows the information of one item in the market <br />
**In:** None <br />
**Out:** Returns a tuple containing the information of the item in the market list at the given index <br />

### placeBid(uint256 bidAmount, uint256 index)
**Use:** Places a bid on an item in the market list <br />
**In:** Takes in the amount to be bid on the item and the index of the item in the market list <br />
**Out:** Returns true if the bid is successfully placed on the item, returns false if the bid amount is not higher than the current highest bid on the item, if the user does not have enough balance to cover the bid, the item is not in the market, or if the caller is unregistered <br />









