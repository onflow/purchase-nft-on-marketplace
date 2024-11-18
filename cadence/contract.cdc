// Rest of NFTStorefront contract above

access(all)
fun purchase(payment: @FungibleToken.Vault): @NonFungibleToken.NFT {
    pre {
        self.details.purchased == false: "Listing has already been purchased"
        payment.isInstance(self.details.salePaymentVaultType): "Payment vault is not the requested fungible token type"
        payment.balance == self.details.salePrice: "Payment vault does not contain the requested price"
    }

    // Mark the listing as purchased to prevent further purchases
    self.details.setToPurchased()

    // Fetch the NFT to return to the purchaser
    let nft <- self.nftProviderCapability
        .borrow()!
        .withdraw(withdrawID: self.details.nftID)

    // Neither receivers nor providers are trustworthy, they must implement the correct
    // interface but beyond complying with its pre/post conditions they are not gauranteed
    // to implement the functionality behind the interface in any given way.
    // Therefore we cannot trust the Collection resource behind the interface,
    // and we must check the NFT resource it gives us to make sure that it is the correct one.
    
    // Validate the NFT type and ID
    assert(nft.isInstance(self.details.nftType), message: "Withdrawn NFT is not of the specified type")
    assert(nft.id == self.details.nftID, message: "Withdrawn NFT does not have the specified ID")

    // Rather than aborting the transaction if any receiver is absent when we try to pay it,
    // we send the cut to the first valid receiver.
    // The first receiver should therefore either be the seller, or an agreed recipient for
    // any unpaid cuts.
    var residualReceiver: &{FungibleToken.Receiver}? = nil

    // Pay each beneficiary their portion of the payment
    for cut in self.details.saleCuts {
        if let receiver = cut.receiver.borrow() {
            let paymentCut <- payment.withdraw(amount: cut.amount)
            receiver.deposit(from: <-paymentCut)
            if residualReceiver == nil {
                residualReceiver = receiver
            }
        }
    }

    // Ensure at least one payment receiver was available
    assert(residualReceiver != nil, message: "No valid payment receivers")

    // Deposit any remaining payment to the first valid receiver
    residualReceiver!.deposit(from: <-payment)

    // Emit a completion event for the listing
    emit ListingCompleted(
        listingResourceID: self.uuid,
        storefrontResourceID: self.details.storefrontID,
        purchased: self.details.purchased
    )

    // Return the purchased NFT to the buyer
    return <-nft
}

// Rest of NFTStorefront contract below