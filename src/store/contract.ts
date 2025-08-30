// src/store/contract.ts

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useWallet } from '../composables/useWallet'
import { useWalletStore } from './wallet'

export const useContractStore = defineStore('contract', () => {
  const totalSupply = ref(5000)
  const maxMintsPerUser = ref(0)
  const isLoading = ref(false)
  const ownerAddress = ref<string | null>(null)
  const isWhitelisted = ref(false)
  const userMintCount = ref(0)
  const isMinting = ref(false)
  const mintTxHash = ref<string | null>(null)
  const mintError = ref<string | null>(null)

  const { getProvider, getSigner, getContract } = useWallet()
  const walletStore = useWalletStore()

  async function fetchContractData() {
    // Rimuovi il controllo !walletStore.isConnected
    isLoading.value = true
    try {
      const provider = getProvider()
      const contract = getContract(provider)

      const [maxMints, owner] = await Promise.all([
        contract.maxMintsPerUser(),
        contract.owner(),
      ])
      maxMintsPerUser.value = Number(maxMints)
      ownerAddress.value = owner
    } catch (error) {
      console.error("Failed to fetch contract data:", error)
      maxMintsPerUser.value = 0
      ownerAddress.value = null
    } finally {
      isLoading.value = false
    }
  }

  async function fetchUserData() {
    if (!walletStore.isConnected || !walletStore.connectedAddress) return

    try {
      const provider = getProvider()
      const contract = getContract(provider)
      const address = walletStore.connectedAddress

      const [whitelisted, mintedCount] = await Promise.all([
        contract.whitelist(address),
        contract.userMintCount(address),
      ])

      isWhitelisted.value = whitelisted
      userMintCount.value = Number(mintedCount)
    } catch (error) {
      console.error("Failed to fetch user data:", error)
      // Reset values
      isWhitelisted.value = false
      userMintCount.value = 0
    }
  }

  // --- Funzione di Mint ---
  async function handleMint() {
    if (!walletStore.isConnected) {
      alert("Please connect your wallet first.")
      return
    }

    isMinting.value = true
    mintError.value = null
    mintTxHash.value = null

    try {
      const signer = await getSigner()
      const contractWithSigner = getContract(signer)

      console.log("Sending mint transaction...")
      const tx = await contractWithSigner.mint()

      console.log("Transaction sent, waiting for confirmation...", tx.hash)
      mintTxHash.value = tx.hash

      await tx.wait()
      console.log("Transaction confirmed!")

      await fetchUserData()
    } catch (error: any) {
      console.error("Minting failed:", error)
      const reason = error.reason || "An unknown error occurred."
      mintError.value = reason
    } finally {
      isMinting.value = false
    }
  }

  // --- Azioni Admin ---
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
    // Actions
    fetchContractData,
    fetchUserData,
    handleMint,
    updateWhitelist,
    setMaxMints,
    setBaseURI,
    setRoyalty,
  }
})