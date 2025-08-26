import { ethers, type Contract } from 'ethers'
import { useWalletStore } from '../store/wallet'
import { memeFishArmyAddress, memeFishArmyAbi } from '../contracts'
// TypeScript 用户注意：你可能需要安装 @types/node 来获取 NodeJS.Global 定义
// npm install -D @types/node
declare global {
  interface Window {
    ethereum?: any
  }
}

export function useWallet() {
  const walletStore = useWalletStore()

  // 检查浏览器是否安装了 MetaMask 等钱包
  const isWalletInstalled = (): boolean => {
    return typeof window.ethereum !== 'undefined'
  }

  // 获取 Provider 和 Signer
  const getProvider = () => {
    if (!isWalletInstalled()) throw new Error('Wallet not installed.')
    return new ethers.BrowserProvider(window.ethereum)
  }

  const getSigner = async () => {
    const provider = getProvider()
    return await provider.getSigner()
  }

  // 连接钱包的核心函数
  const connect = async () => {
    if (walletStore.isConnecting) return
    if (!isWalletInstalled()) {
      alert('Please install a wallet like MetaMask.')
      return
    }

    walletStore.setConnecting(true)
    try {
      const provider = getProvider()
      const accounts = await provider.send('eth_requestAccounts', [])

      if (accounts.length > 0) {
        walletStore.setAddress(accounts[0])
        const network = await provider.getNetwork()
        walletStore.setChainId(Number(network.chainId))
        setupListeners() // 连接成功后设置监听器
      }
    } catch (error) {
      console.error('Failed to connect wallet:', error)
      walletStore.reset()
    } finally {
      walletStore.setConnecting(false)
    }
  }

  // 断开连接 (实际上是重置状态)
  const disconnect = () => {
    walletStore.reset()
    // 移除监听器以避免内存泄漏
    if (isWalletInstalled()) {
      window.ethereum.removeListener('accountsChanged', handleAccountsChanged)
      window.ethereum.removeListener('chainChanged', handleChainChanged)
    }
  }

  // 处理账户切换
  const handleAccountsChanged = (accounts: string[]) => {
    if (accounts.length === 0) {
      // 用户锁定了钱包或断开了所有账户的连接
      disconnect()
    } else {
      walletStore.setAddress(accounts[0])
    }
  }

  // 处理网络切换
  const handleChainChanged = (chainIdHex: string) => {
    walletStore.setChainId(parseInt(chainIdHex, 16))
  }

  // 设置事件监听器
  const setupListeners = () => {
    if (isWalletInstalled()) {
      window.ethereum.on('accountsChanged', handleAccountsChanged)
      window.ethereum.on('chainChanged', handleChainChanged)
    }
  }

  const getContract = (signerOrProvider: ethers.Signer | ethers.Provider): Contract => {
    return new ethers.Contract(memeFishArmyAddress, memeFishArmyAbi, signerOrProvider)
  }

  return {
    connect,
    disconnect,
    isWalletInstalled,
    getProvider,
    getSigner,
    getContract,
  }
}