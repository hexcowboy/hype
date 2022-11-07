# Ethereum Prediction Market (EPM)

The EPM project provides a **trustless**, **on-chain** prediction market contract that does not rely on off-chain computation or oracles.

## How

Unlike a traditional prediction market where future prices are predicted, EPM uses popularity to determine the outcome of a cycle where the total amount of bets at the end determine profit.

Cycles can be created by anyone and will last a certain period of blocks. During those blocks, **anyone** can place an arbitrary amount of bets for a symbol. Symbols could be anything that fits into 4 bytes - stock names like "GOOG" and "AAPL", emojis, or numbers that represent an off-chain asset.

## Security Considerations

This contract has not been audited and I'm too poor to fund an audit. Use this contract at your own risk and don't send money to it that you aren't willing to lose.

## Donation Address

If you would like to help this contract become audited, please consider donating to my personal address (all funds received after November 15, 2022 will go towards the funding of an audit). I will be creating a Juicebox DAO and Gnosis safe if EPM ends up gaining popularity.

```
0x67Fd888Da2319f8f8419FD7842e32d5C5E71F528
```
