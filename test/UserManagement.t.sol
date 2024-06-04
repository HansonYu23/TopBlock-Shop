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



    function testAddItem() public {
        vm.startPrank(user);
        bool registered = userManagement.registerUser();
        bool added = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(registered, true, "User should be registered");
        assertEq(added, true, "Item should be added to the cart");
        assertEq(cartSize, 1, "Cart size should be 1");
    }

    function testEditItem() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);

        bool editedLowPrice = userManagement.editLowPrice(1, 150);
        bool editedHighPrice = userManagement.editHighPrice(1, 250);
        bool editedDesc = userManagement.editDescr(1, "An updated test item");
        bool editedName = userManagement.editName(1, "NewItem1");
        bool editedType = userManagement.editType(1, "fashion");

        assertEq(editedLowPrice, true, "Low price should be updated");
        assertEq(editedHighPrice, true, "High price should be updated");
        assertEq(editedDesc, true, "Description should be updated");
        assertEq(editedName, true, "Name should be updated");
        assertEq(editedType, true, "Category should be updated");

        (, string memory name, string memory desc, string memory category, uint256 lowPrice, uint256 highPrice) = userManagement.viewCartItem(1);
        assertEq(lowPrice, 150, "Low price should be 150");
        assertEq(highPrice, 250, "High price should be 250");
        assertEq(desc, "An updated test item", "Description should be updated");
        assertEq(name, "NewItem1", "Name should be updated");
        assertEq(category, "fashion", "Category should be updated");
        vm.stopPrank();

    }

    function testListCartItemToMarket() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);

        bool listed = userManagement.listCartItemToMarket(1);
        uint256 saleCount = userManagement.viewSaleCount();
        UserManagement.PrintItem[] memory market = userManagement.viewMarket();
        vm.stopPrank();

        assertEq(listed, true, "Item should be listed in the market");
        assertEq(saleCount, 1, "Sale count should be 1");
        assertEq(market.length, 1, "Market should have 1 item");
        assertEq(market[0].id, 1, "Market item ID should be 1");
    }

    function testUnlistItemFromMarket() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        userManagement.listCartItemToMarket(1);

        bool unlisted = userManagement.unlistItemFromMarket(1);
        uint256 saleCount = userManagement.viewSaleCount();
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(unlisted, true, "Item should be unlisted from the market");
        assertEq(saleCount, 0, "Sale count should be 0");
        assertEq(cartSize, 1, "Cart size should be 1");
    }

    function testDeleteItem() public {
        vm.startPrank(user);
        userManagement.registerUser();
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);

        bool deleted = userManagement.deleteItem(1);
        uint256 cartSize = userManagement.viewCartSize();
        vm.stopPrank();

        assertEq(deleted, true, "Item should be deleted from the cart");
        assertEq(cartSize, 0, "Cart size should be 0");
    }
}
