contract Shareholders {
    struct Shareholder {
        address account;
        uint sharesHeld;
    }
    
    mapping(address => Shareholder) public shareholders;
    
    uint public internalShares = 1000000;
    address public Alice = msg.sender;
    address public Bob = 0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826;
    
    function Shareholders(){
        shareholders[Alice].account = Alice;
        shareholders[Alice].sharesHeld = internalShares;
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
    
    uint[] internal OldestBids;
    uint[] internal OldestAsks;
    
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
        OldestAsks.length = 0;
        BatchedAsks.length = 0;
        
        mapping(uint => Ask) MatchAsks;
        
        for(uint i = 0; i < Asks.length; i++){
            if(Asks[i].price <= _BidPrice){
                OldestAsks.push(Asks[i].date);
                MatchAsks[Asks[i].date] = Asks[i];
            }
        }
        
        
        for(uint j = 0; j < sort(OldestAsks).length; j++){
            if(_shares >= 0){
                _shares -= MatchAsks[sort(OldestAsks)[j]].shares;
                BatchedAsks.push(MatchAsks[sort(OldestAsks)[j]]);
                if(_shares == 0){
                    return BatchedAsks;
                }
            }
        }
        
        return BatchedAsks;
    }
    
    function SettleBid(address Buyer, uint Shares, Ask MatchingAsk, uint WtdAskPrice) internal returns (bool){
        
        if(Shares >= MatchingAsk.shares){
            // Pay Seller
            MatchingAsk.seller.send(MatchingAsk.shares*WtdAskPrice);
            
            // Transfer Shares
            shareholders[MatchingAsk.seller].sharesHeld -= MatchingAsk.shares;
            if(shareholders[Buyer].account == 0x0)
                shareholders[Buyer].account = Buyer;
        
            shareholders[Buyer].sharesHeld += MatchingAsk.shares;
            
            // Remove Ask
            for(uint i = 0; i < Asks.length; i++){
                if(Asks[i].seller == MatchingAsk.seller && Asks[i].date == MatchingAsk.date){
                    delete Asks[i];
                    return true;
                }
            }
        } else {
            // Pay Seller
            MatchingAsk.seller.send(Shares*WtdAskPrice);
            
            // Transfer Shares
            shareholders[MatchingAsk.seller].sharesHeld -= Shares;
            if(shareholders[Buyer].account == 0x0)
                shareholders[Buyer].account = Buyer;
        
            shareholders[Buyer].sharesHeld += Shares;
            
            // Return true
            return true;
        }
    }
    
    function ExecuteBid(uint orderValue, address Buyer, uint Shares, uint Price, Ask[] MatchingAsks, uint WtdAskPrice) internal returns (bool){
        uint confirmations = 0;
        uint returnValue = orderValue;
        for(uint i = 0; i < MatchingAsks.length; i++){
            if(SettleBid(Buyer, Shares, MatchingAsks[i], WtdAskPrice)){
                if(Shares >= MatchingAsks[i].shares){
                    returnValue -= (MatchingAsks[i].shares*WtdAskPrice);    
                } else {
                    returnValue -= (Shares*WtdAskPrice);
                }
                
                Shares -= MatchingAsks[i].shares;
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
    
    function NewBid(uint _shares, uint _price) internal returns(bool){
        Bids.push(Bid({buyer : msg.sender, shares : _shares, price : _price, date : now}));
        return true;
    }
    
    function SubmitBid(uint _price) returns (bool){
        uint orderValue = msg.value;
        uint _shares = orderValue/_price;
        if(BidMatches(_shares, _price).length > 0){
            return ExecuteBid(orderValue, msg.sender, _shares, _price, BidMatches(_shares, _price), WtdAskPrice(_price));
        } else {
            return NewBid(_shares, _price);
        }
    }
    
    function NewAsk(uint _shares, uint _price) public returns(bool){
        Asks.push(Ask({seller : msg.sender, shares : _shares, price : _price, date : now}));
        return true;
    }
    
    // function SubmitAsk(uint _shares, uint _price) returns (bool){
        
    // }
    
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