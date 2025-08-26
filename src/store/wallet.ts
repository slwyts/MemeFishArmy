import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

// 使用 defineStore 创建一个 store
export const useWalletStore = defineStore('wallet', () => {
  // State
  const connectedAddress = ref<string | null>(null)
  const chainId = ref<number | null>(null)
  const isConnecting = ref(false)

  // Getters (computed properties)
  const isConnected = computed(() => !!connectedAddress.value)
  const shortAddress = computed(() => {
    if (connectedAddress.value) {
      const addr = connectedAddress.value
      return `${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}`
    }
    return ''
  })

  // Actions (methods)
  function setAddress(address: string | null) {
    connectedAddress.value = address
  }

  function setChainId(id: number | null) {
    chainId.value = id
  }

  function setConnecting(status: boolean) {
    isConnecting.value = status
  }

  function reset() {
    connectedAddress.value = null
    chainId.value = null
    isConnecting.value = false
  }

  return {
    // State
    connectedAddress,
    chainId,
    isConnecting,
    // Getters
    isConnected,
    shortAddress,
    // Actions
    setAddress,
    setChainId,
    setConnecting,
    reset
  }
})