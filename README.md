# Ethereum Prediction Market (EPM)

The EPM project provides a **trustless**, **on-chain** prediction market contract that does not rely on off-chain computation or oracles.

### Security Considerations

This contract has not been audited and I'm too poor to fund an audit. Additionally, the project relies on perpdex's implementation of the [BokkyPooBahsRedBlackTreeLibrary](https://github.com/perpdex/BokkyPooBahsRedBlackTreeLibrary/tree/feature/bulk/contracts) library. It also has not been audited as far as I'm aware (although the original implementation [has a public bug bounty program](https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary#bug-bounty-scope-and-donations).

That being said, if you would like to see this contract audited please consider donating to my personal address (all funds received will either go towards the purchase of an audit or eventually be returned). I will be creating a Juicebox DAO if EPM ends up gaining popularity.
