contract Shareholders {
    struct PurchaseOrder {
        uint price;
        uint shares;
        uint date;
    }
    
    struct SaleOrder {
        uint price;
        uint shares;
        uint date;
    }
    
    struct Shareholder {
        address account;
        uint sharesHeld;
        PurchaseOrder[] buys;
        SaleOrder[] sells;
    }
    
    
    mapping(address => Shareholder) public shareholders;
    
    uint public internalShares = 1000000;
    address public Alice = msg.sender;
    address public Bob = 0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826;
    
    function Shareholders(){
        shareholders[Alice].account = Alice;
        shareholders[Alice].sharesHeld = internalShares;
    }
    
    function LowestBid(address shareholder) public returns(uint){
        uint len = shareholders[shareholder].buys.length;
        uint min = 0;
        uint count = 0;
        for(uint i = 0; i < len; i++){
            uint price = shareholders[shareholder].buys[i].price;
            if(min > price || min == 0){
                min = price;
            }
            
            count += 1;
            if(count == len){
                return min;
            }
            
        }
    }
}

contract Ex is Shareholders {
    struct Bid {
        address buyer;
        uint shares;
        uint price;
        uint date;
    }
    
    struct Ask {
        address seller;
        uint shares;
        uint price;
        uint date;
    }
    
    Bid[] public Bids;
    Ask[] public Asks;
    
    Bid[] internal BatchedBids;
    Ask[] internal BatchedAsks;
    
    uint[] internal BidPrices;
    uint[] internal AskPrices;
    
    
    /*
    
    Following Functions Handle Ask-related exchange actions
    
    */
    
    function ValidAsk(address _seller, uint _shares, uint _price) internal returns (bool){
        if(_seller == 0x0 || _shares == 0 || _price == 0 || shareholders[_seller].sharesHeld < _shares)
            return false;
        return true;
    }
    
    function SubmitAsk(uint _shares, uint _price) returns (bool){
        if(!ValidAsk(msg.sender, _shares, _price)){
            throw;
        } else if(AskMatches(_shares, _price).length > 0){
            return ExecuteAsk(msg.sender, _shares, _price, AskMatches(_shares, _price));
        } else {
            // return false;
            return NewAsk(_shares, _price);
        }
    }
    
    function NewAsk(uint _shares, uint _price) internal returns(bool){
        uint dated = now;
        if(Asks.length > 0){
            for(uint i = 0; i < Asks.length; i++){
                if(Asks[i].seller == 0x0){
                    Asks[i].seller = msg.sender;
                    Asks[i].shares = _shares;
                    Asks[i].price = _price;
                    Asks[i].date = dated;
                    return true;
                }
            }    
        } else {
            Asks.push(Ask({seller : msg.sender, shares : _shares, price : _price, date : dated}));
            return true;
        }
    }
    
    function AskMatches(uint _shares, uint _AskPrice) internal returns(Bid[]){
        BidPrices.length = 0;
        BatchedBids.length = 0;
        
        mapping(uint => Bid[]) MatchBids;
        
        if(Bids.length == 0){
            return BatchedBids;
        }
        
        for(uint i = 0; i < Bids.length; i++){
            if(Bids[i].price >= _AskPrice){
                BidPrices.push(Bids[i].price);
                MatchBids[Bids[i].price].push(Bids[i]);
            }
        }
        
        for(uint j = sort(BidPrices).length - 1; j >= 0; j--){
            if(_shares >= 0){
               for(uint k = 0; k < MatchBids[sort(BidPrices)[j]].length; k++){
                    _shares -= MatchBids[sort(BidPrices)[j]][k].shares;
                    BatchedBids.push(MatchBids[sort(BidPrices)[j]][k]);
                    if(j == 0){
                        return BatchedBids;
                    }
                }
            }
        }
        
        return BatchedBids;
    }
    
    function SettleAsk(address Seller, uint Shares, Bid MatchingBid, uint SettlementPrice) internal returns (bool){
        uint date = now;
        if(Shares >= MatchingBid.shares){
            // Pay Seller
            Seller.send(MatchingBid.shares*SettlementPrice);
            
            // Transfer Shares
            shareholders[Seller].sharesHeld -= MatchingBid.shares;
            if(shareholders[MatchingBid.buyer].account == 0x0)
                shareholders[MatchingBid.buyer].account = MatchingBid.buyer;
            
            // Update Shareholder Order History
            
            shareholders[MatchingBid.buyer].sharesHeld += MatchingBid.shares;
            shareholders[MatchingBid.buyer].buys.push(PurchaseOrder({price : SettlementPrice, shares : MatchingBid.shares, date : date}));
            
            
            // Remove Bid
            for(uint i = 0; i < Bids.length; i++){
                if(Bids[i].buyer == MatchingBid.buyer && Bids[i].date == MatchingBid.date){
                    delete Bids[i];
                    return true;
                }
            }
        } else {
            // Pay Seller
            Seller.send(Shares*SettlementPrice);
            
            
            // Transfer Shares
            shareholders[Seller].sharesHeld -= Shares;
            if(shareholders[MatchingBid.buyer].account == 0x0)
                shareholders[MatchingBid.buyer].account = MatchingBid.buyer;
        
            shareholders[MatchingBid.buyer].sharesHeld += Shares;
            shareholders[MatchingBid.buyer].buys.push(PurchaseOrder({price : SettlementPrice, shares : Shares, date : date}));
            
            // Return true
            for(uint j = 0; j < Bids.length; j++){
                if(Bids[j].buyer == MatchingBid.buyer && Bids[j].date == MatchingBid.date){
                    Bids[j].shares -= Shares;
                    return true;
                }
            }
        }
    }
    
    function ExecuteAsk(address Seller, uint Shares, uint Price, Bid[] MatchingBids) internal returns (bool){
        uint confirmations = 0;
        
        for(uint i = 0; i < MatchingBids.length; i++){
            uint SettlementPrice = ((Price+MatchingBids[i].price)/2);
            if(SettleAsk(Seller, Shares, MatchingBids[i], SettlementPrice)){
                        
                //  Calculate Total Buyer Return => Cost savings of profit sharing.
                
                
                uint returnValue = 0;
                if(Shares >= MatchingBids[i].shares){
                    returnValue = ((MatchingBids[i].shares)*(MatchingBids[i].price-SettlementPrice));
                    MatchingBids[i].buyer.send(returnValue);
                } else {
                    returnValue = ((Shares)*(MatchingBids[i].price-SettlementPrice));
                    MatchingBids[i].buyer.send(returnValue);
                }
                
                
                
                if(Shares > MatchingBids[i].shares){
                    Shares -= MatchingBids[i].shares;    
                } else {
                    Shares = 0;
                }
                
                confirmations += 1;
                if(confirmations == MatchingBids.length && Shares == 0){
                    return true;
                } else if(confirmations == MatchingBids.length && Shares > 0 ){
                    return NewAsk(Shares, Price);
                }
            }
        }
        
        return false;
    }
    
    function WtdBidPrice(uint _AskPrice) public returns (uint){
        uint weightedBidPrice = 0;
        for(uint i = 0; i < Bids.length; i++){
            if(Bids[i].price >= _AskPrice){
                weightedBidPrice += (Bids[i].price * Bids[i].shares/BidMarketSupply(_AskPrice));
            }
        }
        
        return weightedBidPrice;
    }
    
    function BidMarketSupply(uint _AskPrice) public returns(uint){
        uint totalSupply = 0;
        for(uint i = 0; i < Bids.length; i++){
            if(Bids[i].price >= _AskPrice){
                totalSupply += Bids[i].shares;
            }
        }
        
        return totalSupply;
    }
    
    
    //
    /*
    
    Following Functions Handle Bid-related exchange actions
    
    */
    
    
    function ValidBid(address _buyer, uint _shares, uint _price) internal returns (bool){
        if(_buyer == 0x0 || _shares == 0 || _price == 0 || _buyer.balance < _price*_shares)
            return false;
        return true;
    }
    
    function NewBid(uint _shares, uint _price) internal returns(bool){
         uint dated = now;
        // Reuse empty Bids Array
        if(Bids.length > 0){
            for(uint i = 0; i < Bids.length; i++){
                if(Bids[i].buyer == 0x0){
                    Bids[i].buyer = msg.sender;
                    Bids[i].shares = _shares;
                    Bids[i].price = _price;
                    Bids[i].date = dated;
                    return true;
                }
            }    
        } else {
            Bids.push(Bid({buyer : msg.sender, shares : _shares, price : _price, date : dated}));
            return true;    
        }
    }
    
    function SubmitBid(uint _price) returns (bool){
        uint orderValue = msg.value;
        uint _shares = orderValue/_price;
        address _buyer = msg.sender;
        if(!ValidBid(_buyer, _shares, _price)){
            throw;
        } else if(BidMatches(_shares, _price).length > 0){
            return ExecuteBid(orderValue, _buyer, _shares, _price, BidMatches(_shares, _price));
        } else {
            // return remainder values (due to rounding limitations);
            _buyer.send((orderValue - _shares*_price)); 
            return NewBid(_shares, _price);
        }
    }
    
    function WtdAskPrice(uint _BidPrice) public returns (uint){
        uint weightedAskPrice = 0;
        for(uint i = 0; i < Asks.length; i++){
            if(Asks[i].price <= _BidPrice){
                weightedAskPrice += (Asks[i].price * Asks[i].shares/AskMarketSupply(_BidPrice));
            }
        }
        
        return weightedAskPrice;
    }
    
    function AskMarketSupply(uint _BidPrice) public returns(uint){
        uint totalSupply = 0;
        for(uint i = 0; i < Asks.length; i++){
            if(Asks[i].price <= _BidPrice){
                totalSupply += Asks[i].shares;
            }
        }
        
        return totalSupply;
    }
    
    function BidMatches(uint _shares, uint _BidPrice) internal returns(Ask[]){
        AskPrices.length = 0;
        BatchedAsks.length = 0;
        
        mapping(uint => Ask[]) MatchAsks;
        
        for(uint i = 0; i < Asks.length; i++){
            if(Asks[i].price <= _BidPrice){
                AskPrices.push(Asks[i].price);
                MatchAsks[Asks[i].price].push(Asks[i]);
            }
        }
        
        for(uint j = 0; j < sort(AskPrices).length; j++){
            if(_shares >= 0){
                for(uint k = 0; k < MatchAsks[sort(AskPrices)[j]].length; k++){
                    _shares -= MatchAsks[sort(AskPrices)[j]][k].shares;
                    BatchedAsks.push(MatchAsks[sort(AskPrices)[j]][k]);
                    if(j == 0){
                        return BatchedAsks;
                    }
                }
            }
        }
        
        
        return BatchedAsks;
    }
    
    function SettleBid(address Buyer, uint Shares, Ask MatchingAsk, uint SettlementPrice) internal returns (bool){
        uint date = now;
        if(Shares >= MatchingAsk.shares){
            // Pay Seller
            MatchingAsk.seller.send(MatchingAsk.shares*SettlementPrice);
            
            // Transfer Shares
            shareholders[MatchingAsk.seller].sharesHeld -= MatchingAsk.shares;
            if(shareholders[Buyer].account == 0x0)
                shareholders[Buyer].account = Buyer;
        
            shareholders[Buyer].sharesHeld += MatchingAsk.shares;
            shareholders[Buyer].sells.push(SaleOrder({price : SettlementPrice, shares : MatchingAsk.shares, date : date}));
            
            // Remove Ask
            for(uint i = 0; i < Asks.length; i++){
                if(Asks[i].seller == MatchingAsk.seller && Asks[i].date == MatchingAsk.date){
                    delete Asks[i];
                    return true;
                }
            }
        } else {
            // Pay Seller
            MatchingAsk.seller.send(Shares*SettlementPrice);
            
            // Transfer Shares
            shareholders[MatchingAsk.seller].sharesHeld -= Shares;
            if(shareholders[Buyer].account == 0x0)
                shareholders[Buyer].account = Buyer;
        
            shareholders[Buyer].sharesHeld += Shares;
            shareholders[Buyer].sells.push(SaleOrder({price : SettlementPrice, shares : Shares, date : date}));
            
            // Amend Ask Shares && return true
            for(uint j = 0; j < Asks.length; j++){
                if(Asks[j].seller == MatchingAsk.seller && Asks[j].date == MatchingAsk.date){
                    Asks[j].shares -= Shares;
                    return true;
                }
            }
        }
    }
    
    function ExecuteBid(uint orderValue, address Buyer, uint Shares, uint Price, Ask[] MatchingAsks) internal returns (bool){
        uint confirmations = 0;
        uint returnValue = orderValue;
        uint SettlementPrice = 0;
        for(uint i = 0; i < MatchingAsks.length; i++){
            SettlementPrice = ((Price+MatchingAsks[i].price)/2);
            if(SettleBid(Buyer, Shares, MatchingAsks[i], SettlementPrice)){
                
                if(Shares >= MatchingAsks[i].shares){
                    returnValue -= (MatchingAsks[i].shares*SettlementPrice);    
                } else {
                    returnValue -= (Shares*SettlementPrice);
                }
                
                if(Shares > MatchingAsks[i].shares){
                    Shares -= MatchingAsks[i].shares;
                } else {
                    Shares = 0;
                }
                
                
                confirmations += 1;
                if(confirmations == MatchingAsks.length && Shares == 0){
                    Buyer.send(returnValue); // return unspent funds to 
                    return true;
                } else if(confirmations == MatchingAsks.length && Shares > 0 ){
                    Buyer.send((returnValue - (Shares*Price)));
                    return NewBid(Shares, Price);
                }
            }
        }
        
        return false;
    }
    
    
    // Utilities
    
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
    
    
    
}