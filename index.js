// Pass the repo name
const recipe = "purchase-nft-on-marketplace";

//Generate paths of each code file to render
const contractPath = `${recipe}/cadence/contract.cdc`;
const transactionPath = `${recipe}/cadence/transaction.cdc`;

//Generate paths of each explanation file to render
const smartContractExplanationPath = `${recipe}/explanations/contract.txt`;
const transactionExplanationPath = `${recipe}/explanations/transaction.txt`;

export const purchaseNftOnMarketplace = {
  slug: recipe,
  title: "Purchase NFT on Marketplace",
  createdAt: new Date(2022, 3, 1),
  author: "Flow Blockchain",
  playgroundLink:
    "https://play.onflow.org/1d11f838-fc0e-4e7f-86e3-6d1a5a1098e3?type=tx&id=7c4fa7ca-5770-4dd4-97d3-ed575f208d22&storage=none",
  excerpt: "Buy an NFT from a marketplace.",
  smartContractCode: contractPath,
  smartContractExplanation: smartContractExplanationPath,
  transactionCode: transactionPath,
  transactionExplanation: transactionExplanationPath,
  filters: {
    difficulty: "intermediate",
  },
};
