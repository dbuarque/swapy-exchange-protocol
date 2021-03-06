pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestSwapyExchange_actions {
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    SwapyExchange throwableProtocol = SwapyExchange(address(throwProxy));
    uint256[] _assetValues;
    uint256[] _returnValues;
    address[] assets;

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;

    bytes msgData;
    function() payable public {

    }

    function shouldThrow(bool result) public {
        Assert.isFalse(result, "Should throw an exception");
    }

    // Testing the createOffer() function
    function testUserCanCreateOfferWithoutVersion() public {
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        assets = protocol.createOffer(
            bytes8(0),
            uint256(360),
            uint256(10),
            bytes5("USD"),
            _assetValues
        );
        Assert.equal(assets.length, 3, "3 Assets must be created");
        bool isOwner = (InvestmentAsset(assets[0]).owner() == address(this)) 
            && (InvestmentAsset(assets[1]).owner() == address(this)) 
            && (InvestmentAsset(assets[2]).owner() == address(this));
        Assert.equal(isOwner, true, "The test contract must be owner of the fundraising offer");
    }
    
    function testUserCanCreateOfferWithVersion() public {
        assets = protocol.createOffer(
            bytes8("1.0.0"),
            uint256(360),
            uint256(10),
            bytes5("USD"),
            _assetValues
        );
        Assert.equal(assets.length, 3, "3 Assets must be created");
        bool isOwner = (InvestmentAsset(assets[0]).owner() == address(this)) 
            && (InvestmentAsset(assets[1]).owner() == address(this)) 
            && (InvestmentAsset(assets[2]).owner() == address(this));
        Assert.equal(isOwner, true, "The test contract must be owner of the fundraising offer");
    }

    function testUserCannotCreateOfferWithAnInvalidVersion() public {
        address(throwableProtocol).call(abi.encodeWithSignature("createOffer(bytes8,uint256,uint256,bytes5,uint256[])",
            bytes8("3.0.0"),
            uint256(360),
            uint256(10),
            bytes5("USD"),
            _assetValues
        ));
        throwProxy.shouldThrow();
    }
    
    // testing invest() function
    function testUnitValueAndFundsMustMatch() public {
        address(throwableProtocol).call.value(2 ether)(abi.encodeWithSignature("invest(address[], uint256)", assets, 1 ether));
        throwProxy.shouldThrow();
    }

    function testUserCanInvest() public {
        bool result = protocol.invest.value(3 ether)(assets, 1 ether);
        Assert.equal(result, true, "Assets must be invested");
        bool isInvestor = (InvestmentAsset(assets[0]).investor() == address(this)) 
            && (InvestmentAsset(assets[1]).investor() == address(this)) 
            && (InvestmentAsset(assets[2]).investor() == address(this));
        Assert.equal(isInvestor, true, "The test contract must be the investor of these assets");
    }
    
    // Testing cancelInvestment() function
    function testOnlyInvestorCanCancelInvestment() public {
        address(throwableProtocol).call(abi.encodeWithSignature("cancelInvestment(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testInvestorCanCancelInvestment() public {
        bool result = protocol.cancelInvestment(assets);
        Assert.equal(result, true, "Investments must be canceled");
    }
    
    // Testing refuseInvestment() function
    function testOnlyOwnerCanRefuseInvestment() public {
        protocol.invest.value(3 ether)(assets, 1 ether);
        address(throwableProtocol).call(abi.encodeWithSignature("refuseInvestment(address[])", assets));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanRefuseInvestment() public {
        bool result = protocol.refuseInvestment(assets);
        Assert.equal(result, true, "Investments must be refused");
    }

    // Testing withdrawFunds() function
    function testOnlyOwnerCanWithdrawFunds() public {
        protocol.invest.value(3 ether)(assets, 1 ether);
        address(throwableProtocol).call(abi.encodeWithSignature("withdrawFunds(address[])", assets));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanWithdrawFunds() public {
        bool result = protocol.withdrawFunds(assets);
        Assert.equal(result, true, "Investments must be accepted");
    }

    // Testing sell() function
    function testOnlyInvestorCanPutOnSale() public {
        _assetValues[0] += 25;
        _assetValues[1] += 25;
        _assetValues[2] += 25;
        address(throwableProtocol).call(abi.encodeWithSignature("sellAssets(address[],uint256[])",assets, _assetValues));
        throwProxy.shouldThrow();
    }

    function testInvestorCanPutOnSale() public {
        bool result = protocol.sellAssets(assets,  _assetValues);
        Assert.equal(result, true, "Assets must be put up on sale");
    }

    // Testing cancelSellOrder() function
    function testOnlyInvestorCanRemoveOnSale() public {
        address(throwableProtocol).call(abi.encodeWithSignature("cancelSellOrder(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testInvestorCanRemoveOnSale() public {
        bool result = protocol.cancelSellOrder(assets);
        Assert.equal(result, true, "Asset must be removed for sale");
    }
    
    // Testing buy() function

    function testUserCanBuyAsset() public {
        protocol.sellAssets(assets,  _assetValues);
        bool result = protocol.buyAsset.value(1050 finney)(assets[0]);
        Assert.equal(result, true, "Asset must be bought");
    }

    // Testing cancelSale() function
    function testOnlyBuyerCanCancelPurchase() public {
        protocol.buyAsset.value(1050 finney)(assets[1]);
        protocol.buyAsset.value(1050 finney)(assets[2]);
        address(throwableProtocol).call(abi.encodeWithSignature("cancelSale(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testBuyerCanCancelPurchase() public {
        bool result = protocol.cancelSale(assets);
        Assert.equal(result, true, "Purchase must be canceled");
    }

    // Testing refuseSale() function
    function testOnlyInvestorCanRefusePurchase() public {
        protocol.buyAsset.value(1050 finney)(assets[0]);
        protocol.buyAsset.value(1050 finney)(assets[1]);
        protocol.buyAsset.value(1050 finney)(assets[2]);
        address(throwableProtocol).call(abi.encodeWithSignature("refuseSale(address[])", assets));
        throwProxy.shouldThrow();
    }
    
    function testInvestorCanRefusePurchase() public {
        bool result = protocol.refuseSale(assets);
        Assert.equal(result, true, "Purchases must be refused");
    }

    // Testing acceptSale() function
    function testOnlyInvestorCanAcceptSale() public {
        protocol.buyAsset.value(1050 finney)(assets[0]);
        protocol.buyAsset.value(1050 finney)(assets[1]);
        protocol.buyAsset.value(1050 finney)(assets[2]);
        address(throwableProtocol).call(abi.encodeWithSignature("acceptSale(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testInvestorCanAcceptSale() public {
        bool result = protocol.acceptSale(assets);
        Assert.equal(result, true, "Sales must be accepted");
    }

    //testing returnInvestment() function 
    function testOnlyOwnerCanReturnInvestment() public {
        _returnValues.push(1100 finney);
        _returnValues.push(1100 finney);
        _returnValues.push(1100 finney);
        address(throwableProtocol)
            .call
            .value(3300 finney)
            (abi.encodeWithSignature("returnInvestment(address[], uint256[])", assets, _returnValues));
        throwProxy.shouldThrow();
    }

    function testReturnValuesAndFundsMustMatch() public {
        bool result = address(protocol)
            .call
            .value(3299 finney)
            (abi.encodeWithSignature("returnInvestment(address[], uint256[])", assets, _returnValues));
        shouldThrow(result);
    }

    function testOwnerCanReturnInvestment() public {
        bool result = address(throwableProtocol)
            .call
            .value(3300 finney)
            (abi.encodeWithSignature("returnInvestment(address[], uint256[])", assets, _returnValues));
        Assert.equal(result, true, "Investments must be returned");
    }

}