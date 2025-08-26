import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useWallet } from '../composables/useWallet'
import { useWalletStore } from './wallet'
import { ethers } from 'ethers'

export const useContractStore = defineStore('contract', () => {
  // State
  const totalSupply = ref(5000)
  const maxMintsPerUser = ref(0)
  const isLoading = ref(false)
  const ownerAddress = ref<string | null>(null)
  // User-specific state
  const isWhitelisted = ref(false)
  const userMintCount = ref(0)

  // Minting process state
  const isMinting = ref(false)
  const mintTxHash = ref<string | null>(null)
  const mintError = ref<string | null>(null)

  const { getProvider, getSigner, getContract } = useWallet() // 确保 getSigner 和 getContract 已导入
  const walletStore = useWalletStore()

  // Actions
  async function fetchContractData() {
    // ... 此函数保持不变 ...
    isLoading.value = true
    try {
      const provider = new ethers.JsonRpcProvider('https://bsc-dataseed.binance.org/')
      const contract = getContract(provider)

      const [maxMints, owner] = await Promise.all([
        contract.maxMintsPerUser(),
        contract.owner() // 新增
      ])
        maxMintsPerUser.value = Number(maxMints)
        ownerAddress.value = owner // 新增
    } catch (error) {
      console.error("Failed to fetch contract data:", error)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchUserData() {
    // ... 此函数保持不变 ...
    if (!walletStore.isConnected || !walletStore.connectedAddress) return

    try {
      const provider = getProvider()
      const contract = getContract(provider)
      const address = walletStore.connectedAddress

      const [whitelisted, mintedCount] = await Promise.all([
        contract.whitelist(address),
        contract.userMintCount(address)
      ])

      isWhitelisted.value = whitelisted
      userMintCount.value = Number(mintedCount)

    } catch (error) {
      console.error("Failed to fetch user data:", error)
    }
  }

  // --- 新增的 MINT 函数 ---
  async function handleMint() {
    if (!walletStore.isConnected) {
      alert("Please connect your wallet first.")
      return
    }

    isMinting.value = true
    mintError.value = null
    mintTxHash.value = null

    try {
      // 对于写入操作，我们需要 Signer
      const signer = await getSigner()
      const contractWithSigner = getContract(signer)

      console.log("Sending mint transaction...")
      const tx = await contractWithSigner.mint()

      console.log("Transaction sent, waiting for confirmation...", tx.hash)
      mintTxHash.value = tx.hash

      await tx.wait() // 等待交易被区块链确认
      console.log("Transaction confirmed!")

      // Mint 成功后，立即更新用户的铸造数量
      await fetchUserData()

    } catch (error: any) {
      console.error("Minting failed:", error)
      // 尝试提取更友好的错误信息
      const reason = error.reason || "An unknown error occurred."
      mintError.value = reason
    } finally {
      isMinting.value = false
    }
  }

  // --- Admin Actions ---
const adminAction = async (methodName: string, ...args: any[]) => {
  const signer = await getSigner()
  const contractWithSigner = getContract(signer)

  const tx = await contractWithSigner[methodName](...args)
  await tx.wait()
}

const updateWhitelist = async (addresses: string[], statuses: boolean[]) => {
  if (addresses.length === 1) {
    const action = statuses[0] ? 'addToWhitelist' : 'removeFromWhitelist'
    await adminAction(action, addresses[0])
  } else {
    await adminAction('batchUpdateWhitelist', addresses, statuses)
  }
}

const setMaxMints = async (limit: number) => {
  await adminAction('setMaxMintsPerUser', limit)
}

const setBaseURI = async (uri: string) => {
  await adminAction('setBaseURI', uri)
}

const setRoyalty = async (royaltyBps: number) => {
  await adminAction('setRoyalty', royaltyBps)
}

  return {
    // State
    totalSupply,
    maxMintsPerUser,
    isLoading,
    isWhitelisted,
    userMintCount,
    isMinting,
    mintTxHash,
    mintError,
    ownerAddress,
    fetchContractData,
    fetchUserData,
    handleMint,
    updateWhitelist,
    setMaxMints,
    setBaseURI,
    setRoyalty
  }
})