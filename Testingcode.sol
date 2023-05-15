function _transfer(address from, address to, uint256 amount)  // Overrides the _transfer() function to use an optional transfer tax.
    internal
    virtual
    override(ERC20) // Specifies only the ERC20 contract for the override.
    nonReentrant // Prevents re-entrancy attacks.
{

// First we have to do the security checks
require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance"); 
require(from != address(0), "ERC20: transfer from the zero address");
require(to != address(0), "ERC20: transfer to the zero address");

// Now we care about the tax
// Set the tax Amount to zero. We increase if necessary. 
taxAmount = 0;
// check if tax is enabled
if (taxed()) {
  // Check if user group is taxable and ONLY THEN increase tax amount. 
  if !(hasRole(EXCLUDED_ROLE, from) || hasRole(EXCLUDED_ROLE, to)) {
     taxAmount = amount*thetax()/10000
  }
}

// So now we have the amount of tax the user has to pay (or not if he is excluded) 
// Now we can care about the max balance think 
// Your attempt was good so I'll reuse parts of your code

// First check if the addresses are excluded from the rule
// Then return, which means the function is finished
if (from == uniswapV2Pair || from == owner()) {
        super._transfer(from, to, amount);
        return; 
}

// Since we already retuned in case of uniswap or owner
// we can be sure that we deal with people where the 2% rule applies
// Calculate the critical amount 
uint256 totalSupply = this.totalSupply();
uint256 amountAfterTaxes = amount-taxAmount;
uint256 maxAmount = totalSupply * 2 / 100; 

require(balanceOf(to).add(amountAfterTaxes) < maxAmount, "ERC20: Amount exceeds the limit of maximum tokens allowed");

super._transfer(from, taxdestination(), taxAmount );
super._transfer(from, to, amountAfterTaxes  );
}



function _transfer(address from, address to, uint256 amount) internal virtual override(ERC20) nonReentrant {

    if(hasRole(EXCLUDED_ROLE, from) || hasRole(EXCLUDED_ROLE, to) || !taxed()) { // If to/from a tax excluded address or if tax is off...
        super._transfer(from, to, amount); // Transfers 100% of amount to recipient.
        } else { // If not to/from a tax excluded address & tax is on...
            require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance"); // Makes sure sender has the required token amount for the total.
            // If the above requirement is not met, then it is possible that the sender could pay the tax but not the recipient, which is bad...
            if (to != uniswapV2Pair) {
                if(balanceOf(to).add((amount) - (amount * (thetax()/10000))) > maxAmount) {
                revert("Amount exceeds the limit of maximum tokens allowed.");
                } else { 
                super._transfer(from, taxdestination(), amount*thetax()/10000); // Transfers tax to the tax destination address.
                super._transfer(from, to, amount*(10000-thetax())/10000); // Transfers the remainder to the recipient.
                }
            } else { 
                super._transfer(from, taxdestination(), amount*thetax()/10000); // Transfers tax to the tax destination address.
                super._transfer(from, to, amount*(10000-thetax())/10000); // Transfers the remainder to the recipient.
        }
    }