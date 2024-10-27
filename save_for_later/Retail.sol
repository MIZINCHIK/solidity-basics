// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Retail {
    address payable  private owner;
    mapping (address => Basket) private clients;
    Wares private wares;

    constructor() {
        owner = payable(msg.sender);
        wares.wares.push();
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    struct Ware {
        string name;
        uint value;
        uint quantity;
    }

    struct Basket {
        mapping (string => Ware) wares;
        uint totalCost;
        bool exists;
    }

    struct Wares {
        Ware[] wares;
        mapping (string => uint) wareIndices;
        uint[] freeIndices;
    }

    function addWare(string memory name, uint quantity) public isOwner {
        Ware storage ware = wares.wares[wares.wareIndices[name]];
        require(ware.quantity > 0, "Can't infer the price");
        ware.quantity += quantity;
    }

    function addWare(string memory name, uint quantity, uint price) public isOwner {
        if (wares.wareIndices[name] != 0) {
            addWare(name, quantity);
        } else {
            Ware memory newWare = Ware({name: name, value: price, quantity: quantity});
            if (wares.freeIndices.length == 0) {
                wares.wares.push(newWare);
                wares.wareIndices[name] = wares.wares.length - 1;
            } else {
                uint lastFree = wares.freeIndices[wares.freeIndices.length - 1];
                wares.freeIndices.pop();
                wares.wares[lastFree] = newWare;
                wares.wareIndices[name] = lastFree;
            }
        }
    }

    function getWares() public view returns(Ware[] memory)  {
        return wares.wares;
    }

    function addWareToBasket(string memory name, uint quantity) public {
        uint index = wares.wareIndices[name];
        require(index > 0, "No such ware in store");
        Ware memory inStoreWare = wares.wares[index];
        require(inStoreWare.quantity >= quantity, "Not enough wares in stock");
        if (inStoreWare.quantity == quantity) {
            delete(wares.wares[index]);
            wares.freeIndices.push(index);
            delete(wares.wareIndices[name]);
        } else {
            wares.wares[index].quantity -= quantity;
        }
        address buyer = msg.sender;
        Basket storage buyerBasket = clients[buyer];
        buyerBasket.exists = true;
        buyerBasket.wares[name].quantity += quantity;
        buyerBasket.totalCost += inStoreWare.value * quantity;
    }

    function deleteFromBasket(string memory name) public {
        address client = msg.sender;
        Ware memory inBasketWare = clients[client].wares[name];
        if (inBasketWare.quantity > 0) {
            addWare(name, inBasketWare.quantity, inBasketWare.value);
            clients[client].totalCost -= inBasketWare.value * inBasketWare.quantity;
            delete(clients[client].wares[name]);
        }
    }

    function buyBasket() public payable {
        address client = msg.sender;
        require(clients[client].exists, "No basket found for this client");
        uint cost = clients[client].totalCost;
        require(msg.value == cost, "Not the right amount of money");
        owner.transfer(cost);
        delete(clients[client]);
    }
}