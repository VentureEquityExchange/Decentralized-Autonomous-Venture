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



contract Vesting {
    struct Beneficiary {
        address account;
        uint initial; // % of shares
        uint current; // % of shares
        uint full; // % of shares
        uint period; // In terms of weeks
        uint payment;
    }
    
    mapping(address => Beneficiary) public beneficiaries;
    
    function Vesting(){}
    
    function NewSchedule(address _account, uint _initial, uint _full, uint _period, uint _payment) internal returns (bool){
        beneficiaries[_account].account = _account;
        beneficiaries[_account].initial = _initial;
        beneficiaries[_account].current = beneficiaries[_account].initial;
        beneficiaries[_account].full = _full;
        beneficiaries[_account].period = _period;
        beneficiaries[_account].payment = _payment;
        return true;
    }
    
    function Vest(address _account) returns (bool){
            
    }
    
}
