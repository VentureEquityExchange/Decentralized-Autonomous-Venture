/*
2015 Ryan Michael Tate

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.

*/

import "Shareholders.sol";

contract Exchange is Shareholders {
    struct Ask {
        address seller;
        uint shares;
        uint price;
        uint date;
    }   
    
    struct Bid {
        address buyer;
        uint shares;
        uint price;
        uint date;
    }
    
    Ask[] public Asks;
    uint[] internal asksSorted;
    uint[] internal askMatches;
    uint[] internal askQuantities;
    uint[] internal openAsks;
    
    Bid[] public Bids;
    uint[] internal bidsSorted;
    uint[] internal bidMatches;
    uint[] internal bidQuantities;
    uint[] internal openBids;
    // modifier validBid(address _buyer, uint _shares, uint _price) {
    //     if(_buyer == 0x0 || _shares == 0 || _price == 0 || _buyer.balance < _price*_shares)
    //         throw;
    //     _
    // }
    
    function ValidBid(address _buyer, uint _shares, uint _price) internal returns (bool){
        if(_buyer == 0x0 || _shares == 0 || _price == 0 || _buyer.balance < _price*_shares)
            return false;
        return true;
    }
    
    function ValidAsk(address _seller, uint _shares, uint _price) internal returns (bool){
        if(_seller == 0x0 || _shares == 0 || _price == 0 || shareholders[_seller].sharesHeld < _shares)
            return false;
        return true;
    }
    
    function OpenAsks() public returns (uint[]){
        openAsks.length = 0;
        uint len = SortAsks().length;
        for(uint i = 0; i < len; i++)
            if(Asks[i].seller == msg.sender)
                openAsks.push(i);
        return openAsks;
    }
    
    function OpenBids() public returns (uint[]){
        openBids.length = 0;
        uint len = SortBids().length;
        for(uint i = 0; i < len; i++)
            if(Bids[i].buyer == msg.sender)
                openBids.push(i);
        return openBids;
    }
    
    function DeleteAsk(uint askDate) public returns (bool){
        uint len = SortAsks().length;
        for(uint i = 0; i < len; i++)
            if(Asks[i].seller == msg.sender && Asks[i].date == askDate)
                delete Asks[i];
    }
    
    function DeleteBid(uint bidDate) public returns (bool){
        uint len = SortBids().length;
        for(uint i = 0; i < len; i++)
            if(Bids[i].buyer == msg.sender && Bids[i].date == bidDate)
                delete Bids[i];
    }
    
    function NewAsk(address _seller, uint _shares, uint _price) internal returns (bool){
        uint dated = now;
        // reuse empty Asks arrays
        for(uint i = 0; i < Asks.length; i++){
            if(Asks[i].seller == 0x0){
                Asks[i].seller = _seller;
                Asks[i].shares = _shares;
                Asks[i].price = _price;
                Asks[i].date = dated;
                return true;
            }
        }
        
        Asks.push(Ask({seller : _seller, shares : _shares, price : _price, date: dated}));
        return true;
    }
    
    function NewBid(address _buyer, uint _shares, uint _price) internal returns (bool){
        uint dated = now;
        // Reuse empty Bids Array
        for(uint i = 0; i < Bids.length; i++){
            if(Bids[i].buyer == 0x0){
                Bids[i].buyer = _buyer;
                Bids[i].shares = _shares;
                Bids[i].price = _price;
                Bids[i].date = dated;
                return true;
            }
        }
        
        Bids.push(Bid({buyer : _buyer, shares : _shares, price : _price, date: dated}));
        return true;
    }
    
    function BidAskSpread() returns (uint, uint){
        uint minBid;
        uint maxBid;
        (minBid, maxBid) = MinMaxBid();
        uint minAsk;
        uint maxAsk;
        (minAsk, maxAsk) = MinMaxAsk();
        
        return (maxBid, minAsk);
    }
    
    function SubmitAsk(address _seller, uint _shares, uint _price) returns (bool){
        // address _seller = msg.sender;
        if(!ValidAsk(_seller, _shares, _price))
            throw;
        if(AskInMarket(_price))
            return ExecuteAsk(_seller, _shares, _price);
        
        return NewAsk(_seller, _shares, _price);
        
    }
    
    
    function SubmitBid(uint _price) returns (bool){
        address _buyer = msg.sender;
        uint _order = msg.value; // order is price*shares sent by the bidder in msg.value;
        uint _shares = (_order / _price); 
        if(!ValidBid(_buyer, _shares, _price))
            throw;
        if(BidInMarket(_price))
            return ExecuteBid(_order, _buyer, _shares, _price);
        
        
        // Push to Bids if order cannot be executed;
        
        return NewBid(_buyer, _shares, _price);
    }
    
    function BidInMarket(uint _price) returns (bool){
       uint min;
       uint max;
       (min, max) = MinMaxAsk();
       if(min == 0)
            return false;
       if(min <= _price)
            return true;
        return false;
    }
    
    function AskInMarket(uint _price) returns (bool){
        uint min;
        uint max;
        (min, max) = MinMaxBid();
        if(max == 0)
            return false;
        if(max >= _price)
            return true;
        return false;
    }
    
    function MinMaxAsk() returns (uint _min, uint _max){
        if(SortAsks().length == 0)
            return (0,0);
        uint min = SortAsks()[0];
        uint max = SortAsks()[Asks.length - 1];
        return (min, max);
                
    }
    
    function MinMaxBid() returns (uint _min, uint _max){
        if(SortBids().length == 0)
            return(0,0);
        uint min = SortBids()[0];
        uint max = SortBids()[Bids.length - 1];
        return (min, max);
    }
    
    function SortAsks() internal returns (uint[] _sorted){
        asksSorted.length = 0;
        for(uint i = 0; i < Asks.length; i++)
            if(Asks[i].price != 0 || Asks[i].shares != 0)
                asksSorted.push(Asks[i].price);
        return sort(asksSorted);
    }
    
    function SortBids() internal returns (uint[] _sorted){
        bidsSorted.length = 0;
        for(uint i = 0; i < Bids.length; i++)
            if(Bids[i].price != 0 || Bids[i].shares != 0)
                bidsSorted.push(Bids[i].price);
        return sort(bidsSorted);
    }
    
    
    function AskMatches(uint _price) internal returns (uint []){
        askMatches.length = 0;
        for(uint i = 0; i < Asks.length; i++)
            if(Asks[i].price <= _price)
                askMatches.push(i); // push indexes of matching asks
        return askMatches;
    }
    
    function BestAsk(uint[] _matchingAsks) internal returns (address, uint, uint, uint){
        uint bestAsk;
        askQuantities.length = 0;
        for(uint i = 0; i < _matchingAsks.length; i++)
            askQuantities.push(Asks[_matchingAsks[i]].shares);
        bestAsk = sort(askQuantities)[askQuantities.length - 1];
        for(uint j = 0; j < _matchingAsks.length; j++)
            if(Asks[_matchingAsks[j]].shares == bestAsk)
                return(Asks[_matchingAsks[j]].seller, Asks[_matchingAsks[j]].shares, Asks[_matchingAsks[j]].price, Asks[_matchingAsks[j]].date);
    }
    
    
    function BidMatches(uint _price) internal returns (uint []){
        bidMatches.length = 0;
        for(uint i = 0; i < Bids.length; i++)
            if(Bids[i].price >= _price)
                bidMatches.push(i); 
        return bidMatches;
    }
    
    
    function BestBid(uint[] _matchingBids) internal returns (address, uint, uint, uint){
        uint bestBid;
        bidQuantities.length = 0;
        for(uint i = 0; i < _matchingBids.length; i++)
            bidQuantities.push(Bids[_matchingBids[i]].shares);
        bestBid = sort(bidQuantities)[bidQuantities.length - 1];
        for(uint j = 0; j < _matchingBids.length; j++)
            if(Bids[_matchingBids[j]].shares == bestBid)
                return(Bids[_matchingBids[j]].buyer, Bids[_matchingBids[j]].shares, Bids[_matchingBids[j]].price, Bids[_matchingBids[j]].date);
    }
    
    // function BatchBids(Ask _ask, Bid[] _bids) internal returns(bool){...}
    
    function sort(uint[] arr) internal returns (uint[]) {
      uint minIdx; 
      uint temp;
      uint len = arr.length;
      for(var i = 0; i < len; i++){
        minIdx = i;
        for(var j = i+1; j<len; j++){
           if(arr[j]<arr[minIdx]){
              minIdx = j;
           }
        }
        temp = arr[i];
        arr[i] = arr[minIdx];
        arr[minIdx] = temp;
      }
      return arr;
    }
    
    function SettleBid(uint orderValue, address _buyer, uint buyerShares, uint bidPrice, address _seller, uint sellerShares, uint askPrice, uint askDate) internal returns (bool){
        /*
        if bid shares demanded > supply of seller;
        1. Pay seller price*shares;
        2. Subtract Shares from seller;
        3. Add Shares to bidder;
        4. Remove Ask from open orders;
        5. Edit Bid with outstanding shares;
        
        */
        _seller.send(sellerShares*askPrice);
        shareholders[_seller].sharesHeld -= sellerShares;
        if(shareholders[_buyer].account == 0x0)
            shareholders[_buyer].account = _buyer;
    
        shareholders[_buyer].sharesHeld += sellerShares;
        uint BidRemainder = buyerShares - sellerShares;
        for(uint i = 0; i < Asks.length; i++)
            if(Asks[i].seller == _seller && Asks[i].date == askDate)
                delete Asks[i];
        _buyer.send((orderValue - (sellerShares*askPrice)) - (BidRemainder*bidPrice)); // return excess funds to bidder; leave enough to cover open bid;
        if(BidRemainder == 0)
            return true;
        
        
        return NewBid(_buyer, BidRemainder, bidPrice);
        
        
    }
    
    function ClearBid(uint orderValue, address _buyer, uint buyerShares, uint bidPrice, address _seller, uint sellerShares, uint askPrice, uint askDate) internal returns (bool){
        /*
        if bid shares demanded < supply of seller;
        1. Pay seller price*shares;
        2. Subtract Shares from seller;
        3. Add Shares to bidder;
        4. Remove Bid from open orders;
        5. Edit Ask with outstanding shares;
        */
        _seller.send(buyerShares*askPrice);
        shareholders[_seller].sharesHeld -= buyerShares;
        if(shareholders[_buyer].account == 0x0)
            shareholders[_buyer].account = _buyer;
    
        shareholders[_buyer].sharesHeld += buyerShares;
        uint AskRemainder = sellerShares-buyerShares;
        for(uint j = 0; j < Asks.length; j++)
            if(Asks[j].seller == _seller && Asks[j].date == askDate)
                Asks[j].shares = AskRemainder;
        _buyer.send(orderValue - (buyerShares*askPrice));
        return true;
    }
    
    function ExecuteBid(uint orderValue, address _buyer, uint buyerShares, uint _price) internal returns (bool){
        address _seller;
        uint sellerShares;
        uint sellerPrice;
        uint _d;
        (_seller, sellerShares, sellerPrice, _d) = BestAsk(AskMatches(_price));
        if(buyerShares >= sellerShares)
            return SettleBid(orderValue, _buyer, buyerShares, _price, _seller, sellerShares, sellerPrice, _d);
        return ClearBid(orderValue, _buyer, buyerShares, _price, _seller, sellerShares, sellerPrice, _d);
    }
    
    function SettleAsk(address _seller, uint sellerShares, uint askPrice, address _buyer, uint buyerShares, uint buyerPrice, uint bidDate) internal returns (bool){
        /*
        if bid shares demanded < supply of seller;
        1. Pay seller buyerprice*buyershares; => seller is accepting buyer terms/price at quantity.
        2. Subtract Shares from seller;
        3. Add Shares to bidder;
        4. Remove Bid from open orders;
        5. Edit Ask with outstanding shares;
        */
        _seller.send(buyerShares*buyerPrice);
        shareholders[_seller].sharesHeld -= buyerShares;
        if(shareholders[_buyer].account == 0x0)
            shareholders[_buyer].account = _buyer;
    
        shareholders[_buyer].sharesHeld += buyerShares;
        uint AskRemainder = sellerShares-buyerShares;
        for(uint j = 0; j < Bids.length; j++)
            if(Bids[j].buyer == _buyer && Bids[j].date == bidDate)
                delete Bids[j];
        
        // _buyer should already be reimbursed for excessive bid at submittal; seller does not need to be reimbursed;
        // _buyer.send((orderValue - (sellerShares*askPrice)) - (BidRemainder*bidPrice)); 
        
        
        if(AskRemainder == 0)
            return true;
        
        return NewAsk(_seller, AskRemainder, askPrice);
    }
    
    function ClearAsk(address _seller, uint sellerShares, uint askPrice, address _buyer, uint buyerShares, uint buyerPrice, uint bidDate) internal returns (bool){
        /* 
        buyer Shares > seller Shares
        clear ask
        edit bid order
        */
        _seller.send(sellerShares*buyerPrice); // sellerShares are avaiable shares
        shareholders[_seller].sharesHeld -= sellerShares;
        if(shareholders[_buyer].account == 0x0)
            shareholders[_buyer].account = _buyer;
    
        shareholders[_buyer].sharesHeld += sellerShares;
        uint BidRemainder = buyerShares-sellerShares;
        for(uint j = 0; j < Bids.length; j++)
            if(Bids[j].buyer == _buyer && Bids[j].date == bidDate)
                Bids[j].shares = BidRemainder;
        return true;
    }
    
    
    function ExecuteAsk(address _seller, uint sellerShares, uint askPrice) internal returns (bool){
        address _buyer;
        uint buyerShares;
        uint buyerPrice;
        uint bidDate;
        (_buyer, buyerShares, buyerPrice, bidDate) = BestBid(BidMatches(askPrice));
        if(sellerShares >= buyerShares)
            return SettleAsk(_seller, sellerShares, askPrice, _buyer, buyerShares, buyerPrice, bidDate); // if ask supply >= bid demanded; clear bid, new ask.
        return ClearAsk(_seller, sellerShares, askPrice, _buyer, buyerShares, buyerPrice, bidDate); // if ask supply < bid demanded; clear ask;
    }
    
}
