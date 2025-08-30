import { ethers, type Contract } from 'ethers'
import { useWalletStore } from '../store/wallet'
import { memeFishArmyAddress, memeFishArmyAbi, desiredChainId } from '../contracts'

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
    
  // 切换网络
  const switchNetwork = async () => {
    const provider = getProvider()
    const chainIdHex = '0x' + desiredChainId.toString(16) // 手动转换为十六进制字符串

    try {
      await provider.send('wallet_switchEthereumChain', [{ chainId: chainIdHex }]);
    } catch (switchError: any) {
      // This error code indicates that the chain has not been added to MetaMask.
      if (switchError.code === 4902) {
        try {
            // 在这里添加你的网络信息
          await provider.send('wallet_addEthereumChain', [
            {
              chainId: chainIdHex,
              chainName: 'Polygon Mainnet',
              rpcUrls: ['https://polygon-rpc.com/'],
              nativeCurrency: {
                  name: "POL",
                  symbol: "POL",
                  decimals: 18,
              },
              blockExplorerUrls: ["https://polygonscan.com/"]
            },
          ]);
        } catch (addError) {
          console.error("Failed to add the network", addError)
        }
      }
      console.error("Failed to switch to the network", switchError)
    }
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
        if(Number(network.chainId) !== desiredChainId){
            await switchNetwork()
        }
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
    if(parseInt(chainIdHex, 16) !== desiredChainId) {
        switchNetwork()
    }
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