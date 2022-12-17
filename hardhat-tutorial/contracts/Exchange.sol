// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

    address public cryptoDevTokenAddress;

    // Exchange is inheriting ERC20 because of tracking LP tokens
    constructor(address _CryptoDevToken) ERC20("CryptoDev LP Token", "CDLP") {
        require(_CryptoDevToken != address(0), "Token address passed is a null address");
        cryptoDevTokenAddress = _CryptoDevToken;
    }

    // returns the amount of `Crypto Dev Tokens` held by the Contract
    function getReserve() public view returns(uint) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        // if the reserve is empty take any user supplied value for 'Ether' and 'CryptoDev'
        // there is no ratio available currently

        if (cryptoDevTokenReserve == 0) {
            // transfer the cryptoDevTokens held by the user account to this contract for adding liquidity
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);

            // Take the current ethBalance and mint `ethBalance` amount of LP tokens to the user.
            // `liquidity` provided is equal to `ethBalance` because this is the first time user
            // is adding `Eth` to the contract, so whatever `Eth` contract has is equal to the one supplied
            // by the user in the current `addLiquidity` call
            // `liquidity` tokens that need to be minted to the user on `addLiquidity` call should always be proportional
            // to the Eth specified by the user
            liquidity = ethBalance;
            _mint(msg.sender, liquidity); // _mint is ERC20.sol smart contract function to mint ERC20 tokens
        } else{
            /*
            If the reserve is not empty, intake any user supplied value for
            `Ether` and determine according to the ratio how many `Crypto Dev` tokens
            need to be supplied to prevent any large price impacts because of the additional
            liquidity
            */

            // Eth reserve is curr Eth Balance - value of Eth given by user in this call (as it is added to contract balance upon calling)
            uint ethReserve = ethBalance - msg.value;

            // maintaining the ratio of CD tokens user can give against the ETH they have deposited to this contract
            uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/(ethReserve); // this will give min tokens needed for balance
            require(_amount >= cryptoDevTokenAmount, "Amount of tokens sent is less than the minimum tokens required");

            // transfer only the cryptoDevTokenAmount amount of tokens since we have proportionalized it accordingly
            cryptoDevToken.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);

            // to send the LP tokens to the user, we need to maintain ratio based on ETH given by the user
            // lp tokens to give/total LP tokens = eth given by user/total eth reserve;
            // lp tokens to give = total LP tokens * eth given by user / total eth reserve;

            liquidity = (totalSupply() * msg.value)/(ethReserve);
            _mint(msg.sender, liquidity);
        }

        return liquidity;
    }

    function removeLiquidity(uint _amount) public returns (uint, uint) {
        require(_amount > 0, "_amount should be greater than 0");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();

        // The amount of Eth that would be sent back to the user is based on a ratio
        // Ratio is -> (Eth sent back to the user) / (current Eth reserve) = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        // Then by some maths -> (Eth sent back to the user) = (current Eth reserve * amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)

        uint ethAmount = (ethReserve * _amount) / _totalSupply;

        // amount of crypto dev token to send back is 
        // crypto dev to send = (total supply of cryptoDev with that user * num of lp tokens user wants to withdraw)/total lp tokens
        uint cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;

        // burn those lp tokens from user account since it has been redeemed to remove liquidity
        _burn(msg.sender, _amount);

        // transfer ETH and CD tokens back to user after calculating
        payable(msg.sender).transfer(ethAmount);
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);

        return(ethAmount, cryptoDevTokenAmount);
    }

    // returns the amount of Eth/CD tokens to be returned to the user in the swap
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {

        // inputAmount = inputAmount * 99 / 100 -> 1% fees applicable
        // (inputAmount * outputReserve)/(inputReserve + inputAmount)

        require(inputReserve > 0 && outputReserve > 0, "INVALID_RESERVE: Reserves are empty for Eth or Token");
        // charging a fee of 1%
        // input amount with fee = inputAmount - (1*(inputAmount)/100) = inputAmount * 99 / 100
        uint256 inputAmountWithFee = inputAmount * 99;

        // coding the formula for (x + Δx) * (y - Δy) = x * y
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        
        return numerator/denominator;
    }

    // swapping ETH for CD tokens
    // user give Eth as the input <-> We give back CD tokens to the user by cutting a 1% fee
    function ethToCryptoDevToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();

        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value, // important to subtract the newly added eth from contract balance
            tokenReserve
        );

        require(tokensBought >= _minTokens, "Insufficient Output Amount");
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }

    // Swaps CryptoDev Tokens for Eth
    function cryptoDevTokenToEth(uint _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");

        // transfer CD tokens from user address to contract -> adding to liquidity pool
        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );

        // send the `ethBought` to the user from the contract
        payable(msg.sender).transfer(ethBought);
    }


}