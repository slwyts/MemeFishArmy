<template>
  <div class="space-y-8">
    <!-- 重要提示：权限转移和版税设置 -->
    <div class="bg-gradient-to-r from-red-500/20 to-orange-500/20 backdrop-blur-sm p-6 rounded-2xl border-2 border-red-500/50">
      <div class="flex items-start space-x-4">
        <div class="text-4xl">⚠️</div>
        <div class="flex-1">
          <h3 class="text-xl font-bold text-red-400 mb-2">重要：合约权限配置（必须按顺序执行）</h3>
          <div class="space-y-2 text-sm text-gray-300">
            <p class="font-semibold">部署 MFACSystem 后的配置步骤：</p>
            <ol class="list-decimal list-inside space-y-2 ml-4">
              <li>
                <strong class="text-yellow-400">步骤 1：转移 NFT 合约所有权</strong><br/>
                <span class="ml-6">在老 NFT 合约 (0x1792...60dC) 调用 <code class="bg-slate-800 px-2 py-0.5 rounded text-cyan-400">transferOwnership(MFACSystem合约地址)</code></span><br/>
                <span class="ml-6 text-gray-400">→ 这样 MFACSystem 才能调用 NFT 合约的 addToWhitelist 等管理员功能</span>
              </li>
              <li>
                <strong class="text-yellow-400">步骤 2：设置 NFT 版税接收者</strong><br/>
                <span class="ml-6">在本页面点击下方 "🎨 设置 NFT 版税接收者" 按钮</span><br/>
                <span class="ml-6 text-gray-400">→ 这样 NFT 在交易市场（OpenSea等）的 5% 版税会打到 MFACSystem 合约</span>
              </li>
              <li>
                <strong class="text-green-400">完成配置</strong><br/>
                <span class="ml-6 text-gray-400">→ 老的 NFT 管理员页面将不再可用，请使用本页面管理所有功能</span>
              </li>
            </ol>
            <div class="mt-4 pt-4 border-t border-slate-600 space-y-1">
              <p class="text-yellow-400">
                ⚡ 老 NFT 合约地址: <code class="bg-slate-800 px-2 py-0.5 rounded">{{ nftContractAddress }}</code>
              </p>
              <p class="text-green-400">
                ✅ MFACSystem 合约地址: <code class="bg-slate-800 px-2 py-0.5 rounded">{{ mfacSystemAddress }}</code>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- NFT 版税设置（步骤 2 操作按钮） -->
    <div class="bg-gradient-to-r from-purple-500/20 to-pink-500/20 backdrop-blur-sm p-6 rounded-2xl border-2 border-purple-500/50">
      <div class="flex items-center justify-between">
        <div class="flex items-start space-x-4 flex-1">
          <div class="text-4xl">🎨</div>
          <div>
            <h3 class="text-xl font-bold text-purple-300 mb-2">NFT 版税接收者设置</h3>
            <p class="text-sm text-gray-300 mb-2">
              点击此按钮将老 NFT 合约的版税接收者设置为 MFACSystem 合约地址
            </p>
            <p class="text-xs text-gray-400">
              ⚠️ 前提：必须先完成步骤 1（transferOwnership）
            </p>
          </div>
        </div>
        <button
          @click="handleSetNFTRoyaltyReceiver"
          :disabled="loading.setRoyalty"
          class="px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold rounded-xl hover:from-purple-700 hover:to-pink-700 transition-all transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 shadow-lg"
        >
          <i v-if="loading.setRoyalty" class="fa fa-spinner fa-spin mr-2"></i>
          <span v-else>🎨</span>
          设置版税接收者
        </button>
      </div>
    </div>

    <!-- NFT 白名单管理 -->
    <div class="bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700">
      <h2 class="text-2xl font-bold text-white mb-6">🎫 NFT 白名单管理</h2>
      
      <div class="space-y-6">
        <!-- 单个地址 -->
        <div>
          <label class="block text-sm font-semibold text-gray-300 mb-2">单个地址</label>
          <input
            v-model="singleAddress"
            type="text"
            placeholder="0x..."
            class="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
          />
          <div class="flex space-x-3 mt-3">
            <button
              @click="handleAddToWhitelist(false)"
              :disabled="loading.addSingle"
              class="flex-1 px-4 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed"
            >
              <i v-if="loading.addSingle" class="fa fa-spinner fa-spin mr-2"></i>
              添加到白名单
            </button>
            <button
              @click="handleRemoveFromWhitelist(false)"
              :disabled="loading.removeSingle"
              class="flex-1 px-4 py-2 bg-red-600 text-white font-semibold rounded-lg hover:bg-red-700 transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed"
            >
              <i v-if="loading.removeSingle" class="fa fa-spinner fa-spin mr-2"></i>
              移除白名单
            </button>
          </div>
        </div>

        <!-- 批量地址 -->
        <div>
          <label class="block text-sm font-semibold text-gray-300 mb-2">批量地址（每行一个）</label>
          <textarea
            v-model="batchAddresses"
            rows="5"
            placeholder="0x...&#10;0x...&#10;0x..."
            class="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none font-mono text-sm"
          ></textarea>
          <div class="flex space-x-3 mt-3">
            <button
              @click="handleAddToWhitelist(true)"
              :disabled="loading.addBatch"
              class="flex-1 px-4 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed"
            >
              <i v-if="loading.addBatch" class="fa fa-spinner fa-spin mr-2"></i>
              批量添加
            </button>
            <button
              @click="handleRemoveFromWhitelist(true)"
              :disabled="loading.removeBatch"
              class="flex-1 px-4 py-2 bg-red-600 text-white font-semibold rounded-lg hover:bg-red-700 transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed"
            >
              <i v-if="loading.removeBatch" class="fa fa-spinner fa-spin mr-2"></i>
              批量移除
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- 系统参数设置 -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- 空投控制 -->
      <div class="bg-slate-900/80 backdrop-blur-sm p-6 rounded-2xl border border-slate-700">
        <h3 class="text-xl font-bold text-white mb-4">🎁 空投控制</h3>
        
        <div class="space-y-4">
          <div class="flex items-center justify-between p-4 bg-slate-800/50 rounded-lg">
            <div>
              <div class="font-semibold text-white">空投状态</div>
              <div class="text-sm text-gray-400">
                {{ airdropStarted ? '已开启' : '未开启' }}
              </div>
            </div>
            <button
              v-if="!airdropStarted"
              @click="handleStartAirdrop"
              :disabled="loading.startAirdrop"
              class="px-6 py-2 bg-green-600 text-white font-bold rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-500"
            >
              <i v-if="loading.startAirdrop" class="fa fa-spinner fa-spin mr-2"></i>
              开启空投
            </button>
            <span v-else class="text-green-400 font-bold">✓ 已开启</span>
          </div>

          <div v-if="airdropStarted" class="p-4 bg-blue-900/20 border border-blue-500/30 rounded-lg">
            <div class="text-sm text-blue-300">
              <div class="flex justify-between mb-1">
                <span>开始时间:</span>
                <span class="font-mono">{{ formatTimestamp(mfacStore.stats?.airdropStartTime) }}</span>
              </div>
              <div class="flex justify-between">
                <span>剩余天数:</span>
                <span class="font-bold">{{ mfacStore.airdropDaysRemaining }} 天</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 交易费用开关 -->
      <div class="bg-slate-900/80 backdrop-blur-sm p-6 rounded-2xl border border-slate-700">
        <h3 class="text-xl font-bold text-white mb-4">💰 交易费用</h3>
        
        <div class="space-y-4">
          <div class="flex items-center justify-between p-4 bg-slate-800/50 rounded-lg">
            <div>
              <div class="font-semibold text-white">费用开关</div>
              <div class="text-sm text-gray-400">
                买入 1% / 卖出 2%
              </div>
            </div>
            <button
              @click="handleToggleFees"
              :disabled="loading.toggleFees"
              class="px-6 py-2 font-bold rounded-lg transition-colors disabled:bg-gray-500"
              :class="feesEnabled ? 'bg-green-600 hover:bg-green-700 text-white' : 'bg-gray-600 hover:bg-gray-700 text-white'"
            >
              <i v-if="loading.toggleFees" class="fa fa-spinner fa-spin mr-2"></i>
              {{ feesEnabled ? '已开启' : '已关闭' }}
            </button>
          </div>

          <div class="grid grid-cols-2 gap-3 text-center text-sm">
            <div class="p-3 bg-green-900/20 border border-green-500/30 rounded-lg">
              <div class="text-gray-400">买入税</div>
              <div class="text-2xl font-bold text-green-400">1%</div>
            </div>
            <div class="p-3 bg-red-900/20 border border-red-500/30 rounded-lg">
              <div class="text-gray-400">卖出税</div>
              <div class="text-2xl font-bold text-red-400">2%</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 池子余额统计 -->
    <div class="bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700">
      <h2 class="text-2xl font-bold text-white mb-6">📊 池子余额统计</h2>
      
      <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
        <div class="p-4 bg-gradient-to-br from-green-900/30 to-green-800/20 border border-green-500/30 rounded-xl">
          <div class="text-sm text-green-300 mb-1">质押池</div>
          <div class="text-2xl font-bold text-white">
            {{ formatAmount(mfacStore.stats?.stakingPoolRemaining) }}
          </div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>

        <div class="p-4 bg-gradient-to-br from-blue-900/30 to-blue-800/20 border border-blue-500/30 rounded-xl">
          <div class="text-sm text-blue-300 mb-1">流通NFT分红</div>
          <div class="text-2xl font-bold text-white">
            {{ formatAmount(mfacStore.stats?.circulatingDividendPool) }}
          </div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>

        <div class="p-4 bg-gradient-to-br from-purple-900/30 to-purple-800/20 border border-purple-500/30 rounded-xl">
          <div class="text-sm text-purple-300 mb-1">SBT分红</div>
          <div class="text-2xl font-bold text-white">
            {{ formatAmount(mfacStore.stats?.sbtDividendPool) }}
          </div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>

        <div class="p-4 bg-gradient-to-br from-yellow-900/30 to-yellow-800/20 border border-yellow-500/30 rounded-xl">
          <div class="text-sm text-yellow-300 mb-1">DAO 国库</div>
          <div class="text-2xl font-bold text-white">
            {{ formatAmount(mfacStore.stats?.daoTreasury) }}
          </div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>

        <div class="p-4 bg-gradient-to-br from-orange-900/30 to-orange-800/20 border border-orange-500/30 rounded-xl">
          <div class="text-sm text-orange-300 mb-1">Builder 池</div>
          <div class="text-2xl font-bold text-white">
            {{ formatAmount(mfacStore.stats?.superBuilderPoolRemaining) }}
          </div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>

        <div class="p-4 bg-gradient-to-br from-pink-900/30 to-pink-800/20 border border-pink-500/30 rounded-xl">
          <div class="text-sm text-pink-300 mb-1">💎 NFT版税池</div>
          <div class="text-2xl font-bold text-white">
            {{ formatBNB(mfacStore.stats?.nftRoyaltyPool) }}
          </div>
          <div class="text-xs text-gray-400">BNB</div>
        </div>

        <div class="p-4 bg-gradient-to-br from-indigo-900/30 to-indigo-800/20 border border-indigo-500/30 rounded-xl">
          <div class="text-sm text-indigo-300 mb-1">📈 累计版税收入</div>
          <div class="text-2xl font-bold text-white">
            {{ formatBNB(mfacStore.stats?.totalNFTRoyaltyReceived) }}
          </div>
          <div class="text-xs text-gray-400">BNB</div>
        </div>
      </div>
    </div>

    <!-- 成功/错误提示 -->
    <div v-if="successMessage" class="bg-green-500/20 border border-green-500/50 rounded-lg p-4">
      <p class="text-green-400 font-semibold">✓ {{ successMessage }}</p>
    </div>

    <div v-if="errorMessage" class="bg-red-500/20 border border-red-500/50 rounded-lg p-4">
      <p class="text-red-400 font-semibold">✗ {{ errorMessage }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useMFACSystemStore } from '@/store/mfacSystem'
import { useWalletStore } from '@/store/wallet'
import { ethers } from 'ethers'
import { mfacSystemAddress as mfacContractAddress, mfacSystemAbi } from '@/contracts'

const mfacStore = useMFACSystemStore()
const walletStore = useWalletStore()

const singleAddress = ref('')
const batchAddresses = ref('')
const successMessage = ref('')
const errorMessage = ref('')

const loading = ref({
  addSingle: false,
  removeSingle: false,
  addBatch: false,
  removeBatch: false,
  startAirdrop: false,
  toggleFees: false,
  setRoyalty: false
})

const nftContractAddress = import.meta.env.VITE_NFT_CONTRACT_ADDRESS
const mfacSystemAddress = import.meta.env.VITE_MFAC_SYSTEM_CONTRACT_ADDRESS

// Helper function to get MFACSystem contract
const getMFACContract = (signerOrProvider: ethers.Signer | ethers.Provider) => {
  return new ethers.Contract(mfacContractAddress, mfacSystemAbi, signerOrProvider)
}

const airdropStarted = computed(() => mfacStore.airdropStarted)
const feesEnabled = computed(() => {
  // 需要从合约读取，暂时返回 true
  return true
})

const formatAmount = (amount: bigint | undefined): string => {
  if (!amount) return '0'
  const value = Number(amount) / 1e18
  return value.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  })
}

const formatBNB = (amount: bigint | undefined): string => {
  if (!amount) return '0'
  const value = Number(amount) / 1e18
  return value.toLocaleString(undefined, {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4
  })
}

const formatTimestamp = (timestamp: bigint | undefined): string => {
  if (!timestamp) return '--'
  const date = new Date(Number(timestamp) * 1000)
  return date.toLocaleString('zh-CN')
}

const clearMessages = () => {
  successMessage.value = ''
  errorMessage.value = ''
  setTimeout(() => {
    successMessage.value = ''
    errorMessage.value = ''
  }, 5000)
}

const handleAddToWhitelist = async (isBatch: boolean) => {
  clearMessages()
  const key = isBatch ? 'addBatch' : 'addSingle'
  loading.value[key] = true

  try {
    const addresses = isBatch
      ? batchAddresses.value.split('\n').filter(a => a.trim() !== '').map(a => a.trim())
      : [singleAddress.value.trim()]

    if (addresses.length === 0) {
      errorMessage.value = '请输入地址'
      return
    }

    // 验证地址格式
    for (const addr of addresses) {
      if (!ethers.isAddress(addr)) {
        errorMessage.value = `无效的地址: ${addr}`
        return
      }
    }

    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()
    const contract = getMFACContract(signer)

    // 批量添加白名单
    for (const addr of addresses) {
      const tx = await contract.addToWhitelist(addr)
      await tx.wait()
    }

    successMessage.value = `成功添加 ${addresses.length} 个地址到白名单`
    
    if (isBatch) {
      batchAddresses.value = ''
    } else {
      singleAddress.value = ''
    }
  } catch (err: any) {
    errorMessage.value = err.message || '操作失败'
    console.error('Add to whitelist failed:', err)
  } finally {
    loading.value[key] = false
  }
}

const handleRemoveFromWhitelist = async (isBatch: boolean) => {
  clearMessages()
  const key = isBatch ? 'removeBatch' : 'removeSingle'
  loading.value[key] = true

  try {
    const addresses = isBatch
      ? batchAddresses.value.split('\n').filter(a => a.trim() !== '').map(a => a.trim())
      : [singleAddress.value.trim()]

    if (addresses.length === 0) {
      errorMessage.value = '请输入地址'
      return
    }

    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()
    const contract = getMFACContract(signer)

    for (const addr of addresses) {
      const tx = await contract.removeFromWhitelist(addr)
      await tx.wait()
    }

    successMessage.value = `成功移除 ${addresses.length} 个地址`
    
    if (isBatch) {
      batchAddresses.value = ''
    } else {
      singleAddress.value = ''
    }
  } catch (err: any) {
    errorMessage.value = err.message || '操作失败'
    console.error('Remove from whitelist failed:', err)
  } finally {
    loading.value[key] = false
  }
}

const handleStartAirdrop = async () => {
  clearMessages()
  loading.value.startAirdrop = true

  try {
    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()
    const contract = getMFACContract(signer)

    const tx = await contract.startAirdrop()
    await tx.wait()

    successMessage.value = '✓ 空投已成功开启！'
    await mfacStore.fetchContractStats()
  } catch (err: any) {
    errorMessage.value = err.message || '开启空投失败'
    console.error('Start airdrop failed:', err)
  } finally {
    loading.value.startAirdrop = false
  }
}

const handleToggleFees = async () => {
  clearMessages()
  loading.value.toggleFees = true

  try {
    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()
    const contract = getMFACContract(signer)

    const tx = await contract.setFeesEnabled(!feesEnabled.value)
    await tx.wait()

    successMessage.value = `✓ 交易费用已${!feesEnabled.value ? '开启' : '关闭'}`
  } catch (err: any) {
    errorMessage.value = err.message || '切换失败'
    console.error('Toggle fees failed:', err)
  } finally {
    loading.value.toggleFees = false
  }
}

/**
 * 设置 NFT 版税接收者
 * 此操作会调用 MFACSystem 的 setNFTRoyaltyReceiver() 函数
 * 该函数会代理调用老 NFT 合约的 setRoyalty(500)
 * 从而将版税接收者更新为 MFACSystem 合约地址
 */
const handleSetNFTRoyaltyReceiver = async () => {
  clearMessages()
  loading.value.setRoyalty = true

  try {
    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()
    const contract = getMFACContract(signer)

    // 调用合约的 setNFTRoyaltyReceiver 函数
    const tx = await contract.setNFTRoyaltyReceiver()
    await tx.wait()

    successMessage.value = '✓ 成功设置 NFT 版税接收者为 MFACSystem 合约！现在 NFT 交易的 5% 版税会自动打到本合约'
  } catch (err: any) {
    // 提供更友好的错误提示
    if (err.message.includes('MFACSystem must be NFT contract owner first')) {
      errorMessage.value = '❌ 失败：请先在老 NFT 合约执行 transferOwnership(MFACSystem地址)'
    } else if (err.message.includes('user rejected')) {
      errorMessage.value = '❌ 用户取消了交易'
    } else {
      errorMessage.value = `❌ 设置失败: ${err.message}`
    }
    console.error('Set NFT royalty receiver failed:', err)
  } finally {
    loading.value.setRoyalty = false
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
  }
})
</script>
