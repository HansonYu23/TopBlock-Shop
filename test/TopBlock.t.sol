// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TopBlock.sol";

contract TopBlockTest is Test {
    TopBlock topBlock;
    address admin;
    address user;
    address otherUser;
    address extra1;

    function setUp() public {
        admin = address(this);
        user = address(0x1);
        otherUser = address(0x2);
        extra1 = address(0x3);

        topBlock = new TopBlock();

        vm.startPrank(admin);
        topBlock.registerUser();
        vm.stopPrank();
    }

    /*
    FUNCTIONAL: A user can register as both buyer and seller
    Detailed Description: This test is designed that a user can register in the system with a specific role. It ensures that the registration
    process works correctly and that the role assigned to the user is accurate. The function tests the registration functionality of the 
    "UserManagement" contract and it ensures that a user can register as both a buyer and a seller. The test starts by impersonating a user,
    calling the "registerUser" function, and then verifying the registration status and assigned role. The registerUser function should return 
    true indiciating successful registration and the viewRole function should return 1 representing that the user is registered. 
    */
    function testRegisterUser() public {
        vm.startPrank(user);
        bool registered = topBlock.registerUser();
        uint8 role = topBlock.viewRole();
        vm.stopPrank();
        assertEq(registered, true, "User should be registered");
        assertEq(role, 1, "User's role should be 1");
    }

    /*
    SECURITY: A registered user cannot re-register (Constant registration can allow masked addresses to take malicious actions)
    Detailed Description: This test is designed to verify that a registered user account cannot re-register and ensures the integrity
    of the registration process by preventing multiple registrations from the same address. This prevents users from registering multiple
    times, which could be used for malicious purposes such as evading bans, exploiting rewards, or skewing user metrics and ensures that 
    the system accurately maintains unique user identities. The first call to registerUser should succeed, indicating the user registered. 
    The second call to registerUser should fail, returning false, indicating that re-registration is not allowed. If the test fails, it means 
    that users can register multiple times using the same address which could lead to security vulnerabilities where attackers exploit multiple
    registrations, inflated user statistics, misleading stakeholders, potential misuse of resources or benefits intended for new users, and 
    increased risk of bypassing system restrictions and conducting fraudulent activities. 
    */
    function sec_UserRegistersTwice() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool reg2 = topBlock.registerUser();
        vm.stopPrank();
        assertEq(reg2, false, "User was allowed to register");
    }


    /*
    FUNCTIONAL: Add balance to user with correct role
    Detailed Description: This test is designed to verify the functionality of adding a balance to a registered user's account and it ensures that only 
    a user with the correct role can add blanace and that the balance is updated correctly. The user must be registered before they can add a balance and 
    the addBalance function is responsisble for adding the specified amount to the user's account so this test verifies both the return value of addBalance 
    and the actual balance in the user's account after the addition. The user should be able to register successfully without errors and the addBalance 
    function should return true, indicating that the balance addition was successful. The user's balance should reflect the added amount, which in this case
    is 180. 
    */
    function testAddBalance() public {
        vm.startPrank(user);
        topBlock.registerUser();
        bool result = topBlock.addBalance(180);
        assertEq(result, true, "Balance deposit failed");
        uint256 balance = topBlock.viewBalance();
        assertEq(balance, 180, "Balance should be 180");
        vm.stopPrank();
    }

    /*
    SECURITY: Add balance to user with incorrect role (Unauthorized user should not be able to modify balance)
    Detailed Description: This test is designed to ensure that unauthorized users cannot add balance to an account. 
    It helps maintain the security and integrity of user balances by enforcing access controls. The test verifies that 
    the addBalance function is protected against unauthorized access and it ensures that only users with the correct 
    role or permissions can modify the balance of an account, preventing potential misuse or theft of funds. The addBalance
    function should return false when an unauthorized user (who is not registered) attempts to add balance. The balance of the
    user account should remain unchanged confirming that unauthorized actions do not affect the account. If the test fails, it 
    means that unauthorized users can add balance to accounts, which could lead to financial loss due to unauthorized access to funds,
    exploitation of the system by malicious actors, compromised integrity and trust in the system, as it would be vulnerable to fraudulent 
    activities and attacks. 
    */
    function testAddBalanceUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = topBlock.addBalance(100);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to add balance");
        assertEq(balance, 0, "Balance should remain 0 for unauthorized user");
    }

    /*
    FUNCTIONAL: Withdraw balance from user with sufficient balance
    Detailed Description: This test is designed to verify the functionality of withdrawing balance from a user account that has sufficient funds. 
    It ensures that the withdrawal process works correctly and updates the balance as expected. The user must be registered before they can add 
    or withdraw balance. The user user must have a sufficient balance before attempting to withdraw. The withdrawBalance function is responsible for 
    subtracting the specified amount from the user's account balance. The test verifies both the return value of withdrawBalance and the actual balance 
    in the user's account after the withdrawal. The user should be able to register and add balance to their account successfully and the withdrawBalance
    function should return true, indicating that the withdrawal was successful. The user's balance should be updated to reflect the withdrawal showing the
    remaining balance. 
    */
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

    /*
    SECURITY: Withdraw balance from user with insufficient balance (User cannot take more money than they have)
    Detailed Description: This test is designed to ensure that users cannot withdraw more money than they have in their balance and ensures 
    that the withdrawal function correctly handles insufficient balance scenarios and maintains financial integrity. This test ensures that users
    cannot exploit the system by withdrawing more funds than they have and ensures that the system accurately tracks and manages user balances, 
    preventing overdrawing. The withdrawBalance function should return false when a user attempts to withdraw more than their available balance. 
    The user's balance should remain unchanged after the failed withdrawal attempt. If the test fails, it indicates that the user might be able to 
    withdraw more money than they have leading to finanical loss for the system due to unauthorized withdrawals and exploitation of the withdrawal
    functionality, potentially compromising the system's integrity in addition to the loss of trust in the system's ability to manage and protect
    user funds. 
    */
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

    /*
    SECURITY: Withdraw balance from unauthorized user
    Detailed description: This test ensures that an unauthorized user cannot withdraw funds from another user's account and is critical for 
    maintaining account security and preventing unauthorized access to funds. This ensures that unauthorized users cannot withdraw funds from 
    accounts they do not own and verifies that the system correctly enforces user authentication and access controls for finanical transactions.
    The withdrawBalance function should return false when called by an unauthorized user and the balance for the unauthorized user should remain
    unchanged confirming that the withdrawal attempt was not successful. If the test fails, it indicates that unauthorized users might be able to
    withdraw funds from other accounts leading to finanical loss for legitimate users due to unauthorized withdrawals, exploitation of the system by 
    malicious actors, compromising its security, and the loss of trust in the system's ability to protect user funds, as it would be vulnerable to 
    unauthorized access and manipulation. 
    */
    function testWithdrawBalanceUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = topBlock.withdrawBalance(50);
        uint256 balance = topBlock.viewBalance();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to withdraw balance");
        assertEq(balance, 0, "Balance should remain 0 for unauthorized user");
    }


    /*
    FUNCTIONAL: Add item to user cart with correct role
    Detailed description: This test ensures that a registered user with the correct role can successfully add an item to their cart. It verifies that the
    addItem function works as expected and correctly updates the cart with the new item. The user must be registered before they can add items to their 
    cart and the addItem function is responsible for adding an item to the user's cart. The test verfies both the return value of addItem and the actual
    details of the item in the user's cart. The addItem function should return true, indicating that the item was added successfully and the cart size 
    should be updated to 1, reflecting the new item in the cart. The details of the item (ID, name, description, category, low price, high price) should
    match the input values provided to the addItem function. 
    */
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

    
    /*
    SECURITY: Add item to user cart with incorrect role
    Detailed description: This test ensures that an unauthorized user cannot add an item to another user's cart. It verifies that the addItem function 
    correctly enforces access controls and prevents unauthorized modifications to user data. This test ensures that only users witht he correct role 
    (in this case, role 1) can add items to their own cart and it verifies that the system protects against unauthorized manipulation of user data, 
    maintaining consistency and trustworthiness. The addItem function should return false, indicating that the unauthorized user was not able to add an 
    item to the cart and the cart size should remain 0 for the unauthorized user, confirming that no unauthorized changes were made to the cart. If the 
    test fails, it suggests that unauthorized useres can add items to other users' carts potentially leading to data inconsistency since unauthorized items 
    could appear in user carts, impacting their shopping experience and causing confusion. This could also lead to exploitation of system features since 
    malicious users could exploit this vulnerability to manipulate data or disrupt normal operations and the loss of trust since users may lose confidence 
    in the system's ability to protect their data and enforce access controls, affecting user retention and reputation. 
    */
    function testAddItemUnauthorized() public {
        vm.startPrank(otherUser);
        bool result = topBlock.addItem("Item1", 100, 200, "A test item", "tech", 1);
        uint256 cartSize = topBlock.viewCartSize();
        vm.stopPrank();

        assertEq(result, false, "Unauthorized user should not be able to add item to the cart");
        assertEq(cartSize, 0, "Cart size should remain 0 for unauthorized user");
    }

    /*
    FUNCTIONAL/SECURITY: Add multiple items to user cart ensuring it doesn't exceed limit
    Detailed description: This test function verifies that a user can add multiple items to their cart without exceeding the cart size limit and it 
    specifically tests the behavior when attempting to exceed the cart size limit, ensuring that the system correctly prevents unauthorized cart size 
    manipulation. This ensures that the system enforces the cart size limit to prevent users from adding an excessive number of items. This protects
    against potential resource exhaustion by limited the number of items a user can add to their cart. The addItem function should return true, indicating 
    that the items (Item1) were added successfully to the cart and the cart size should be updated to 99 items after adding. Attempted to add more items
    (Item2) when the cart size limit is reached should return false, indicating that the addition failed due to the cart size limit being exceeded and the 
    cart size should remain 99 items after the failed addition attempt. If the test fails, it indicates that the system allows users to exceed their cart
    size limit leading to resource exhaustion, since users could add an unlimited number of items, consuming excessive system resources, performance issues
    since excessive items in carts could degrade system performance, affecting overall user experience, and inconsistent business rules since violation of 
    cart size limits could lead to inconsistencies in application behavior and user expectations. 
    */
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

    /* 
    FUNCTIONAL: Users can view all items in cart, SECURITY: Items appear only to owner
    Detailed description: This test function verfies that users can view all items in their cart accurately and it specifically tests the security measure 
    that ensures only the owner of the cart can view the items within it. This function uses the addItem function to add items to the carts 
    of the user and the otherUser and retreives the cart size using viewCartSize. This also retrieves the items in the cart using viewItemsInCart, 
    and ensures that items added by user are only visisble to user, and items added by otherUser are only visible to otherUser. The Items, Item1, 
    Item2, Item3, Item4 should be added successfully to the respective users' carts. The cart size for both user and otherUser should reflect the 
    correct number of items added (2 items each) and each user should be able to view their items with accurate details (ID, name, description, 
    category, prices). The items in user's cart should not be visible to otherUser and vice versa ensuring privacy and data security. If the test 
    fails, it indicates potential issues such as users may see incorrect items or sizes in their cart leading ot confusion and items added by one user 
    may be visible to another, compromising user privacy and data security.
    */

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

    /*
    FUNCTIONAL: Edit item properties successfully
    Detailed Description: This test verifies the functionality of editing item properties (low price, high price, description, name, category) 
    after adding an item to the cart. It ensures that each edit operation modifies the item properties correctly and that the updated values are 
    reflected when retrieved. This test uses the addItem function to add an item named "Item1" with initial properties (low price = 100, high price = 200, 
    description = "A test item", category = "tech"). This test uses editLowPrice, editHighPrice, editDescr, editName, editType functions to modify the item's 
    properties. This test retrieves the updated item properties using viewCartItem and verifies that they match the expected values after editing.The exepcted 
    result is the the item "Item1" should be added to the cart successfully (addItem returns true) and each edit operation (editLowPrice, editHighPrice, editDescr, 
    editName, editType) should return true, indicating that the corresponding item property was successfully updated. After editing, the retrieved item properties 
    (viewCartItem) should reflect the updated values: lowPrice should be updated to 150, highPrice should be updated to 250, desc should be updated to "Updated description",
    name should be updated to "Updated Name", category should be updated to "fashion". If the test fails, it suggests potential issues such as the fact that users may not be 
    able to modify item details as expected, impacting user experience and incorrect or outdated item details could lead to inconsistencies in the application, affecting data 
    reliability and functionality.
    */
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
        (, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) = topBlock.viewCartItem(1);
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

    /*
    FUNCTIONAL: Edit item properties with incorrect index (Expect failure)
    Detailed description: This test function verifies the behavior of the contract when attempting to edit item properties using an incorrect index. It aims to ensure that operations 
    intended to modify non-existent items fail gracefully without affecting existing data. This test uses the addItem function to add an item named "Item1" with initial properties 
    (low price = 100, high price = 200, description = "A test item", category = "tech"). This test attempts to edit item properties (low price, high price, description, name, category) 
    using respective edit functions (editLowPrice, editHighPrice, editDescr, editName, editType) with index 2, which is incorrect. This test checks that all edit operations return false, 
    indicating failure due to incorrect index. The item "Item1" should be added to the cart successfully (addItem returns true). Each edit operation (editLowPrice, editHighPrice, editDescr, editName, editType)
    should return false, indicating that the edit operation failed due to an incorrect index. If any edit operation were to unexpectedly return true, it would indicate that the contract allows modifications 
    to non-existent items. This could lead to uninteded data corruption or inconsistencies in the application, impacting user trust and data reliability. Therefore, the test ensures that such scenarios are properly 
    handled to maintain contract integrity and user confidence. 
    */
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

    /*
    FUNCTIONAL: Delete item from cart successfully
    Detailed Description: This function verifies the functionality of deleting an item from the user's cart and ensures that the delete operation correctly removes the specified item and 
    updates the cart size accordingly. This test registers a user using registerUser function to set up the test environment and adds an item named "Item1" with parameters (low price = 100, 
    high price = 200, description = "A test item", category = "tech", quantity = 1) to the user's cart using addItem function. This function deletes the item with ID 1 using the deleteItem function.
    This function checks that the delete operation returns true (deleteItem returns true), indicating successful deletion of the item. This function checks that the cart size (viewCartSize function) 
    is updated to 0 after deleting the item, confirming that the item has been removed from the cart. The item Item1 should be added to the cart successfully (addItem returns true). Deleting the item 
    with ID 1 should return true (deleteItem returns true), indicating successful deletion. The cart size (viewCartSize) should be 0 after deleting the item, confirming that it has been removed from the 
    cart. If the delete operation fails (return false) or if the cart size is not udpated correctly after deletion, it inidcates a flaw in item deletion logic. This could lead to items not being properly
    removed from users' carts, causing incorrect cart management and potential discrepancies in application functionality and therefore the test ensures that the delete functionality works as expected to 
    maintain correct cart management and user experience. 
    */
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

    /*
    FUNCTIONAL: Attempt to delete item with incorrect index (Expect failure)
    Detailed Description: The testDeleteItemIncorrectIndex function verifies the functionality of deleting an item from the user's cart with an incorrect index. It ensures that attempting 
    to delete an item with an index that does not exist in the cart fails as expected. This test helps maintain the correctness of the item deletion logic and ensures that only valid items 
    can be deleted from the cart. This function registers a user using registerUser function to set up the test environment and addItem adds an item named "Item1" with parameters (low price = 100, 
    high price = 200, description = "A test item", category = "tech", quantity = 1) to the user's cart using addItem function. This function attempts to delete an item with ID 2 (which does not exist) 
    using deleteItem function and checks that the delete operation returns false (deleteItem returns false), indicating that the deletion failed due to an incorrect index. This function checks that the 
    cart size (viewCartSize) remains unchanged (1 item) after the failed deletion, confirming that no items were removed. The item "Item1" should be added to the cart successfully (addItem returns true).
    Attempting to delete an item with ID 2 (which does not exist) should return false (deleteItem returns false), indicating that the deletion failed. The cart size (viewCartSize) should remain unchanged 
    (1 item) after the failed deletion, confirming that no items were removed. If the delete operation with an incorrect index does not fail (returns true) or modifies the cart size, it indicates a 
    flaw in the item deletion logic. This could lead to unintended deletion of items or incorrect cart management, impacting the application's reliability and user experience. Therefore, the test ensures 
    that the system correctly handles attempts to delete items with incorrect indices to maintain proper cart management and user satisfaction.
    */
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

    /*
    FUNCTIONAL: List item to market successfully
    Detailed Description: The testListToMarket function verifies the functionality of listing an item from the user's cart to the market. It ensures that after listing an item, the user's 
    cart size decreases by one and the market size increases by one, reflecting proper item management. This function registers a user using registerUser function to set up the test environment.
    The function addItem() sdds an item named "Item" with parameters (low price = 100, high price = 200, description = "A test item", category = "tech", quantity = 5) to the user's cart using addItem function.
    The listCartItemToMarket function lists the item with ID 3 to the market using listCartItemToMarket function. This function checks that the item is successfully listed to the market (listCartItemToMarket returns true).
    This function checks that the timestamp (timePosted) for the listed item in the market (viewMarketItem) is greater than 0, indicating it has been listed. This function verifies that the user's cart size 
    (viewCartSize) is decreased by 1 after listing to the market. This function also verifies that the user's cart contains 4 items (viewItemsInCart), confirming one item was removed and it also verifies that 
    the market size (viewSaleCount) is increased by 1 after listing to the market, indicating the item has been successfully added to the market for sale. The item should be listed to the market successfully (listCartItemToMarket returns true).
    The timestamp (timePosted) for the listed item should be set, indicating it has been successfully listed. The user's cart size should decrease by 1 after listing the item to the market. The user's cart should 
    contain 4 items after listing (originally 5 items). The market size should increase by 1 after listing the item, indicating successful addition of the item to the market. If the item fails to list to the market 
    (returns false), it indicates an issue with listing functionality. Incorrect timestamp (timePosted) or incorrect cart and market size changes could lead to incorrect item management. This could impact user 
    transactions and overall marketplace reliability, affecting user trust and operational integrity. Therefore, the test ensures that the system correctly handles listing items to the market to maintain proper 
    marketplace functionality and user satisfaction.
    */
    function testListToMarket() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item", 100, 200, "A test item", "tech", 5);
        bool listResult = topBlock.listCartItemToMarket(3);
        (, , , , , , uint256 timePosted) = topBlock.viewMarketItem(3);
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

    /*
    FUNCTIONAL: Attempt to list item with incorrect index (Expect failure)
    Detailed Description: The testListIncorrectIndex function verifies the functionality of handling attempts to list an item from the user's cart to the market with an incorrect index. It ensures that the 
    system correctly rejects invalid attempts to list items, thereby maintaining data integrity and preventing unintended actions in the marketplace. The registerUser() registers a user using registerUser function 
    to set up the test environment. The addItem() function adds an item named "Item" with parameters (low price = 100, high price = 200, description = "Test item", category = "tech", quantity = 1) to the user's 
    cart using addItem function. THe listCartItemtoMarket() function attempts to list the item with index 2 (which does not exist in this case) to the market using listCartItemToMarket function.
    This function checks that the attempt to list the item fails (listCartItemToMarket returns false) due to the incorrect index. This function verifies that the user's cart size (viewCartSize) remains 
    unchanged after the failed attempt to list the item. The attempt to list the item to the market with an incorrect index should fail (listCartItemToMarket returns false). 
    The user's cart size should remain 1 after the failed attempt to list the item, indicating no unintended changes to the cart. If listing an item with an incorrect index does not fail as expected, 
    it could lead to incorrect item management in the marketplace. Users might unintentionally list incorrect items or items that do not exist, affecting marketplace integrity. This could result in unexpected 
    behaviors for users interacting with the marketplace, potentially leading to confusion or financial loss. Therefore, the test ensures that the contract under test (UserManagement) correctly handles invalid 
    index scenarios in the listCartItemToMarket function to maintain robustness and user trust.
    */
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

    /*
    FUNCTIONAL: view all items in market
    Detailed description: The testViewMarket function verifies the functionality of the viewMarket function, ensuring it correctly displays all items listed in the marketplace. It tests the capability 
    of users to view items listed by themselves and other users, validating the marketplace's aggregation and display mechanism. 
    Register Users: 
        Registers user and otherUser using the registerUser function to set up the test environment.
    Add Items to Carts:
        user adds two items:
            "Item1" with parameters (low price = 100, high price = 200, description = "Test item 1", category = "tech", quantity = 1).
            "Item2" with parameters (low price = 150, high price = 250, description = "Test item 2", category = "fashion", quantity = 1).
        otherUser adds two items:
            "Item3" with parameters (low price = 200, high price = 300, description = "Test item 3", category = "food", quantity = 1).
            "Item4" with parameters (low price = 250, high price = 350, description = "Test item 4", category = "books", quantity = 1).
    List Items to Market: Lists each item from both users to the market using listCartItemToMarket function.
    View Market: Calls viewMarket function to retrieve all items currently listed in the marketplace.
    Verify Results:
        Checks that the viewMarket function returns an array (items) with a length of 4.
        Verifies that the array contains all 4 items listed by user and otherUser, confirming the correct aggregation and display of marketplace items.
    After listing all items to the market, calling viewMarket should return an array with a length of 4. The array should contain all items listed by user 
    ("Item1" and "Item2") and otherUser ("Item3" and "Item4"), demonstrating the marketplace's ability to aggregate and display items from multiple users. If the viewMarket function 
    fails to correctly display items from both users, it could indicate a flaw in the marketplace listing or retrieval mechanism. Users might not see all available items for purchase, 
    leading to a degraded user experience and potentially lost opportunities for trade. This could impact the usability and trustworthiness of the marketplace feature within the contract.
    Therefore, the test ensures that the contract under test (UserManagement) accurately manages and retrieves market items across different users to maintain marketplace integrity and functionality.
    */
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


    /*
    FUNCTIONAL: unlistItemFromMarket - successful removal from market
    Detailed Description: The testUnlistItemFromMarketSuccess function tests the functionality of unlistItemFromMarket to ensure it correctly removes an item from the marketplace when called by its owner.
    It verifies that the item is successfully unlisted from the marketplace and that the relevant state variables are updated accordingly.
    Register User: Registers user using the registerUser function to set up the test environment.
    Add Item to Cart: Adds an item "Item1" (tech category) to user's cart with specific parameters (low price = 100, high price = 200, description = "Test item 1", category = "tech", quantity = 1) using the addItem function.
    List Item to Market: Lists "Item1" to the market using listCartItemToMarket function to make it available for sale.
    Unlist Item from Market: Calls unlistItemFromMarket function to remove "Item1" from the market.
    Verify State Changes:
        unlisted should be true indicating successful removal of the item.
        saleCount should be 0 indicating no items are currently listed for sale in the market.
        cartSize should be 1 indicating the item "Item1" remains in the user's cart after being unlisted.
    After executing unlistItemFromMarket, the function should return true (unlisted) indicating that the item was successfully removed from the market. The saleCount should be 0 as there are no items 
    listed for sale in the market after the removal. The cartSize should remain 1 indicating that the item "Item1" is still in the user's cart after being unlisted from the market. If unlistItemFromMarket 
    fails to remove the item from the market, it could lead to incorrect or outdated marketplace listings. Users might see incorrect information about available items for sale, potentially causing confusion 
    or errors in trade. This could adversely affect the reliability and usability of the marketplace feature within the contract.
    */
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

    /*
    SECURITY: unlistItemFromMarket - unauthorized user
    The testUnlistItemFromMarketUnauthorized function tests the security aspect of the unlistItemFromMarket function. It specifically verifies that an unauthorized user (otherUser) 
    cannot remove an item from the marketplace that they do not own. The test ensures that attempting to call unlistItemFromMarket from an unauthorized account (otherUser) will fail. Only the user who 
    listed the item (user) should have the ability to remove it from the marketplace. 
    Register User: Registers user using the registerUser function to set up the test environment.
    Add Item to Cart: Adds an item "Item1" (tech category) to user's cart with specific parameters (low price = 100, high price = 200, description = "Test item 1", category = "tech", quantity = 1) using the addItem function.
    List Item to Market: Lists "Item1" to the market using listCartItemToMarket function to make it available for sale.
    Attempt Unauthorized Unlisting: Calls unlistItemFromMarket function from otherUser's account.
    Verify Result: Asserts that unlisted is false, indicating that the unauthorized attempt to unlist the item from the market failed.
    After attempting to call unlistItemFromMarket from otherUser, the function should return false (unlisted). The item "Item1" should remain listed in the market, as only the owner (user) can remove it. 
    If unlistItemFromMarket incorrectly allows unauthorized users (otherUser) to remove items from the market, it could lead to unauthorized modifications of marketplace listings. This could potentially 
    disrupt the integrity and fairness of the marketplace, as unauthorized users could manipulate or remove items that they do not own. Such a failure could undermine user trust in the marketplace 
    functionality provided by the contract, affecting its reliability and adoption.
    */
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

    /*
    FUNCTIONAL: unlistItemFromMarket with index out of range
    The testUnlistItemFromMarketOutOfRange function tests the functionality of the unlistItemFromMarket method when called with an index that is out of the range of items listed in the market.
    It verifies that the contract handles such out-of-range scenarios gracefully and does not allow unintended operations. 
    Register User: Registers user using the registerUser function to set up the test environment.
    Add Item to Cart: Adds an item "Item1" (tech category) to user's cart with specific parameters (low price = 100, high price = 200, description = "Test item 1", category = "tech", quantity = 1) using the addItem function.
    List Item to Market: Lists "Item1" to the market using listCartItemToMarket function to make it available for sale.
    Attempt to Unlist Out-of-Range Item: Calls unlistItemFromMarket function with an index (99) that is out of the range of items currently listed in the market.
    Verify Result: Asserts that success is false, indicating that the attempt to unlist an item with an out-of-range index failed.
    The unlistedItemFromMarket function should return false (success) and no item should be unlisted from the market because the provided index (99) does not correspond to any item currently listed in the market.
    */
    function testUnlistItemFromMarketOutOfRange() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("Item1", 100, 200, "Test item 1", "tech", 1);
        topBlock.listCartItemToMarket(1);
        bool success = topBlock.unlistItemFromMarket(99);
        vm.stopPrank();

        assertEq(success, false, "Unlisting item with index out of range should fail");
    }

    /*
    FUNTIONAL: Test if items can be bid on successfully multiple times
    Detailed description: The testSuccessfulBid function tests the functionality of bidding on an item listed in the market multiple times successfully. It aims to ensure that users can 
    place bids on the same item, and the contract correctly updates the highest bid amount (low in this case).
    Register User: Registers user using registerUser function to set up the test environment.
    Add Item to Inventory: Adds an item "item1" (category: "tech") to user's inventory with specific parameters (low price = 100, high price = 200, description = "description", category = "category", quantity = 1) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    Place Bids:
        otherUser: Registers otherUser and adds balance (180) to the account.
            Places a bid of 180 on the listed item using placeBid function.
            Verifies that the bid is successful (suc is true) and checks that the bid amount (low) on the market item is updated to 181.
        extra1: Registers extra1 and adds balance (250) to the account.
            Places a bid of 250 on the listed item using placeBid function.
            Verifies that the bid is successful (suc is true) and checks that the bid amount (low) on the market item is updated to 251.
    The item "item1" should be successfully listed in the market after listCartItemToMarket is called. Both bids placed by otherUser and extra1 should be successful (suc is true). The bid amounts 
    (low) on the market item should be updated correctly after each successful bid, reflecting the highest bid placed.
    */
    function testSuccessfulBid() public {

        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(1);
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser();
        topBlock.addBalance(180);
        bool suc = topBlock.placeBid(180, 1);
        assertEq(suc, true, "Bid did not go through");
        (, , , , uint256 low, ,) = topBlock.viewMarketItem(1);
        assertEq(low, 181, "bid didn't update??");
        vm.stopPrank();

        vm.startPrank(extra1);
        topBlock.registerUser();
        topBlock.addBalance(250);
        suc = topBlock.placeBid(250, 1);
        assertEq(suc, true, "Bid did not go through");
        (, , , , low, ,) = topBlock.viewMarketItem(1);
        assertEq(low, 251, "bid didn't update??");
        vm.stopPrank();
    }

    /*
    SECURITY: Test if failed bid if underbid
    The testBidTooLow function tests the behavior of the bidding system when users attempt to place bids that are lower than the current highest bid on an item listed in the market.
    It verifies that such underbids are correctly rejected by the contract. Underbidding: This test specifically checks if the contract prevents bids that are lower than the current highest bid from being accepted.
    Ensuring that bids are properly validated against the current highest bid is crucial for maintaining fairness in the bidding process. 
    Register User: Registers user using registerUser function to set up the test environment.
    Add Item to Inventory: Adds an item "item1" (category: "tech") to user's inventory with specific parameters (low price = 100, high price = 200, description = "description", category = "category", quantity = 1) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    Place Bids:
        otherUser: Registers otherUser and adds balance (180) to the account.
            Attempts to place a bid of 18 on the listed item using placeBid function.
            Asserts that the bid fails (suc is false) because it is lower than the current highest bid.
            Places a valid bid of 180 on the listed item using placeBid function.
            Verifies that the bid is successful (suc is true) and checks that the bid amount (low) on the market item is updated to 181.
        extra1: Registers extra1 and adds balance (250) to the account.
            Attempts to place a bid of 20 on the listed item using placeBid function.
            Asserts that the bid fails (suc is false) because it is lower than the current highest bid.
    If the test fails, it indicates that the contract does not properly validate bid amounts against the current highest bid. This could potentially allow bids 
    that are unfairly lower than the current highest bid to be accepted and could lead to manipulation of the bidding system. Ensuring correct validation of bids is crucial 
    to maintain fairness and integrity in the auction process within the smart contract.
    */
    function testBidTooLow() public {

        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(1);
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser();
        topBlock.addBalance(180);
        bool suc = topBlock.placeBid(18, 1);
        assertEq(suc, false, "Bid should not go through");
        suc = topBlock.placeBid(180, 1);
        assertEq(suc, true, "Bid did not go through");
        (, , , , uint256 low, ,) = topBlock.viewMarketItem(1);
        assertEq(low, 181, "bid didn't update??");
        vm.stopPrank();

        vm.startPrank(extra1);
        topBlock.registerUser();
        topBlock.addBalance(250);
        suc = topBlock.placeBid(20, 1);
        assertEq(suc, false, "Bid should not go through");
        vm.stopPrank();
    }

    /*
    SECURITY: User cannot buy own product
    Detailed description: The testBidByOwner function tests the behavior of the bidding system when the owner of an item attempts to bid on their own product listed in the market. It verifies 
    that the contract correctly prevents the owner from participating in bidding on their own item. This test specifically checks if the contract properly identifies and rejects bids made by 
    the owner of an item listed in the market. Ensuring that owners cannot bid on their own items is crucial to prevent unfair manipulation of bidding outcomes. Register Users: Registers user and otherUser using registerUser function to set up the test environment.
    Add Balance: Adds balance (200) to both user and otherUser using addBalance function to simulate funds for bidding.
    Add Item to Inventory: Adds an item "item1" (category: "category") to user's inventory with specific parameters (low price = 100, high price = 200, description = "description", quantity = 1) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    OtherUser Places Bid:
        Registers otherUser, adds balance (200), and attempts to place a bid of 180 on the listed item using placeBid function.
        Asserts that the bid is successful (suc is true) and checks that the bid amount (low) on the market item is updated to 181.
    User (Owner) Attempts to Place Bid:
        Registers user (owner of the item) and attempts to place a bid of 200 on the listed item using placeBid function.
        Asserts that the bid fails (suc is false) because user is the owner of the item and cannot bid on their own product.
    If the test fails, it indicates that the contract does not properly validate the ownership of items before allowing bids. This could potentially allow the owner of an item to 
    bid on their own product, leading to unfair manipulation of bidding outcomes. Ensuring correct validation of ownership and preventing self-buying is crucial to maintain fairness 
    and integrity in the auction process within the smart contract.
    */
    function testBidByOwner() public {

        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addBalance(200);
        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(1);
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser();
        topBlock.addBalance(200);
        bool suc = topBlock.placeBid(180, 1);
        assertEq(suc, true, "Bid did not go through");
        (, , , , uint256 low, ,) = topBlock.viewMarketItem(1);
        assertEq(low, 181, "bid didn't update??");
        vm.stopPrank();

        vm.startPrank(user);
        suc = topBlock.placeBid(200, 1);
        assertEq(suc, false, "Bid should not go through");
        vm.stopPrank();
    }

    /*
    SECURITY: Unregistered user cannot bid
    Detailed Description: The testBidByUnreg function tests the behavior of the bidding system when an unregistered user attempts to place a bid on an item listed in the market.
    It verifies that the contract correctly prevents unregistered users from participating in the bidding process. This test specifically checks if the contract properly identifies 
    and rejects bids made by users who are not registered. Ensuring that only registered users can bid on items is essential to prevent unauthorized participation and ensure the security of the auction system.
    Register User: Registers user using registerUser function to set up the test environment.
    Add Item to Inventory: Adds an item "item1" (category: "category") to user's inventory with specific parameters (low price = 100, high price = 200, description = "description", quantity = 1) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    Unregistered User Attempts to Place Bid:
        otherUser (unregistered) attempts to place a bid of 180 on the listed item using placeBid function.
        Asserts that the bid fails (suc is false) because otherUser is not registered and should not be allowed to bid.
    If the test fails, it indicates that the contract does not properly validate the registration status of users before allowing bids. This could potentially allow unauthorized users 
    to participate in the bidding process, leading to unfair competition and manipulation of auction outcomes. Ensuring strict validation of user registration status before allowing 
    bids is crucial to maintain the integrity and security of the auction mechanism within the smart contract.
    */
    function testBidByUnreg() public {
        vm.startPrank(user);
        topBlock.registerUser();
        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(1);
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        bool suc = topBlock.placeBid(180, 1);
        assertEq(suc, false, "Bid went through");
        vm.stopPrank();
    }


    /*
    FUNCTIONAL: Test if the buyer who pays more will eventually own the items
    Detailed description: The testSuccessfulPurchase function tests the bidding and purchase mechanism within the smart contract. It ensures that the user who places the 
    highest bid eventually wins the item listed in the market. The test also verifies that the smart contract correctly updates bid prices and manages multiple item listings. 
    Register Users: Registers user, otherUser, and extra1 using the registerUser function to simulate different users interacting with the contract.
    Add Item to Inventory: user adds an item "item1" to their inventory with specific parameters (low price = 100, high price = 200, description = "description", category = "category", quantity = 5) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    Bidding Process:
        otherUser places a bid of 180 on the listed item using placeBid function.
        Asserts that the bid is successful (suc is true), and checks that the bid updates the item's low price to 181 and time to 1.
        extra1 places a bid of 250 on the listed item using placeBid function.
        Asserts that the bid is successful (suc is true), and checks that the bid updates the item's low price to 251.
    Listing Additional Items: user lists additional items (2, 3, and 4) to the market using listCartItemToMarket function.
    Verification:
        extra1 verifies the total time recorded (count) and asserts that it equals 15.
        Checks that extra1's cart size is 1, indicating the successful purchase and retention of one item in the cart.
    The test simulates a scenario where multiple users participate in bidding for an item. It ensures that the user who places the highest bid (250) eventually owns the item.
    The test verifies all bid updates (low price) and item listings (time recorded) are accurately reflected in the smart contract state. Asserts that all operations related to 
    bidding, listing, and verification produce the expected outcomes, demonstrating the correctness of the contract's purchase mechanism.
    */
    function testSuccessfulPurchase() public {
        vm.startPrank(user);
        topBlock.registerUser(); //1

        topBlock.addItem("item1", 100, 200, "description", "category", 5);
        topBlock.listCartItemToMarket(1); //3
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser(); //4
        topBlock.addBalance(180);
        bool suc = topBlock.placeBid(180, 1); //6
        assertEq(suc, true, "Bid did not go through");
        (, , , , uint256 low, ,uint256 time) = topBlock.viewMarketItem(1);
        assertEq(time, 1, "time wrong");
        assertEq(low, 181, "bid didn't update??");
        vm.stopPrank();

        vm.startPrank(extra1);
        topBlock.registerUser(); //7
        topBlock.addBalance(250);
        suc = topBlock.placeBid(250, 1); //9
        assertEq(suc, true, "Bid did not go through");
        (, , , , low, ,) = topBlock.viewMarketItem(1);
        assertEq(low, 251, "bid didn't update??");
        vm.stopPrank();

        vm.startPrank(user);
        topBlock.listCartItemToMarket(2); //11
        topBlock.listCartItemToMarket(3); //13
        topBlock.listCartItemToMarket(4); //15
        vm.stopPrank();

        vm.startPrank(extra1);
        uint256 count = topBlock.viewTime();
        assertEq(count, 15, "count error");
        uint256 cartSize = topBlock.viewCartSize();
        assertEq(cartSize, 1, "where is the item");
        vm.stopPrank();
    }

    /*
    FUNCTIONAL: Buyer can place item for resale
    Detailed Description: The testSuccessfulResale function tests the resale functionality within the smart contract. It verifies that a user who purchases an 
    item from the market can subsequently list it for resale. The test ensures that the resale process maintains the integrity of market listings and allows new bids on relisted items. 
    Register Users: Registers user, otherUser, and extra1 using registerUser function to simulate different users interacting with the contract.
    Add Item to Inventory: user adds an item "item1" to their inventory with specific parameters (low price = 100, high price = 200, description = "description", category = "category", quantity = 5) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    Bidding Process:
        otherUser places a bid of 180 on the listed item using placeBid function.
        user lists additional items (2, 3, 4, and 5) to the market using listCartItemToMarket function.
    Verification:
        otherUser verifies the total time recorded (count) and asserts that it equals 14.
        Checks that otherUser's cart size is 1, indicating the successful purchase and retention of one item in the cart.
        otherUser relists "item1" to the market using listCartItemToMarket function.
        otherUser adds a new item "item2" to their inventory with the same parameters as "item1".
    Bidding on Relisted Item:
        extra1 registers as a user and adds a balance of 200.
        extra1 places a bid of 200 on "item1" using placeBid function.
    Additional Listings:
        otherUser lists additional items (6, 7, 8, and 9) to the market using listCartItemToMarket function.
    Verification:
        extra1 verifies their cart size and asserts it is 1, indicating the successful purchase and retention of one item in the cart after the resale process.
    The test simulates a scenario where otherUser purchases "item1" and subsequently relists it for resale. It ensures that extra1 can bid on the relisted item "item1" 
    and that the item remains correctly listed in the market after relisting. The test verifies all market listing operations, including relisting and adding new items, 
    produce the expected outcomes, demonstrating the correctness of the contract's resale functionality.
    */
    function testSuccessfulResale() public {
        vm.startPrank(user);
        topBlock.registerUser(); //1

        topBlock.addItem("item1", 100, 200, "description", "category", 5);
        topBlock.listCartItemToMarket(1); //3
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser(); //4
        topBlock.addBalance(180);
        topBlock.placeBid(180, 1); //6
        vm.stopPrank();

        vm.startPrank(user);
        topBlock.listCartItemToMarket(2); //8
        topBlock.listCartItemToMarket(3); //10
        topBlock.listCartItemToMarket(4); //12
        topBlock.listCartItemToMarket(5); //14
        vm.stopPrank();

        vm.startPrank(otherUser);
        uint256 count = topBlock.viewTime();
        assertEq(count, 14, "count error");
        uint256 cartSize = topBlock.viewCartSize();
        assertEq(cartSize, 1, "where is the item");
        topBlock.listCartItemToMarket(1);  //relist item
        topBlock.addItem("item2", 100, 200, "description", "category", 5);
        vm.stopPrank();

        vm.startPrank(extra1);
        topBlock.registerUser();
        topBlock.addBalance(200);
        topBlock.placeBid(200, 1);
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.listCartItemToMarket(6);
        topBlock.listCartItemToMarket(7);
        topBlock.listCartItemToMarket(8);
        topBlock.listCartItemToMarket(9);
        vm.stopPrank();

        vm.startPrank(extra1);
        cartSize = topBlock.viewCartSize();
        assertEq(cartSize, 1, "where is the item");
        vm.stopPrank();
    }

    /*
    FUNCTIONAL: Returns to seller if timed out with no bids
    Detailed Description: The testSuccessfulItemReturn function tests the behavior of the contract when an item listed in the market receives no bids within a certain time period.
    It ensures that items are correctly returned to the seller's inventory if they expire without any bids.
    Register Users: Registers user and otherUser using registerUser function to simulate different users interacting with the contract.
    Add Item to Inventory: user adds an item "item1" to their inventory with specific parameters (low price = 100, high price = 200, description = "description", category = "category", quantity = 1) using addItem function.
    List Item to Market: Lists "item1" to the market using listCartItemToMarket function to make it available for bidding.
    Verify Market Listing: Asserts that the item is correctly listed in the market by checking the length of marketItems.
    Other User Listings: otherUser adds five more "item1" to their inventory with the same parameters and lists them to the market using listCartItemToMarket function.
    Verification:
        Verifies that user's cart size is 1, indicating the successful listing of "item1" to the market.
        Ensures that the seller's inventory remains correctly updated after listing "item1" to the market.
    The test should simulate a scenario where user lists "item1" to the market and verifies its presence. It ensures that otherUser successfully lists multiple "item1" to the market.
    The test verifies that user's cart size is 1, indicating the successful listing of "item1". Overall, it validates that the contract correctly handles the listing of items 
    to the market and ensures that the seller's inventory is properly managed during and after market interactions.
    */
    function testSuccessfulItemReturn() public {
        vm.startPrank(user);
        topBlock.registerUser(); //1
        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(1); //3
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser(); //4
        topBlock.addItem("item1", 100, 200, "description", "category", 5);
        topBlock.listCartItemToMarket(2); //6
        topBlock.listCartItemToMarket(3); //8
        topBlock.listCartItemToMarket(4); //10
        topBlock.listCartItemToMarket(5); //12
        topBlock.listCartItemToMarket(6); //14
        vm.stopPrank();

        vm.startPrank(user);
        uint256 cartSize = topBlock.viewCartSize();
        assertEq(cartSize, 1, "where is the item");
        vm.stopPrank();
    }

    /*
    SECURITY: Buyer doesn't have enough money at sale point
    Detailed description: The testLostMoney function tests the contract's behavior when a buyer attempts to purchase items from the market without having sufficient funds in their balance.
    It ensures that the contract correctly prevents unauthorized purchases and maintains the integrity of financial transactions within the bidding system.
    Unauthorized Purchases: Ensures that buyers cannot proceed with purchases if they do not have enough funds in their account.
    Financial Risk Mitigation: Tests the contract's ability to handle financial transactions securely and mitigate risks associated with unauthorized transactions.
    Expected Result:
        user registers and lists "item1" to the market.
        otherUser registers, adds "item1" to their inventory, and lists it to the market.
        extra1 registers, adds sufficient balance, places bids on market items, and lists additional items to the market.
        Verifies that otherUser's cart size is 1, indicating the successful listing of "item1" to the market.
        Overall, the test ensures that the contract correctly handles market interactions and financial transactions, maintaining fairness and security in the bidding process.
    If the test fails, it indicates a potential vulnerability where buyers could bypass the contract's financial checks and make unauthorized purchases. This could lead to financial 
    losses for sellers, incorrect handling of inventory, and compromise the integrity of the bidding system by allowing unauthorized transactions.
    */
    function testLostMoney() public {
        vm.startPrank(user);
        topBlock.registerUser(); //1

        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(1); //3   item1 = 1
        TopBlock.PrintItem[] memory marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 1, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(otherUser);
        topBlock.registerUser(); //4
        topBlock.addItem("item1", 100, 200, "description", "category", 1);
        topBlock.listCartItemToMarket(2); //6  item2 = 4
        marketItems = topBlock.viewMarket();
        assertEq(marketItems.length, 2, "Item should be listed in the market");
        vm.stopPrank();

        vm.startPrank(extra1);
        topBlock.registerUser(); //7
        topBlock.addBalance(200);
        topBlock.placeBid(200, 1); //9
        topBlock.placeBid(200, 2); //11
        topBlock.addItem("item1", 100, 200, "description", "category", 5);
        topBlock.listCartItemToMarket(3); //15
        topBlock.listCartItemToMarket(4); //17
        topBlock.listCartItemToMarket(5);
        vm.stopPrank();

        vm.startPrank(otherUser);
        uint256 cartSize = topBlock.viewCartSize();
        assertEq(cartSize, 1, "where is the item");
        vm.stopPrank();
    }
}
