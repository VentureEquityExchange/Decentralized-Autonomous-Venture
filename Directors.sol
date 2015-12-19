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
    }
    
    mapping(address => Director) public directors;
    address public DAV;
    address public Founder;
    uint public internalShares = 1000000;
    
    event directorsAmended(string _n, address _a, bytes32 _r);
    
    function Directors() {
        /* DAV is initial owner */
        DAV = address(this);
        directors[DAV].name = "DAV";
        directors[DAV].account = DAV;
        directors[DAV].role = "DAV";
        shareholders[DAV].account = DAV;
        shareholders[DAV].sharesHeld = internalShares; 
        // Initial value of DAV shares
        
        
        /* Founder is partner in DAV */
        Founder = msg.sender;
        directors[Founder].name = "Founder";
        directors[Founder].account = Founder;
        directors[Founder].role = "founder";
        
    }
    
    function addDirectors(address[] ds) isDAV internal returns (bool){
        if(ds.length == 0)
            return false;
        for(uint i = 0; i < ds.length; i++)
            directors[ds[i]].account = ds[i];
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
    
    function transferOwnership(uint amount, address from, address to) isDAV internal returns (bool){
        if(shareholders[from].sharesHeld < amount)
            throw;
        shareholders[from].sharesHeld -= amount;
        shareholders[to].sharesHeld += amount;
        return true;
    }
    
    function getOwnership(address director) public returns (uint){
        return shareholders[director].sharesHeld;
    }
    
    
    modifier isDirector { if (directors[msg.sender].account != 0x0) _ }
    modifier hasRole(bytes32 role) { if (directors[msg.sender].role == role) _ }
    modifier isFounder { if (directors[msg.sender].account == Founder) _ }
    modifier isDAV { if (directors[msg.sender].account == DAV) _ }
}
