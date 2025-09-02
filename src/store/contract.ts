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
  const baseURI = ref<string | null>(null)
  const royaltyBps = ref<number | null>(null)

  const whitelist = ref<string[]>([])
  const holders = ref<Record<string, number[]>>({})
  const hasScanned = ref(false)


  const { getProvider, getSigner, getContract } = useWallet()
  const walletStore = useWalletStore()

  async function fetchContractData() {
    isLoading.value = true
    try {
      const provider = getProvider()
      const contract = getContract(provider)

      const [maxMints, owner, tokenOneUri, royaltyInfo] = await Promise.all([
        contract.maxMintsPerUser(),
        contract.owner(),
        contract.uri(1),
        contract.royaltyInfo(1, 10000)
      ])

      maxMintsPerUser.value = Number(maxMints)
      ownerAddress.value = owner

      if (tokenOneUri && typeof tokenOneUri === 'string') {
        const lastSlashIndex = tokenOneUri.lastIndexOf('/')
        if (lastSlashIndex !== -1) {
          baseURI.value = tokenOneUri.substring(0, lastSlashIndex + 1)
        }
      }

      if (royaltyInfo && royaltyInfo.length > 1) {
        royaltyBps.value = Number(royaltyInfo[1])
      }

    } catch (error) {
      console.error("Failed to fetch contract data:", error)
      maxMintsPerUser.value = 0
      ownerAddress.value = null
      baseURI.value = null
      royaltyBps.value = null
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
      isWhitelisted.value = false
      userMintCount.value = 0
    }
  }

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
      const tx = await contractWithSigner.mint()
      mintTxHash.value = tx.hash
      await tx.wait()
      await fetchUserData()
    } catch (error: any) {
      console.error("Minting failed:", error)
      mintError.value = error.reason || "An unknown error occurred."
    } finally {
      isMinting.value = false
    }
  }
  
  async function scanForWhitelist() {
    try {
      const provider = getProvider()
      const contract = getContract(provider)
      const filter = contract.filters.WhitelistUpdated()
      const events = await contract.queryFilter(filter)

      const currentWhitelist = new Map<string, boolean>()
      events.forEach((event: any) => {
        if (event.args) {
          const user = event.args.user
          const added = event.args.added
          currentWhitelist.set(user, added)
        }
      })

      const addresses: string[] = []
      currentWhitelist.forEach((isAdded, address) => {
        if (isAdded) {
          addresses.push(address)
        }
      })
      whitelist.value = addresses
    } catch (error) {
      console.error("Failed to scan for whitelist:", error)
      whitelist.value = []
    }
  }

  async function scanForHolders() {
     try {
        const provider = getProvider()
        const contract = getContract(provider)
        const zeroAddress = '0x0000000000000000000000000000000000000000'

        const singleFilter = contract.filters.TransferSingle()
        const batchFilter = contract.filters.TransferBatch()

        const [singleEvents, batchEvents] = await Promise.all([
            contract.queryFilter(singleFilter),
            contract.queryFilter(batchFilter)
        ]);

        const ownership = new Map<number, string>()

        batchEvents.forEach((event: any) => {
            if (event.args && event.args.from === zeroAddress) {
                const ids = event.args.ids.map(Number)
                const to = event.args.to
                ids.forEach((id: number) => ownership.set(id, to))
            }
        });

        singleEvents.forEach((event: any) => {
            if (event.args && event.args.from === zeroAddress) {
                const id = Number(event.args.id)
                const to = event.args.to
                ownership.set(id, to)
            }
        });
        
        const finalHolders: Record<string, number[]> = {}
        ownership.forEach((owner, tokenId) => {
            if (!finalHolders[owner]) {
                finalHolders[owner] = []
            }
            finalHolders[owner].push(tokenId)
        });

        for (const owner in finalHolders) {
            finalHolders[owner].sort((a, b) => a - b);
        }

        holders.value = finalHolders

     } catch (error) {
         console.error("Failed to scan for holders:", error)
         holders.value = {}
     }
  }
    
  // ** FIX: Added space between async and function **
  async function fetchAllQueryData() {
      if (hasScanned.value) return; 
      isLoading.value = true;
      try {
          await Promise.all([scanForWhitelist(), scanForHolders()]);
          hasScanned.value = true;
      } catch (error) {
          console.error("Failed to fetch all query data:", error);
      } finally {
          isLoading.value = false;
      }
  }

  const adminAction = async (methodName: string, ...args: any[]) => {
    const signer = await getSigner()
    const contractWithSigner = getContract(signer)
    const tx = await contractWithSigner[methodName](...args)
    await tx.wait()
    await fetchContractData()
    hasScanned.value = false;
    whitelist.value = [];
    holders.value = {};
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
    totalSupply,
    maxMintsPerUser,
    isLoading,
    isWhitelisted,
    userMintCount,
    isMinting,
    mintTxHash,
    mintError,
    ownerAddress,
    baseURI,       
    royaltyBps,
    whitelist,
    holders,
    hasScanned,
    fetchContractData,
    fetchUserData,
    handleMint,
    updateWhitelist,
    setMaxMints,
    setBaseURI,
    setRoyalty,
    scanForWhitelist,
    scanForHolders,
    fetchAllQueryData,
  }
})