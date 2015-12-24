contract decimals {
    // uint[] public threshold;
    // uint[] public votes;
    uint[] public reals;
    
    function CeilingFloor() public returns (uint){
        // decimals currently are not supported in solidity;
        // Explore using Iverson's floor and ceiling functions
        // x-1 < m <= x <= n < x+1
        // m = floor
        // n = ceiling
        // Might just use the Kronecker Product of matrices multiplication
        
        
        // threshold[0] = 67;
        // threshold[1] = 100;
        // votes[1] = 100;
        reals.length = 0;
        uint count;
        for(uint i = 0; i < 21; i++)
            uint a = uint(20/i); // 20 / 4 => 5 should be real.
            if(a != 0)
                reals.push(a);
        return returnLength(reals);
    }
    
    function returnLength(uint[] nums) returns (uint){
        return nums.length;
    }
}