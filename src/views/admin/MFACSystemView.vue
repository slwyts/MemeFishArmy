<template>
  <div class="space-y-8">
    <!-- 核心数据概览 -->
    <div class="bg-slate-900/80 backdrop-blur-sm p-6 rounded-2xl border border-slate-700">
      <h2 class="text-xl font-bold text-white mb-4">📊 核心数据</h2>
      
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="p-4 bg-gradient-to-br from-emerald-900/30 to-emerald-800/20 border border-emerald-500/30 rounded-xl">
          <div class="text-xs text-gray-400 mb-1">NFT已售</div>
          <div class="text-2xl font-bold text-white">{{ stats?.nftsSold?.toString() || '0' }}</div>
          <div class="text-xs text-gray-500">/ 4500</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-blue-900/30 to-blue-800/20 border border-blue-500/30 rounded-xl">
          <div class="text-xs text-gray-400 mb-1">空投状态</div>
          <div class="text-lg font-bold text-white">{{ airdropStarted ? '进行中' : '未开始' }}</div>
          <div class="text-xs text-gray-500">{{ airdropStarted ? `剩余${airdropDaysRemaining}天` : '待首次领取' }}</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-slate-900/30 to-slate-800/20 border border-slate-500/30 rounded-xl">
          <div class="text-xs text-gray-400 mb-1">MFAC 余额</div>
          <div class="text-lg font-bold text-white">{{ formatMFAC(contractBalance) }}</div>
          <div class="text-xs text-gray-500">代币</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-purple-900/30 to-purple-800/20 border border-purple-500/30 rounded-xl">
          <div class="text-xs text-gray-400 mb-1">BNB 余额</div>
          <div class="text-lg font-bold text-white">{{ bnbBalance }}</div>
          <div class="text-xs text-gray-500">主币</div>
        </div>
      </div>
    </div>

    <!-- Tab 导航 -->
    <div class="bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700">
      <div class="flex border-b border-slate-700 overflow-x-auto">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'px-6 py-4 font-semibold whitespace-nowrap transition-all',
            activeTab === tab.id
              ? 'text-cyan-400 border-b-2 border-cyan-400 bg-cyan-500/10'
              : 'text-gray-400 hover:text-gray-300 hover:bg-slate-800/50'
          ]"
        >
          {{ tab.icon }} {{ tab.name }}
        </button>
      </div>

      <div class="p-8">
        <!-- 手续费配置 -->
        <div v-show="activeTab === 'fees'">
          <h3 class="text-xl font-bold text-white mb-6">交易手续费配置</h3>
          
          <div class="space-y-6">
            <!-- 手续费比例 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">手续费比例</label>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">买入手续费 (%)</label>
                  <input
                    v-model.number="buyFeeInput"
                    type="number"
                    min="0"
                    max="10"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">卖出手续费 (%)</label>
                  <input
                    v-model.number="sellFeeInput"
                    type="number"
                    min="0"
                    max="10"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
              </div>
              <button
                @click="updateFeePercents"
                :disabled="loading.feePercents"
                class="mt-4 w-full px-6 py-2 bg-cyan-600 hover:bg-cyan-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
              >
                <i v-if="loading.feePercents" class="fa fa-spinner fa-spin mr-2"></i>
                更新手续费比例
              </button>
            </div>

            <!-- 手续费分配比例 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">手续费分配比例（总计需为100%）</label>
              <div class="grid grid-cols-3 gap-4">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">流通NFT (%)</label>
                  <input
                    v-model.number="feeDistribution.circulating"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">SBT (%)</label>
                  <input
                    v-model.number="feeDistribution.sbt"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">DAO国库 (%)</label>
                  <input
                    v-model.number="feeDistribution.dao"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
              </div>
              <div class="mt-2 text-sm" :class="feeDistributionTotal === 100 ? 'text-green-400' : 'text-red-400'">
                总计: {{ feeDistributionTotal }}% {{ feeDistributionTotal === 100 ? '✓' : '✗ 必须等于100%' }}
              </div>
              <button
                @click="updateFeeDistribution"
                :disabled="loading.feeDistribution || feeDistributionTotal !== 100"
                class="mt-4 w-full px-6 py-2 bg-cyan-600 hover:bg-cyan-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
              >
                <i v-if="loading.feeDistribution" class="fa fa-spinner fa-spin mr-2"></i>
                更新分配比例
              </button>
            </div>
          </div>
        </div>

        <!-- DEX & 白名单 -->
        <div v-show="activeTab === 'dex'">
          <h3 class="text-xl font-bold text-white mb-6">DEX Pair & 免手续费地址</h3>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- DEX Pair 管理 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-2">DEX Pair 管理</label>
              <p class="text-xs text-gray-400 mb-4">设置 DEX 交易对地址（用于识别买卖方向）</p>
              <div class="space-y-3">
                <input
                  v-model="dexPairInput"
                  type="text"
                  placeholder="0x..."
                  class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                />
                <div class="flex space-x-3">
                  <button
                    @click="setDEXPair(true)"
                    :disabled="loading.dexPair"
                    class="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.dexPair" class="fa fa-spinner fa-spin mr-2"></i>
                    添加 Pair
                  </button>
                  <button
                    @click="setDEXPair(false)"
                    :disabled="loading.dexPair"
                    class="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.dexPair" class="fa fa-spinner fa-spin mr-2"></i>
                    移除 Pair
                  </button>
                </div>
              </div>
            </div>

            <!-- 免手续费地址 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-2">免手续费地址</label>
              <p class="text-xs text-gray-400 mb-4">设置不收取交易手续费的地址</p>
              <div class="space-y-3">
                <input
                  v-model="excludedAddressInput"
                  type="text"
                  placeholder="0x..."
                  class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                />
                <div class="flex space-x-3">
                  <button
                    @click="setExcludedFromFee(true)"
                    :disabled="loading.excludedFee"
                    class="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.excludedFee" class="fa fa-spinner fa-spin mr-2"></i>
                    添加豁免
                  </button>
                  <button
                    @click="setExcludedFromFee(false)"
                    :disabled="loading.excludedFee"
                    class="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.excludedFee" class="fa fa-spinner fa-spin mr-2"></i>
                    移除豁免
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 资金提取 -->
        <div v-show="activeTab === 'withdraw'">
          <h3 class="text-xl font-bold text-white mb-6">资金提取</h3>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- 提取 MFAC -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">提取 MFAC 代币</label>
              <div class="space-y-3">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">接收地址</label>
                  <input
                    v-model="withdrawMFAC.to"
                    type="text"
                    placeholder="0x..."
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">数量（MFAC）</label>
                  <input
                    v-model="withdrawMFAC.amount"
                    type="number"
                    step="0.01"
                    placeholder="1000"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <button
                  @click="handleWithdrawMFAC"
                  :disabled="loading.withdrawMFAC"
                  class="w-full px-6 py-2 bg-orange-600 hover:bg-orange-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
                >
                  <i v-if="loading.withdrawMFAC" class="fa fa-spinner fa-spin mr-2"></i>
                  💰 提取 MFAC
                </button>
              </div>
            </div>

            <!-- 提取 BNB -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">提取 BNB</label>
              <div class="space-y-3">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">接收地址</label>
                  <input
                    v-model="withdrawBNB.to"
                    type="text"
                    placeholder="0x..."
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">数量（BNB）</label>
                  <input
                    v-model="withdrawBNB.amount"
                    type="number"
                    step="0.001"
                    placeholder="1.0"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <button
                  @click="handleWithdrawBNB"
                  :disabled="loading.withdrawBNB"
                  class="w-full px-6 py-2 bg-yellow-600 hover:bg-yellow-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
                >
                  <i v-if="loading.withdrawBNB" class="fa fa-spinner fa-spin mr-2"></i>
                  💎 提取 BNB
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 成功/错误提示 -->
    <Transition name="fade">
      <div v-if="successMessage" class="bg-green-500/20 border border-green-500/50 rounded-lg p-4">
        <p class="text-green-400 font-semibold">✓ {{ successMessage }}</p>
      </div>
    </Transition>

    <Transition name="fade">
      <div v-if="errorMessage" class="bg-red-500/20 border border-red-500/50 rounded-lg p-4">
        <p class="text-red-400 font-semibold">✗ {{ errorMessage }}</p>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ethers } from 'ethers'
import { useMFACSystemStore } from '../../store/mfacSystem'
import { useWalletStore } from '../../store/wallet'
import { useWallet } from '../../composables/useWallet'

const mfacStore = useMFACSystemStore()
const walletStore = useWalletStore()

// Refs
const activeTab = ref('fees')
const bnbBalance = ref('0')

const tabs = [
  { id: 'fees', name: '手续费配置', icon: '💰' },
  { id: 'dex', name: 'DEX & 白名单', icon: '🔄' },
  { id: 'withdraw', name: '资金提取', icon: '💸' },
]

// Form inputs
const buyFeeInput = ref(1)
const sellFeeInput = ref(2)
const feeDistribution = ref({
  circulating: 30,
  sbt: 20,
  dao: 50,
})
const dexPairInput = ref('')
const excludedAddressInput = ref('')
const withdrawMFAC = ref({ to: '', amount: '' })
const withdrawBNB = ref({ to: '', amount: '' })

// Loading states
const loading = ref({
  feePercents: false,
  feeDistribution: false,
  dexPair: false,
  excludedFee: false,
  withdrawMFAC: false,
  withdrawBNB: false,
})

// Messages
const successMessage = ref('')
const errorMessage = ref('')

// Computed
const stats = computed(() => mfacStore.stats)
const contractBalance = computed(() => mfacStore.userTokenBalance) // 需要获取合约地址的余额
const airdropStarted = computed(() => mfacStore.airdropStarted)
const airdropDaysRemaining = computed(() => mfacStore.airdropDaysRemaining)
const feeDistributionTotal = computed(() => 
  feeDistribution.value.circulating + feeDistribution.value.sbt + feeDistribution.value.dao
)

// Helper functions
const formatMFAC = (amount: bigint | undefined): string => {
  if (!amount) return '0'
  return (Number(amount) / 1e18).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })
}

const clearMessages = () => {
  setTimeout(() => {
    successMessage.value = ''
    errorMessage.value = ''
  }, 5000)
}

const showSuccess = (msg: string) => {
  successMessage.value = msg
  errorMessage.value = ''
  clearMessages()
}

const showError = (msg: string) => {
  errorMessage.value = msg
  successMessage.value = ''
  clearMessages()
}

// 获取合约 BNB 余额
const fetchBNBBalance = async () => {
  try {
    const { getProvider } = useWallet()
    const provider = getProvider()
    const mfacAddress = import.meta.env.VITE_MFAC_SYSTEM_CONTRACT_ADDRESS
    const balance = await provider.getBalance(mfacAddress)
    bnbBalance.value = (Number(balance) / 1e18).toLocaleString(undefined, { minimumFractionDigits: 4, maximumFractionDigits: 4 })
  } catch (err) {
    console.error('Failed to fetch BNB balance:', err)
    bnbBalance.value = '0'
  }
}

// Actions
const updateFeePercents = async () => {
  loading.value.feePercents = true
  try {
    const result = await mfacStore.setFeePercents(buyFeeInput.value, sellFeeInput.value)
    if (result) {
      showSuccess(`手续费比例已更新：买入${buyFeeInput.value}% / 卖出${sellFeeInput.value}%`)
    } else {
      showError('更新失败')
    }
  } catch (err: any) {
    showError(err.message || '更新失败')
  } finally {
    loading.value.feePercents = false
  }
}

const updateFeeDistribution = async () => {
  loading.value.feeDistribution = true
  try {
    const result = await mfacStore.setFeeDistribution(
      feeDistribution.value.circulating,
      feeDistribution.value.sbt,
      feeDistribution.value.dao
    )
    if (result) {
      showSuccess('分配比例已更新')
    } else {
      showError('更新失败')
    }
  } catch (err: any) {
    showError(err.message || '更新失败')
  } finally {
    loading.value.feeDistribution = false
  }
}

const setDEXPair = async (isPair: boolean) => {
  if (!dexPairInput.value || !ethers.isAddress(dexPairInput.value)) {
    showError('请输入有效的地址')
    return
  }
  
  loading.value.dexPair = true
  try {
    const result = await mfacStore.setDEXPair(dexPairInput.value, isPair)
    if (result) {
      showSuccess(`DEX Pair 已${isPair ? '添加' : '移除'}`)
      dexPairInput.value = ''
    } else {
      showError('操作失败')
    }
  } catch (err: any) {
    showError(err.message || '操作失败')
  } finally {
    loading.value.dexPair = false
  }
}

const setExcludedFromFee = async (excluded: boolean) => {
  if (!excludedAddressInput.value || !ethers.isAddress(excludedAddressInput.value)) {
    showError('请输入有效的地址')
    return
  }
  
  loading.value.excludedFee = true
  try {
    const result = await mfacStore.setExcludedFromFee(excludedAddressInput.value, excluded)
    if (result) {
      showSuccess(`地址豁免已${excluded ? '添加' : '移除'}`)
      excludedAddressInput.value = ''
    } else {
      showError('操作失败')
    }
  } catch (err: any) {
    showError(err.message || '操作失败')
  } finally {
    loading.value.excludedFee = false
  }
}

const handleWithdrawMFAC = async () => {
  if (!withdrawMFAC.value.to || !ethers.isAddress(withdrawMFAC.value.to)) {
    showError('请输入有效的接收地址')
    return
  }
  if (!withdrawMFAC.value.amount || Number(withdrawMFAC.value.amount) <= 0) {
    showError('请输入有效的数量')
    return
  }
  
  loading.value.withdrawMFAC = true
  try {
    const amount = ethers.parseEther(withdrawMFAC.value.amount)
    const result = await mfacStore.withdrawMFAC(withdrawMFAC.value.to, amount)
    if (result) {
      showSuccess(`成功提取 ${withdrawMFAC.value.amount} MFAC`)
      withdrawMFAC.value = { to: '', amount: '' }
    } else {
      showError('提取失败')
    }
  } catch (err: any) {
    showError(err.message || '提取失败')
  } finally {
    loading.value.withdrawMFAC = false
  }
}

const handleWithdrawBNB = async () => {
  if (!withdrawBNB.value.to || !ethers.isAddress(withdrawBNB.value.to)) {
    showError('请输入有效的接收地址')
    return
  }
  if (!withdrawBNB.value.amount || Number(withdrawBNB.value.amount) <= 0) {
    showError('请输入有效的数量')
    return
  }
  
  loading.value.withdrawBNB = true
  try {
    const amount = ethers.parseEther(withdrawBNB.value.amount)
    const result = await mfacStore.withdrawBNB(withdrawBNB.value.to, amount)
    if (result) {
      showSuccess(`成功提取 ${withdrawBNB.value.amount} BNB`)
      withdrawBNB.value = { to: '', amount: '' }
    } else {
      showError('提取失败')
    }
  } catch (err: any) {
    showError(err.message || '提取失败')
  } finally {
    loading.value.withdrawBNB = false
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
    await fetchBNBBalance()
  }
})
</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
