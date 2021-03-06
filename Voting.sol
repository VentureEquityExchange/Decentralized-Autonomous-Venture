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

import "Bylaws.sol";
import "Directors.sol";
import "Shareholders.sol";
import "Exchange.sol";

contract Voting is Bylaws, Shareholders, Exchange, Directors {
    
    
    struct Vote {
        address voter;
        bool decision; // true = in favor; false = not in favor
        uint dateVoted;
    }
    
    struct Resolution {
        address proposedBy;
        uint dateProposed;
        uint endDate;
        string proposal;
        bytes32 data; // sha3(arb. byte length)
        Vote[] votes;
        bool EOR;
        bool result;
        bool closed;
        bytes32 voteType;
        uint shares;
        uint price;
    }
    
    mapping(uint => Resolution) public resolutions;
    uint[] internal openResolutions;
    uint[] public allResolutions;
    uint internal yes;
    uint internal no;
    
    
    function newIssuanceVote(uint shares, uint price) ORL public returns (uint){
        return newResolution("Issue Shares", true, shares, price, "Issue Shares");
        
    }
    
    function newResolution(string proposal, bool _EOR, uint _shares, uint _price, bytes32 _voteType) ORL public returns (uint){
        // if(proposal == "")
        //     throw;
        uint dateProposed = now;
        resolutions[dateProposed].proposedBy = msg.sender;
        resolutions[dateProposed].dateProposed = dateProposed;
        resolutions[dateProposed].proposal = proposal;
        resolutions[dateProposed].EOR = _EOR;
        resolutions[dateProposed].voteType = _voteType;
        resolutions[dateProposed].shares = _shares;
        resolutions[dateProposed].price = _price;
        resolutions[dateProposed].result = false; // start resolutions as false; apparently this is not being set....
        resolutions[dateProposed].closed = false;
        resolutions[dateProposed].endDate = dateProposed + bylaws.resolutionPeriod;
        
        Resolution r = resolutions[dateProposed];
        allResolutions.push(r.dateProposed);
        return dateProposed;
    }
    
    function getOpenResolutions() public returns (uint[]){
        openResolutions.length = 0;
        uint len = allResolutions.length;
        for(uint i = 0; i < len; i++){
            if(resolutions[allResolutions[i]].closed == false){
                openResolutions.push(allResolutions[i]);
            }
        }
                
        return openResolutions;
    }
    
    function getResolutionResult(uint r) isOpen(r) public returns(bool result){
        return (resolutions[r].result);
    }
    
    function hasVoted(uint r, address voter) internal returns (bool){
        uint len = resolutions[r].votes.length;
        for(uint i = 0; i < len; i++){
            if(resolutions[r].votes[i].voter == voter){
                return true;
            }
        }
        
        return false;
    }
    
    function vote(uint r, bool _decision) resComplete(r) isDirector public returns (bool){
        if(hasVoted(r, msg.sender)){
            throw;
        } else if(resolutions[r].voteType == "Issue Shares"){
            resolutions[r].votes.push(Vote({voter: msg.sender, decision: _decision, dateVoted: now}));
            if(Resolved(r)){
                return SubmitAsk(address(this), resolutions[r].shares, resolutions[r].price);
            } else {
                return true;
            }
        }
    }
    
    function votePassed(uint r) public returns(bool){
        uint totalVotes;
        uint yesVotes;
        uint noVotes;
        (totalVotes, yesVotes, noVotes) = countVotes(r);
        bool result = (yesVotes > noVotes);
        
        uint totalVoters = numSubscribedVoters();
        uint percentComplete = (100 * totalVotes/totalVoters);
        
        if(result && percentComplete > bylaws.EORT){
            return true;
        } else {
            return false;
        }
            
    }
    
    function Resolve(uint r) public returns(bool){
        // calculate status of voting
        uint totalVotes;
        uint yesVotes;
        uint noVotes;
        (totalVotes, yesVotes, noVotes) = countVotes(r);
        
        bool result = (yesVotes > noVotes);
        
        uint totalVoters = numSubscribedVoters();
        uint percentComplete = (100 * totalVotes/totalVoters);
        
        
        if(resolutions[r].endDate < now) {
            resolutions[r].result = result;
            resolutions[r].closed = true;
            resolutions[r].endDate = now;
            return true;
        } else if(resolutions[r].EOR == true && percentComplete > bylaws.EORT){
            resolutions[r].result = result;
            resolutions[r].closed = true;
            resolutions[r].endDate = now;
            return true;
        } else if(resolutions[r].EOR != true && percentComplete > bylaws.ORT){
            resolutions[r].result = result;
            resolutions[r].closed = true;
            resolutions[r].endDate = now;
            return true;
        } else {
            return false;    
        }
    }
    
    function Resolved(uint r) public returns (bool){
        if(resolutions[r].closed == true){
            return true;
        } else {
            return Resolve(r);
        }
    }
    
    function numSubscribedVoters() public returns(uint){
        if(bylaws.equalWeighted == true){
            // if equal weighted, only directors get voting priveleges
            // if share weighted, shareholders get voting priveleges based on weight
            return getCurrentDirectors().length - 1; // subtract DAV from directors;
        } else {
            return getCurrentShareholders().length - 1; // subtract DAV from shareholders;
        }
    }
    
    function countVotes(uint r) public returns(uint total, uint y, uint n){
        // I suspect an issue here.
        yes = 0;
        no = 0;
        uint len = resolutions[r].votes.length;
        for(uint i = 0; i < len; i++)
            if(resolutions[r].votes[i].decision == true){
                yes += 1;
            } else {
                no += 1;
            }
        return (len, yes, no);
    }
    
    modifier resComplete(uint r){ if(resolutions[r].closed == true) throw; _ }
    modifier isOpen(uint r) { if(resolutions[r].closed == false) throw; _ }
    modifier ORL { if(bylaws.ORL <= openResolutions.length) throw; _ }
    
}

















