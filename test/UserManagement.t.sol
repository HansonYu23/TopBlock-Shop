// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UserManagement.sol";

contract UserManagementTest is Test {
    UserManagement userManagement;
    address admin;
    address user;
    address otherUser;

    function setUp() public {
        admin = address(this);
        user = address(0x1);
        otherUser = address(0x2);

        userManagement = new UserManagement();

        vm.startPrank(admin);
        userManagement.registerUser();
        vm.stopPrank();
    }

    //FUNCTIONAL: A user can register as both buyer and seller

    function testRegisterUser() public {
        vm.startPrank(user);
        bool registered = userManagement.registerUser();
        uint8 role = userManagement.viewRole();
        vm.stopPrank();
        assertEq(registered, true, "User should be registered");
        assertEq(role, 1, "User's role should be 1");
    }

    //SECURITY: A registered user cannot re-register (Constant registration can allow masked addresses to take malicious actions)
    function sec_UserRegistersTwice() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool reg2 = userManagement.registerUser();
        vm.stopPrank();
        assertEq(reg2, false, "User was allowed to register");
    }

    // FUNCTIONAL: Add balance to user with correct role
    function testAddBalance() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addBalance(100);
        uint256 balance = userManagement.viewBalance();
        vm.stopPrank();

        assertEq(result, true, "Balance deposit failed");
        assertEq(balance, 100, "Balance should be 100");
    }

    // SECURITY: Add balance to user with incorrect role (Unauthorized user should not be able to modify balance)
    function testAddBalanceUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = userManagement.addBalance(100);
        uint256 balance = userManagement.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to add balance");
        assertEq(balance, 0, "Balance should remain 0 for unauthorized user");
    }

    // FUNCTIONAL: Withdraw balance from user with sufficient balance
    function testWithdrawBalance() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addBalance(100);
        bool result = userManagement.withdrawBalance(50);
        uint256 balance = userManagement.viewBalance();
        vm.stopPrank();

        assertEq(result, true, "Balance should be withdrawn successfully");
        assertEq(balance, 50, "Balance should be 50 after withdrawal");
    }

    // SECURITY: Withdraw balance from user with insufficient balance (User cannot take more money than they have)
    function testWithdrawInsufficientBalance() public {
        // Register the user
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addBalance(50);
        bool result = userManagement.withdrawBalance(100);
        uint256 balance = userManagement.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Withdrawal should fail due to insufficient balance");
        assertEq(balance, 50, "Balance should remain 50 after failed withdrawal");
    }

    // SECURITY: Withdraw balance from unauthorized user
    function testWithdrawBalanceUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = userManagement.withdrawBalance(50);
        uint256 balance = userManagement.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to withdraw balance");
        assertEq(balance, 0, "Balance should remain 0 for unauthorized user");
    }



    // FUNCTIONAL: Add item to user cart with correct role
    function testAddItem() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        uint256 cartSize = userManagement.viewCartSize();
        (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) = userManagement.viewCartItem(1);
        vm.stopPrank();

        assertEq(result, true, "Item should be added to the cart successfully");
        assertEq(cartSize, 1, "Cart size should be 1 after adding the item");
        assertEq(id, 1, "Item ID should be 1");
        assertEq(name, "Item1", "Item name should be 'Item1'");
        assertEq(desc, "A test item", "Item description should be 'A test item'");
        assertEq(category, "tech", "Item category should be 'tech'");
        assertEq(lowPrice, 100, "Item low price should be 100");
        assertEq(highPrice, 200, "Item high price should be 200");
    }

    // SECURITY: Add item to user cart with incorrect role
    function testAddItemUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to add item to the cart");
        assertEq(cartSize, 0, "Cart size should remain 0 for unauthorized user");
    }

    // FUNCTIONAL/SECURITY: Add multiple items to user cart ensuring it doesn't exceed limit
    function testAddMultipleItems() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 99);
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(result, true, "Items should be added to the cart successfully");
        assertEq(cartSize, 99, "Cart size should be 99 after adding the items");

        // SECURITY: Test exceeding the cart limit
        vm.startPrank(user);
        result = userManagement.addItem("Item2", 100, 200, "Another test item", "tech", 2);
        cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(result, false, "Adding items should fail due to cart size limit");
        assertEq(cartSize, 99, "Cart size should remain 99 after failed addition");
    }

    // FUNCTIONAL: Users can view all items in cart, SECURITY: Items appear only to owner
    function testViewCarts() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result1 = userManagement.addItem("Item1", 100, 200, "A test item 1", "tech", 1);
        bool result2 = userManagement.addItem("Item2", 150, 250, "A test item 2", "fashion", 1);

        vm.stopPrank();

        vm.startPrank(otherUser);
        userManagement.registerUser();
        bool result3 = userManagement.addItem("Item3", 100, 200, "A test item 1", "tech", 1);
        bool result4 = userManagement.addItem("Item4", 150, 250, "A test item 2", "fashion", 1);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 cartSize1 = userManagement.viewCartSize();
        UserManagement.PrintItem[] memory items1 = userManagement.viewItemsInCart();
        vm.stopPrank();

        vm.startPrank(otherUser);
        uint256 cartSize2 = userManagement.viewCartSize();
        UserManagement.PrintItem[] memory items2 = userManagement.viewItemsInCart();
        vm.stopPrank();

        assertEq(result1, true, "First item should be added to the cart successfully");
        assertEq(result2, true, "Second item should be added to the cart successfully");
        assertEq(result3, true, "Third item should be added to the cart successfully");
        assertEq(result4, true, "Fourth item should be added to the cart successfully");
        assertEq(cartSize1, 2, "Cart size 1 should be 2 after adding two items");
        assertEq(cartSize2, 2, "Cart size 2 should be 2 after adding two items");
        assertEq(items1.length, 2, "Cart should contain 2 items");
        assertEq(items2.length, 2, "Cart should contain 2 items");
        
        // First item
        assertEq(items1[0].id, 1, "First cart item ID should be 1");
        assertEq(items1[0].name, "Item1", "First cart item name should be 'Item1'");
        assertEq(items1[0].desc, "A test item 1", "First cart item description should be 'A test item 1'");
        assertEq(items1[0].category, "tech", "First cart item category should be 'tech'");
        assertEq(items1[0].lowPrice, 100, "First cart item low price should be 100");
        assertEq(items1[0].highPrice, 200, "First cart item high price should be 200");
        
        // Second item
        assertEq(items1[1].id, 2, "Second cart item ID should be 2");
        assertEq(items1[1].name, "Item2", "Second cart item name should be 'Item2'");
        assertEq(items1[1].desc, "A test item 2", "Second cart item description should be 'A test item 2'");
        assertEq(items1[1].category, "fashion", "Second cart item category should be 'fashion'");
        assertEq(items1[1].lowPrice, 150, "Second cart item low price should be 150");
        assertEq(items1[1].highPrice, 250, "Second cart item high price should be 250");

        // Third item
        assertEq(items2[0].id, 3, "First cart item ID should be 3");
        assertEq(items2[0].name, "Item3", "First cart item name should be 'Item3'");
        assertEq(items2[0].desc, "A test item 1", "First cart item description should be 'A test item 1'");
        assertEq(items2[0].category, "tech", "First cart item category should be 'tech'");
        assertEq(items2[0].lowPrice, 100, "First cart item low price should be 100");
        assertEq(items2[0].highPrice, 200, "First cart item high price should be 200");
        
        // Fourth item
        assertEq(items2[1].id, 4, "Second cart item ID should be 4");
        assertEq(items2[1].name, "Item4", "Second cart item name should be 'Item4'");
        assertEq(items2[1].desc, "A test item 2", "Second cart item description should be 'A test item 2'");
        assertEq(items2[1].category, "fashion", "Second cart item category should be 'fashion'");
        assertEq(items2[1].lowPrice, 150, "Second cart item low price should be 150");
        assertEq(items2[1].highPrice, 250, "Second cart item high price should be 250");
    }

    // FUNCTIONAL: Edit item properties successfully
    function testEditItem() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");
        
        // Edit item properties
        bool editLowPriceResult = userManagement.editLowPrice(1, 150);
        bool editHighPriceResult = userManagement.editHighPrice(1, 250);
        bool editDescrResult = userManagement.editDescr(1, "Updated description");
        bool editNameResult = userManagement.editName(1, "Updated Name");
        bool editTypeResult = userManagement.editType(1, "fashion");
        (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) = userManagement.viewCartItem(1);
        vm.stopPrank();

        assertEq(editLowPriceResult, true, "Low price should be successfully edited");
        assertEq(editHighPriceResult, true, "High price should be successfully edited");
        assertEq(editDescrResult, true, "Description should be successfully edited");
        assertEq(editNameResult, true, "Name should be successfully edited");
        assertEq(editTypeResult, true, "Category should be successfully edited");

        assertEq(lowPrice, 150, "Low price should be updated to 150");
        assertEq(highPrice, 250, "High price should be updated to 250");
        assertEq(desc, "Updated description", "Description should be updated");
        assertEq(name, "Updated Name", "Name should be updated");
        assertEq(category, "fashion", "Category should be updated");
    }

    // FUNCTIONAL: Edit item properties with incorrect index (Expect failure)
    function testEditItemIncorrectIndex() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");

        bool editLowPriceResult = userManagement.editLowPrice(2, 150);
        bool editHighPriceResult = userManagement.editHighPrice(2, 250);
        bool editDescrResult = userManagement.editDescr(2, "Updated description");
        bool editNameResult = userManagement.editName(2, "Updated Name");
        bool editTypeResult = userManagement.editType(2, "fashion");

        vm.stopPrank();

        assertEq(editLowPriceResult, false, "Low price edit with incorrect index should fail");
        assertEq(editHighPriceResult, false, "High price edit with incorrect index should fail");
        assertEq(editDescrResult, false, "Description edit with incorrect index should fail");
        assertEq(editNameResult, false, "Name edit with incorrect index should fail");
        assertEq(editTypeResult, false, "Category edit with incorrect index should fail");
    }

    // FUNCTIONAL: Delete item from cart successfully
    function testDeleteItem() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");
        bool deleteResult = userManagement.deleteItem(1);
        uint256 s = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(deleteResult, true, "Item should be deleted successfully");
        assertEq(s, 0, "Cart size should be 0 after deleting the item");
    }

    // FUNCTIONAL: Attempt to delete item with incorrect index (Expect failure)
    function testDeleteItemIncorrectIndex() public {
        vm.startPrank(user);
        userManagement.registerUser();
        bool result = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");
        bool deleteResult = userManagement.deleteItem(2);
        uint256 s = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(deleteResult, false, "Item deletion with incorrect index should fail");
        assertEq(s, 1, "Cart size should remain unchanged");
    }

    // FUNCTIONAL: List item to market successfully
    function testListToMarket() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item", 100, 200, "A test item", "tech", 5);
        bool listResult = userManagement.listCartItemToMarket(3);
        (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice, uint256 timePosted) = userManagement.viewMarketItem(3);
        uint256 cartSize = userManagement.viewCartSize();
        uint256 marketSize = userManagement.viewSaleCount();
        UserManagement.PrintItem[] memory items = userManagement.viewItemsInCart();
        vm.stopPrank();

        assertEq(listResult, true, "Item should be listed to the market successfully");
        assertGt(timePosted, 0, "Timestamp should be set for the listed item");
        assertEq(cartSize, 4, "Cart size should be decreased by 1 after listing to market");
        assertEq(items.length, 4, "Cart size should be 4");
        assertEq(marketSize, 1, "Market size should be increased by 1 after listing to market");
    }

    // FUNCTIONAL: Attempt to list item with incorrect index (Expect failure)
    function testListIncorrectIndex() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item", 100, 200, "Test item", "tech", 1);
        bool listResult = userManagement.listCartItemToMarket(2);
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(listResult, false, "Listing item to market with incorrect index should fail");
        assertEq(cartSize, 1, "Cart size should remain 1 after failed listing to market");
    }

    //FUNCTIONAL: view all items in market
    function testViewMarket() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        userManagement.addItem("Item2", 150, 250, "Test item 2", "fashion", 1);
        userManagement.listCartItemToMarket(1);
        userManagement.listCartItemToMarket(2);
        vm.stopPrank();

        vm.startPrank(otherUser);
        userManagement.registerUser();
        userManagement.addItem("Item3", 200, 300, "Test item 3", "food", 1);
        userManagement.addItem("Item4", 250, 350, "Test item 4", "books", 1);
        userManagement.listCartItemToMarket(3);
        userManagement.listCartItemToMarket(4);
        UserManagement.PrintItem[] memory items = userManagement.viewMarket();
        vm.stopPrank();

        assertEq(items.length, 4, "Market should contain all items from both users");
    }


    // FUNCTIONAL: unlistItemFromMarket - successful removal from market
    function testUnlistItemFromMarketSuccess() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        userManagement.listCartItemToMarket(1);
        bool unlisted = userManagement.unlistItemFromMarket(1);
        uint256 saleCount = userManagement.viewSaleCount();
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(unlisted, true, "Item should be unlisted from the market");
        assertEq(saleCount, 0, "Sale count should be 0");
        assertEq(cartSize, 1, "Cart size should be 1");
    }

    // SECURITY: unlistItemFromMarket - unauthorized user
    function testUnlistItemFromMarketUnauthorized() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        userManagement.listCartItemToMarket(1);
        vm.stopPrank();

        vm.startPrank(otherUser);
        userManagement.registerUser();
        bool unlisted = userManagement.unlistItemFromMarket(1);
        vm.stopPrank();
        assertEq(unlisted, false, "Unregistered user should not be able to unlist item from market");
    }

    // FUNCTIONAL: unlistItemFromMarket with index out of range
    function testUnlistItemFromMarketOutOfRange() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        userManagement.listCartItemToMarket(1);
        bool success = userManagement.unlistItemFromMarket(99);
        vm.stopPrank();

        assertEq(success, false, "Unlisting item with index out of range should fail");
    }

    //FUNTIONAL: Test if items purchased by a buyer can be put on sell again 
    function testItemCanBePutOnSaleAgain() public {
        vm.startPrank(user);
        // Register buyer
        userManagement.registerUser();

        // Add balance to buyer
        userManagement.addBalance(1000);

        // Add item to buyer's cart
        userManagement.addItem("item1", 100, 200, "description", "category", 1);

        // List item in market
        userManagement.listCartItemToMarket(1);

        // View market to check if item is listed
        UserManagement.PrintItem[] memory marketItems = userManagement.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");

        // Unlist item from market
        userManagement.unlistItemFromMarket(1);

        // View market to check if item is unlisted
        marketItems = userManagement.viewMarket();
        assertEq(marketItems.length, 0, "Item should be unlisted from the market");
        vm.stopPrank();

    }

    //FUNCTIONAL: Test if the buyer who pays more will eventually own the items 
    function testHigherOwnsItem() public {
        vm.startPrank(user);
        //Register first buyer
        userManagement.registerUser();
        //Add balance to first buyer
        userManagement.addBalance(1000);
        vm.stopPrank();

        //Handle expired items
        //userManagement.handleExpiredItems();
        //vm.stopPrank();

        //Register and add balance for the second user 
        vm.startPrank(otherUser);
        userManagement.registerUser();
        userManagement.addBalance(1000);
        vm.stopPrank();

        //Handle expired items
        //userManagement.handleExpiredItems();

        //First user places a bid
        vm.startPrank(user);
        userManagement.addItem("item2", 100, 200, "description", "category", 1);
        //bool bidResult1 = userManagement.placeBid(150, 1);
        bool listed = userManagement.listCartItemToMarket(1);
        assertEq(listed, true, "Item should be listed in the market");
        //assertEq(bidResult1, true, "First user's bid should be successful");
        vm.stopPrank();
        //assertEq(bidResult1, true, "First user's bid should be successful");

        // First user places a bid
        vm.startPrank(user);
        bool bidResult1 = userManagement.placeBid(150, 1);
        vm.stopPrank();
        assertEq(bidResult1, true, "First user's bid should be successful");

        //Handle expired items
        //userManagement.handleExpiredItems();
        //vm.stopPrank();

        //Second user places a higher bid
        vm.startPrank(otherUser);
        bool bidResult2 = userManagement.placeBid(200, 1);
        vm.stopPrank();
        assertEq(bidResult2, true, "Second user's bid should be successful");
        //vm.stopPrank();

        //Handle expired items
        userManagement.handleExpiredItems();
        //vm.stopPrank();

        //Assertions for the first user
        vm.startPrank(user);
        assertEq(userManagement.viewNumActiveBids(), 0, "First buyer should have 0 active bids after being outbid.");
        vm.stopPrank();

        //Assertions for the second user
        vm.startPrank(otherUser);
        assertEq(userManagement.viewNumActiveBids(), 1, "Second buyer should have 1 active bid after bidding.");
        vm.stopPrank();

        (uint256 id, , , , , , ) = userManagement.viewMarketItem(1);
        assertEq(id, 1, "Item should be owned by the highest bidder");

    }

    //SECURITY TEST: Test for inadequate balance when placing a bid
    function testPlaceBidWithInadequateBalance() public {
        vm.startPrank(user);
        //Register first buyer
        userManagement.registerUser();

        //Add balance less than the bid amount 
        userManagement.addBalance(50);

        //Attempt to place a bid with an amount higher than the balance
        bool result = userManagement.placeBid(100, 1);
        vm.stopPrank();
        //Assert that the bid was not successful
        assertEq(result, false, "Bid should not be successful due to inadequate balance");
        //vm.stopPrank();
    }

    //SECURITY TEST: Test for handling expired items with no bids
    
    function testHandleExpiredItemsWithNoBids() public {
        vm.startPrank(user);
        userManagement.registerUser();
        
        // Add items to the market without any bids
        userManagement.addItem("Item 1", 100, 200, "Description 1", "Type", 1);
        userManagement.addItem("Item2", 150, 250, "Description 2", "Type 2", 2);

        // List the items in the market
        bool listed = userManagement.listCartItemToMarket(1);
        assertEq(listed, true, "Item 1 should be listed in the market");
        listed = userManagement.listCartItemToMarket(2);
        assertEq(listed, true, "Item 2 should be listed in the market");

        //Advance time to ensure both items expire
        uint256 expiryTime = block.timestamp + 2 seconds + 1;
        vm.warp(expiryTime);

        //Handle expired items
        userManagement.handleExpiredItems();

        //Verify items are returned to the user's cart 
        (uint256 idAfterHandling1, , , , , ) = userManagement.viewCartItem(1);
        (uint256 id2, , , , , ) = userManagement.viewCartItem(2);

        assertEq(idAfterHandling1, 1, "First item should be returned to user's cart");

        assertEq(id2, 2, "Second item should be returned to user's cart");
        

        vm.stopPrank();
        
    }
    












}
