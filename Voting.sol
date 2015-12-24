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

contract Voting is Bylaws, Directors {
    
    
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
    }
    
    mapping(uint => Resolution) public resolutions;
    uint[] public openResolutions;
    uint[] public allResolutions;
    
    
    
    function newResolution(string proposal, bool _EOR) ORL public returns (bool){
        // if(proposal == "")
        //     throw;
        uint dateProposed = now;
        resolutions[dateProposed].proposedBy = msg.sender;
        resolutions[dateProposed].dateProposed = dateProposed;
        resolutions[dateProposed].proposal = proposal;
        resolutions[dateProposed].EOR = _EOR;
        resolutions[dateProposed].closed = false;
        resolutions[dateProposed].endDate = dateProposed + 2 weeks;
        
        Resolution r = resolutions[dateProposed];
        allResolutions.push(r.dateProposed);
        openResolutions.push(r.dateProposed);
        return true;
    }
    
    function getResolution(uint r) isOpen(r) public returns(string proposal, bool closed, bool result){
        return (resolutions[r].proposal, resolutions[r].closed, resolutions[r].result);
    }
    
    function vote(uint r, address _voter, bool _decision) resComplete(r) public returns (bool){
        resolutions[r].votes.push(Vote({voter: _voter, decision: _decision, dateVoted: now}));
        // calculate if resolution has passed.
        return true;
    }
    
    function ResolutionResult(uint r) internal returns (bool){
        uint totalVotes;
        uint yesVotes;
        uint noVotes;
        (totalVotes, yesVotes, noVotes) = countVotes(r);
        
        uint yT = (100 * yesVotes/totalVotes);
        uint nT = (100 * noVotes/totalVotes);
        if(yT > nT)
            return true;
        return false;
    }
    
    function Resolve(uint r) public returns(bool){
        // calculate status of voting
        uint totalVotes;
        uint yesVotes;
        uint noVotes;
        (totalVotes, yesVotes, noVotes) = countVotes(r);
        
        uint totalVoters = numSubscribedVoters();
        uint percentComplete = (100 * totalVotes/totalVoters);
        
        if(resolutions[r].EOR == true)
            if( percentComplete > bylaws.EORT)
                resolutions[r].result = ResolutionResult(r);
                resolutions[r].closed = true;
                resolutions[r].endDate = now;
                return true;
            return false;
        
        if(percentComplete > bylaws.ORT)
            resolutions[r].result = ResolutionResult(r);
            resolutions[r].closed = true;
            resolutions[r].endDate = now;
            return true;
        return false;
    }
    
    function Resolved(uint r) public returns (bool){
        if(resolutions[r].closed == true)
            return true;
        return Resolve(r);
    }
    
    function numSubscribedVoters() public returns(uint){
        if(bylaws.equalWeighted == true)
            // if equal weighted, only directors get voting priveleges
            // if share weighted, shareholders get voting priveleges based on weight
            return currentDirectors.length - 1; // subtract DAV from directors;
        return currentShareholders.length - 1; // subtract DAV from shareholders;
    }
    
    function voteProgress(uint r, uint _total, uint _y, uint _n) public returns (uint){
        if(resolutions[r].EOR == false)
            return 1;
    }
    
    function countVotes(uint r) public returns(uint total, uint y, uint n){
        uint yes;
        uint no;
        uint len = resolutions[r].votes.length;
        for(uint i = 0; i < len; i++)
            if(resolutions[r].votes[i].decision == true)
                yes += 1;
            no += 1;
        return (len, yes, no);
    }
    
    modifier resComplete(uint r){ if(resolutions[r].closed == true) throw; _ }
    modifier isOpen(uint r) { if(resolutions[r].closed == false) throw; _ }
    modifier ORL { if(bylaws.ORL <= openResolutions.length) throw; _ }
    
}

















