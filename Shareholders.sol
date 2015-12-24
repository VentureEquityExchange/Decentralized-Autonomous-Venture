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



contract Shareholders {
    struct Shareholder {
        address account;
        uint sharesHeld;
    }
    
    mapping(address => Shareholder) public shareholders;
    address[] internal currentShareholders;
    address[] public allShareholders;
    
    uint public internalShares = 1000000;
    
    function Shareholders(){}
    
    function getSharesHeld(address _a) returns (uint){
        return shareholders[_a].sharesHeld;
    }
    
    function getCurrentShareholders() public returns (address[]){
        currentShareholders.length = 0;
        uint len = allShareholders.length;
        for(uint i = 0; i < len; i++)
            if(shareholders[allShareholders[i]].sharesHeld > 0)
                currentShareholders.push(allShareholders[i]);
        return currentShareholders;
    }
    
    function transferOwnership(uint amount, address from, address to) public returns (bool){
        if(shareholders[from].sharesHeld < amount)
            throw;
        shareholders[from].sharesHeld -= amount;
        shareholders[to].sharesHeld += amount;
        if(shareholders[to].account == 0x0)
            shareholders[to].account = to;
            allShareholders.push(to);
        return true;
    }
    
}
