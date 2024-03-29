# Ethereum Hype Market

This repository provides a **trustless**, **on-chain** hype market that does not rely on off-chain computation or oracles.

## How

Unlike a traditional prediction market where future prices are predicted, hype markets use popularity to determine the outcome of a cycle where the total amount of bets ultimately determine gains and losses.

Cycles can be created by anyone and will last a certain period of blocks. During those blocks, **anyone** can place an arbitrary amount of bets for a symbol. Symbols could be anything that fits into 4 bytes - stock names like "GOOG" and "AAPL", emojis, or numbers that represent an off-chain asset.

## Security Considerations

This contract has not been audited and I'm too poor to fund an audit myself. Use this contract at your own risk and don't send money to it that you aren't willing to lose.
