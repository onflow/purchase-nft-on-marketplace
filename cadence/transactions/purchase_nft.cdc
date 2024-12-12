import "FungibleToken"
import "NonFungibleToken"
import "ExampleNFT"
import "NFTStorefront"


transaction {
    let paymentVault: @{FungibleToken.Vault}
    let exampleNFTCollection: &ExampleNFT.Collection
    let storefront: &{NFTStorefront.StorefrontPublic}
    let listing: &{NFTStorefront.ListingPublic}

     prepare(acct: auth(Storage, Capabilities) &Account) {

        // Create and save the storefront
        let storefront <- NFTStorefront.createStorefront()
        acct.storage.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)

        // Publish the storefront capability to the public path
        let storefrontCap = acct.capabilities.storage.issue<&{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontStoragePath
        )
        acct.capabilities.publish(storefrontCap, at: NFTStorefront.StorefrontPublicPath)

        // Borrow the storefront reference using the public capability path
        let storefrontRef = acct.capabilities.borrow<&{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        ) ?? panic("Could not borrow Storefront from provided address")
        self.storefront = storefrontRef

        // Borrow the listing reference
        self.listing = self.storefront.borrowListing(listingResourceID: 10)
            ?? panic("No Offer with that ID in Storefront")

        // Fetch the sale price
        let price = self.listing.getDetails().salePrice

        // Borrow FlowToken vault with proper authorization to withdraw
        let flowTokenCap = acct.capabilities.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(
        /public/flowTokenReceiver
    )   ?? panic("Cannot borrow FlowToken vault with Withdraw entitlement from account")
        
        // Withdraw the payment
        self.paymentVault <- flowTokenCap.withdraw(amount: price)


        // Borrow the NFT collection receiver reference
        let nftCollectionCap = acct.capabilities.borrow<&ExampleNFT.Collection>(
            ExampleNFT.CollectionPublicPath
        ) ?? panic("Cannot borrow NFT collection receiver from account")
        self.exampleNFTCollection = nftCollectionCap
    }

    execute {
        // Execute the purchase
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        // Confirm the token type and deposit the purchased NFT into the buyer's collection
        let nft <- item as! @ExampleNFT.NFT
        self.exampleNFTCollection.deposit(token: <-nft)

        // Cleanup the listing from the storefront
        self.storefront.cleanup(listingResourceID: 10)

        log("Transaction completed successfully")
    }
}