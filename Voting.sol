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

contract Voting is Bylaws {
    
    
    struct Vote {
        address voter;
        bool decision; // true = in favor; false = not in favor
        uint dateVoted;
    }
    
    struct Resolution {
        uint dateProposed;
        uint term;
        uint dateEnded;
        bytes32 proposal;
        Vote[] votes;
        bool EOR;
        bool result;
        bool closed;
    }
    
    mapping(uint => Resolution) public resolutions;
    Resolution[] internal openResolutions;
    Resolution[] public allResolutions;
    
    
    
    function newResolution(bytes32 proposal, bool _EOR) ORL internal returns (uint256){
        if(proposal == "")
            throw;
        uint dateProposed = now;
        Resolution memory r;
        r.dateProposed = dateProposed;
        r.proposal = proposal;
        r.EOR = _EOR;
        r.closed = false;
        
        resolutions[dateProposed] = r;
        allResolutions.push(r);
        openResolutions.push(r);
        
    }
    
    function getResolution(uint r) isOpen(r) public returns(bytes32, bool){
        bytes32 proposal = resolutions[r].proposal;
        bool result = resolutions[r].result;
        
        
    }
    
    function vote(uint r, address _voter, bool _decision) resComplete(r) internal returns (bool){
        resolutions[r].votes.push(Vote({voter: _voter, decision: _decision, dateVoted: now}));
    }
    
    modifier resComplete(uint r){ if(resolutions[r].closed == true) throw; _ }
    modifier isOpen(uint r) { if(resolutions[r].closed == false) throw; _ }
    modifier ORL { if(bylaws.ORL <= openResolutions.length) throw; _ }
    
}

















