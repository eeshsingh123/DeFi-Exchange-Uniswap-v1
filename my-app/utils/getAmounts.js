import { Contract } from "ethers";
import {
  EXCHANGE_CONTRACT_ABI,
  EXCHANGE_CONTRACT_ADDRESS,
  TOKEN_CONTRACT_ABI,
  TOKEN_CONTRACT_ADDRESS,
} from "../constants";

// important to understand:
// getBalance -> internal contract function which gives ETH balance held by contract/user based on addr
// balanceOf -> ERC-20 function which gives the balance of tokens held by user/contract based on addr

export const getEtherBalance = async (provider, address, contract = false) => {
  try {
    if (contract) {
      const balance = await provider.getBalance(EXCHANGE_CONTRACT_ADDRESS);
      return balance;
    } else {
      const balance = await provider.getBalance(address);
      return balance;
    }
  } catch (err) {
    console.error(err);
    return 0;
  }
};

export const getCDTokensBalance = async (provider, address) => {
  try {
    const tokenContract = new Contract(
      TOKEN_CONTRACT_ADDRESS,
      TOKEN_CONTRACT_ABI,
      provider
    );
    const balanceOfCDTokens = await tokenContract.balanceOf(address);
    return balanceOfCDTokens;
  } catch (err) {
    console.error(err);
  }
};

/**
 * getLPTokensBalance: Retrieves the amount of LP tokens in the account
 * of the provided `address`
 */
export const getLPTokensBalance = async (provider, address) => {
    try {
      const exchangeContract = new Contract(
        EXCHANGE_CONTRACT_ADDRESS,
        EXCHANGE_CONTRACT_ABI,
        provider
      );
      const balanceOfLPTokens = await exchangeContract.balanceOf(address);
      return balanceOfLPTokens;
    } catch (err) {
      console.error(err);
    }
  };

  /**
 * getReserveOfCDTokens: Retrieves the amount of CD tokens held by the
 * exchange contract address
 */
export const getReserveOfCDTokens = async (provider) => {
    try {
      const exchangeContract = new Contract(
        EXCHANGE_CONTRACT_ADDRESS,
        EXCHANGE_CONTRACT_ABI,
        provider
      );
      const reserve = await exchangeContract.getReserve();
      return reserve;
    } catch (err) {
      console.error(err);
    }
  };