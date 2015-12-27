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


import "Directors.sol";
import "Exchange.sol";
import "Shareholders.sol";
import "Bylaws.sol";
import "Voting.sol";
import "Vesting.sol";

contract Directorate is Bylaws, Shareholders, Exchange, Directors, Voting, Vesting {
    function Directorate(){}
    
    
    function NewVote(uint r, bool d) isDirector public returns (bool){
        return vote(r, d);
    }
    
    function NewResolution(string p, bool EOR) isDirector public returns(uint){
        return newResolution(p, EOR, 0, 0, "");
    }
    
    function issueShares(uint shares, uint price) public returns(uint Resolution){
        return newIssuanceVote(shares, price);
    }
    
}
