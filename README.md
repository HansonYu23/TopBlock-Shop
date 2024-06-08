## TopBlock Shop

## Setup and Initialization

```shell
$ forge build
$ forge test
```

## Function Information

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
**Out:** Returns the number of active bides the caller has, returns 0 if the caller is unregistered <br />

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









