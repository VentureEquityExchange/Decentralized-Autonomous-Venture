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

contract Directors is Shareholders {
    struct Director {
        string name;
        address account;
        bytes32 role;
        bool active;
    }
    
    mapping(address => Director) public directors;
    address[] internal currentDirectors;
    address[] public allDirectors;
    
    address public DAV;
    address public Founder;
    
    event directorsAmended(string _n, address _a, bytes32 _r);
    
    function Directors() {
        /* DAV is initial owner */
        DAV = address(this);
        directors[DAV].name = "DAV";
        directors[DAV].account = DAV;
        directors[DAV].role = "DAV";
        directors[DAV].active = true;
        allDirectors.push(DAV);
        
        shareholders[DAV].account = DAV;
        shareholders[DAV].sharesHeld = internalShares; 
        allShareholders.push(DAV);
        // Initial value of DAV shares
        
        
        /* Founder is partner in DAV */
        Founder = msg.sender;
        directors[Founder].name = "Founder";
        directors[Founder].account = Founder;
        directors[Founder].role = "founder";
        directors[Founder].active = true;
        allDirectors.push(Founder);
        
        
    }
    
    function addDirectors(address[] ds) isDirector public returns (bool){
        if(ds.length == 0)
            return false;
        for(uint i = 0; i < ds.length; i++)
            directors[ds[i]].account = ds[i];
        return true;
    }
    
    function getCurrentDirectors() public returns(address[]){
        currentDirectors.length = 0;
        uint len = allDirectors.length;
        for(uint i = 0; i < len;  i++)
            if(directors[allDirectors[i]].active == true)
                currentDirectors.push(allDirectors[i]);
        return currentDirectors;
    }
    
    function removeDirector(address _account) isDAV internal returns (bool){
        directors[_account].active = false;
        return true;
    }
    
    function amendDirector(string _name, address _account, bytes32 _role) isDirector internal returns (bool){
        if(_account == 0x0 || directors[_account].account == 0x0)
            return false;
        directors[_account].name = _name;
        directors[_account].account = _account;
        directors[_account].role = _role;
        directorsAmended(_name, _account, _role);
        return true;
    }
    
    modifier isDirector { if (directors[msg.sender].account == 0x0 || directors[msg.sender].active == false) throw; _ }
    modifier hasRole(bytes32 role) { if (directors[msg.sender].role == role) throw; _ }
    modifier isFounder { if (directors[msg.sender].account == Founder) throw; _ }
    modifier isDAV { if (directors[msg.sender].account == DAV) throw; _ }
}
