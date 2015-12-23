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



contract Bylaws {
    /*
    Decentralized Autonomous Ventures have bylaws which help the 
    organization operate internally.
    
    These bylaws can be amended by the Directorate Contract
    via Extra-Ordinary Resolution
    
    For example: Both Ordinary and Extra-Ordinary Resolution thresholds can be 
    set via Extra-Ordinary Resolution voting
    
    Extra-Ordinary Resolutions are resolutions that need a greater percentage of
    the collective vote to pass than Ordinary Resolutions.
    
    Ordinary Resolutions are usually set by greater than 51% or 67% 
    majority vote.
    
    The default threshold value for Ordinary Resolution is set to 67%
    The default threshold value for Extra-Ordinary Resolution is set to 90%
    */
    
    // uint internal ORT; 
    // Ordinary Resolution Threshold Value;
    
    // uint internal EORT; 
    // Extra-Ordinary Resolution Threshold Value;
    
    // uint OpenResolutionLimit; 
    // Open Resolution Limit (ORL) sets the maximum...
    // amount of open resolutions that can exist at one time
    
    struct ByLawsConfig {
        uint ORT;
        uint EORT;
        uint ORL;
        bool equalWeighted; // default is true; false == shareWeighted;
    }
    
    ByLawsConfig public bylaws;
    
    function Bylaws(){
        bylaws.ORT = 67;
        bylaws.EORT = 90;
        bylaws.ORL = 5;
        bylaws.equalWeighted = true;
    }
}





















