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

        vm.prank(admin);
        userManagement.registerUser();
    }

    function testRegisterUser() public {
        vm.prank(user);
        bool registered = userManagement.registerUser();
        assertEq(registered, true, "User should be registered");
    }

    function testAddItem() public {
        vm.prank(user);
        bool registered = userManagement.registerUser();
        assertEq(registered, false,  "User should NOT be registered");
        vm.prank(user);
        bool added = userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        assertEq(added, true, "Item should be added to the cart");

        uint256 cartSize = userManagement.viewCartSize();
        assertEq(cartSize, 1, "Cart size should be 1");
    }

    function testEditItem() public {
        vm.prank(user);
        userManagement.registerUser();
        vm.prank(user);
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);

        vm.prank(user);
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
    }

    function testListCartItemToMarket() public {
        vm.prank(user);
        userManagement.registerUser();
        vm.prank(user);
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);

        vm.prank(user);
        bool listed = userManagement.listCartItemToMarket(1);
        assertEq(listed, true, "Item should be listed in the market");

        uint256 saleCount = userManagement.viewSaleCount();
        assertEq(saleCount, 1, "Sale count should be 1");

        UserManagement.PrintItem[] memory market = userManagement.viewMarket();
        assertEq(market.length, 1, "Market should have 1 item");
        assertEq(market[0].id, 1, "Market item ID should be 1");
    }

    function testUnlistItemFromMarket() public {
        vm.prank(user);
        userManagement.registerUser();
        vm.prank(user);
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);
        vm.prank(user);
        userManagement.listCartItemToMarket(1);

        vm.prank(user);
        bool unlisted = userManagement.unlistItemFromMarket(1);
        assertEq(unlisted, true, "Item should be unlisted from the market");

        uint256 saleCount = userManagement.viewSaleCount();
        assertEq(saleCount, 0, "Sale count should be 0");

        uint256 cartSize = userManagement.viewCartSize();
        assertEq(cartSize, 1, "Cart size should be 1");
    }

    function testDeleteItem() public {
        vm.prank(user);
        userManagement.registerUser();
        vm.prank(user);
        userManagement.addItem("Item1", 100, 200, "A test item", "tech", 1);

        vm.prank(user);
        bool deleted = userManagement.deleteItem(1);
        assertEq(deleted, true, "Item should be deleted from the cart");

        uint256 cartSize = userManagement.viewCartSize();
        assertEq(cartSize, 0, "Cart size should be 0");
    }
}
