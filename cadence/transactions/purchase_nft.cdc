import "FungibleToken"
import "NonFungibleToken"
import "ExampleNFT"
import "NFTStorefront"

transaction {
    let paymentVault: @FungibleToken.Vault
    let exampleNFTCollection: &ExampleNFT.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(acct: auth(Storage, Capabilities) &Account) {
        // Borrow the storefront reference
        self.storefront = getAccount(0x04)
            .capabilities
            .borrow<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            ) ?? panic("Could not borrow Storefront from provided address")

        // Borrow the listing reference
        self.listing = self.storefront.borrowListing(listingResourceID: 10)
            ?? panic("No Offer with that ID in Storefront")

        // Fetch the sale price
        let price = self.listing.getDetails().salePrice

        // Borrow FlowToken vault and withdraw payment
        let mainFlowVault = acct.capabilities.storage.borrow<&FungibleToken.Vault>(
            from: /storage/MainVault
        ) ?? panic("Cannot borrow FlowToken vault from account storage")
        self.paymentVault <- mainFlowVault.withdraw(amount: price)

        // Borrow the NFT collection receiver reference
        self.exampleNFTCollection = acct.capabilities.storage.borrow<&ExampleNFT.Collection{NonFungibleToken.Receiver}>(
            from: ExampleNFT.CollectionStoragePath
        ) ?? panic("Cannot borrow NFT collection receiver from account")
    }

    execute {
        // Execute the purchase
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        // Deposit the purchased NFT into the buyer's collection
        self.exampleNFTCollection.deposit(token: <-item)

        /* Potential computation issue: Ensure the cleanup operation is efficient. */
        // Cleanup the listing from the storefront
        self.storefront.cleanup(listingResourceID: 10)
        
        log("Transaction completed")
    }

    // Optional: Post-condition checks to ensure item is in collection
}
