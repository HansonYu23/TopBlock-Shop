// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TopBlock.sol";

contract TopBlockTest is Test {
    TopBlock topBlock;
    address admin;
    address user;
    address otherUser;

    function setUp() public {
        admin = address(this);
        user = address(0x1);
        otherUser = address(0x2);

        topBlock = new TopBlock();

        vm.startPrank(admin);
        topBlock.registerUser();
        vm.stopPrank();
    }

    //FUNCTIONAL: A user can register as both buyer and seller

    function testRegisterUser() public {
        vm.startPrank(user);
        bool registered = topBlock.registerUser();
        uint8 role = topBlock.viewRole();
        vm.stopPrank();
        assertEq(registered, true, "User should be registered");
        assertEq(role, 1, "User's role should be 1");
    }

    //SECURITY: A registered user cannot re-register (Constant registration can allow masked addresses to take malicious actions)
    function sec_UserRegistersTwice() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool reg2 = topBlock.registerUser();
        vm.stopPrank();
        assertEq(reg2, false, "User was allowed to register");
    }

    // FUNCTIONAL: Add balance to user with correct role
    function testAddBalance() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool result = topBlock.addBalance(100);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, true, "Balance deposit failed");
        assertEq(balance, 100, "Balance should be 100");
    }

    // SECURITY: Add balance to user with incorrect role (Unauthorized user should not be able to modify balance)
    function testAddBalanceUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = topBlock.addBalance(100);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to add balance");
        assertEq(balance, 0, "Balance should remain 0 for unauthorized user");
    }

    // FUNCTIONAL: Withdraw balance from user with sufficient balance
    function testWithdrawBalance() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addBalance(100);
        bool result = topBlock.withdrawBalance(50);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, true, "Balance should be withdrawn successfully");
        assertEq(balance, 50, "Balance should be 50 after withdrawal");
    }

    // SECURITY: Withdraw balance from user with insufficient balance (User cannot take more money than they have)
    function testWithdrawInsufficientBalance() public {
        // Register the user
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addBalance(50);
        bool result = topBlock.withdrawBalance(100);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Withdrawal should fail due to insufficient balance");
        assertEq(balance, 50, "Balance should remain 50 after failed withdrawal");
    }

    // SECURITY: Withdraw balance from unauthorized user
    function testWithdrawBalanceUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = topBlock.withdrawBalance(50);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to withdraw balance");
        assertEq(balance, 0, "Balance should remain 0 for unauthorized user");
    }



    // FUNCTIONAL: Add item to user cart with correct role
    function testAddItem() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        uint256 cartSize = topBlock.viewCartSize();
        (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) = topBlock.viewCartItem(1);
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
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        uint256 cartSize = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to add item to the cart");
        assertEq(cartSize, 0, "Cart size should remain 0 for unauthorized user");
    }

    // FUNCTIONAL/SECURITY: Add multiple items to user cart ensuring it doesn't exceed limit
    function testAddMultipleItems() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 99);
        uint256 cartSize = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(result, true, "Items should be added to the cart successfully");
        assertEq(cartSize, 99, "Cart size should be 99 after adding the items");

        // SECURITY: Test exceeding the cart limit
        vm.startPrank(user);
        result = topBlock.addItem("Item2", 100, 200, "Another test item", "tech", 2);
        cartSize = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(result, false, "Adding items should fail due to cart size limit");
        assertEq(cartSize, 99, "Cart size should remain 99 after failed addition");
    }

    // FUNCTIONAL: Users can view all items in cart, SECURITY: Items appear only to owner
    function testViewCarts() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool result1 = topBlock.addItem("Item1", 100, 200, "A test item 1", "tech", 1);
        bool result2 = topBlock.addItem("Item2", 150, 250, "A test item 2", "fashion", 1);

        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser();
        bool result3 = topBlock.addItem("Item3", 100, 200, "A test item 1", "tech", 1);
        bool result4 = topBlock.addItem("Item4", 150, 250, "A test item 2", "fashion", 1);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 cartSize1 = topBlock.viewCartSize();
        TopBlock.PrintItem[] memory items1 = topBlock.viewItemsInCart();
        vm.stopPrank();

        vm.startPrank(otherUser);
        uint256 cartSize2 = topBlock.viewCartSize();
        TopBlock.PrintItem[] memory items2 = topBlock.viewItemsInCart();
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
        topBlock.registerUser();
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");
        
        // Edit item properties
        bool editLowPriceResult = topBlock.editLowPrice(1, 150);
        bool editHighPriceResult = topBlock.editHighPrice(1, 250);
        bool editDescrResult = topBlock.editDescr(1, "Updated description");
        bool editNameResult = topBlock.editName(1, "Updated Name");
        bool editTypeResult = topBlock.editType(1, "fashion");
        (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) = topBlock.viewCartItem(1);
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
        topBlock.registerUser();
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");

        bool editLowPriceResult = topBlock.editLowPrice(2, 150);
        bool editHighPriceResult = topBlock.editHighPrice(2, 250);
        bool editDescrResult = topBlock.editDescr(2, "Updated description");
        bool editNameResult = topBlock.editName(2, "Updated Name");
        bool editTypeResult = topBlock.editType(2, "fashion");

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
        topBlock.registerUser();
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");
        bool deleteResult = topBlock.deleteItem(1);
        uint256 s = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(deleteResult, true, "Item should be deleted successfully");
        assertEq(s, 0, "Cart size should be 0 after deleting the item");
    }

    // FUNCTIONAL: Attempt to delete item with incorrect index (Expect failure)
    function testDeleteItemIncorrectIndex() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(result, true, "Item should be added to the cart successfully");
        bool deleteResult = topBlock.deleteItem(2);
        uint256 s = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(deleteResult, false, "Item deletion with incorrect index should fail");
        assertEq(s, 1, "Cart size should remain unchanged");
    }

    // FUNCTIONAL: List item to market successfully
    function testListToMarket() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item", 100, 200, "A test item", "tech", 5);
        bool listResult = topBlock.listCartItemToMarket(3);
        (uint256 id, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice, uint256 timePosted) = topBlock.viewMarketItem(3);
        uint256 cartSize = topBlock.viewCartSize();
        uint256 marketSize = topBlock.viewSaleCount();
        TopBlock.PrintItem[] memory items = topBlock.viewItemsInCart();
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
        topBlock.registerUser();
        topBlock.addItem("Item", 100, 200, "Test item", "tech", 1);
        bool listResult = topBlock.listCartItemToMarket(2);
        uint256 cartSize = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(listResult, false, "Listing item to market with incorrect index should fail");
        assertEq(cartSize, 1, "Cart size should remain 1 after failed listing to market");
    }

    //FUNCTIONAL: view all items in market
    function testViewMarket() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        topBlock.addItem("Item2", 150, 250, "Test item 2", "fashion", 1);
        topBlock.listCartItemToMarket(1);
        topBlock.listCartItemToMarket(2);
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser();
        topBlock.addItem("Item3", 200, 300, "Test item 3", "food", 1);
        topBlock.addItem("Item4", 250, 350, "Test item 4", "books", 1);
        topBlock.listCartItemToMarket(3);
        topBlock.listCartItemToMarket(4);
        TopBlock.PrintItem[] memory items = topBlock.viewMarket();
        vm.stopPrank();

        assertEq(items.length, 4, "Market should contain all items from both users");
    }


    // FUNCTIONAL: unlistItemFromMarket - successful removal from market
    function testUnlistItemFromMarketSuccess() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        topBlock.listCartItemToMarket(1);
        bool unlisted = topBlock.unlistItemFromMarket(1);
        uint256 saleCount = topBlock.viewSaleCount();
        uint256 cartSize = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(unlisted, true, "Item should be unlisted from the market");
        assertEq(saleCount, 0, "Sale count should be 0");
        assertEq(cartSize, 1, "Cart size should be 1");
    }

    // SECURITY: unlistItemFromMarket - unauthorized user
    function testUnlistItemFromMarketUnauthorized() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        topBlock.listCartItemToMarket(1);
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser();
        bool unlisted = topBlock.unlistItemFromMarket(1);
        vm.stopPrank();
        assertEq(unlisted, false, "Unregistered user should not be able to unlist item from market");
    }

    // FUNCTIONAL: unlistItemFromMarket with index out of range
    function testUnlistItemFromMarketOutOfRange() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        topBlock.listCartItemToMarket(1);
        bool success = topBlock.unlistItemFromMarket(99);
        vm.stopPrank();

        assertEq(success, false, "Unlisting item with index out of range should fail");
    }

}
