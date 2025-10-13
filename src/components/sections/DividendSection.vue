<template>
  <section id="dividend" class="container mx-auto px-4">
    <div class="max-w-5xl mx-auto">
      <!-- 标题 -->
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-white tracking-tight mb-3">
          💰 交易税分红
        </h2>
        <p class="text-lg text-gray-400">持有NFT即可获得代币交易税分红和NFT版税收入</p>
      </div>

      <!-- 未连接钱包 -->
      <div v-if="!isConnected" class="relative group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-orange-500 to-red-600 rounded-2xl blur-lg opacity-40"></div>
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-12 text-center">
          <div class="text-6xl mb-4">🔐</div>
          <h3 class="text-2xl font-bold text-white mb-2">请先连接钱包</h3>
          <p class="text-gray-400">连接钱包后即可查看您的分红</p>
        </div>
      </div>

      <!-- 已连接 -->
      <div v-else class="space-y-6">
        <!-- 统计卡片 -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">代币分红</div>
            <div class="text-3xl font-bold text-orange-400">{{ formatTokenDividend }}</div>
            <div class="text-xs text-gray-500 mt-1">MFAC</div>
          </div>

          <div class="bg-gradient-to-br from-purple-500/20 to-pink-500/20 backdrop-blur-sm rounded-xl border border-purple-500/30 p-4">
            <div class="text-sm text-purple-300 mb-1">💎 NFT版税</div>
            <div class="text-3xl font-bold text-white">{{ formatRoyalty }}</div>
            <div class="text-xs text-purple-200 mt-1">BNB</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">分红池</div>
            <div class="text-3xl font-bold text-purple-400">{{ formatPool }}</div>
            <div class="text-xs text-gray-500 mt-1">MFAC</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">我的NFT</div>
            <div class="text-3xl font-bold text-blue-400">{{ nftCount }}</div>
            <div class="text-xs text-gray-500 mt-1">张</div>
          </div>
        </div>

        <!-- 代币分红领取 -->
        <div class="relative group">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-orange-500 to-red-600 rounded-2xl blur-lg opacity-40 group-hover:opacity-60 transition duration-500"></div>
          
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-xl font-bold text-white mb-1">💎 领取代币分红</h3>
                <p class="text-gray-400 text-sm">您有 {{ formatTokenDividend }} MFAC 待领取</p>
              </div>
              <button
                @click="handleClaimDividend"
                :disabled="!canClaimDividend"
                class="px-8 py-3 font-bold rounded-xl transition-all transform hover:scale-105 active:scale-95
                       bg-gradient-to-r from-orange-500 to-red-600 hover:from-orange-400 hover:to-red-500
                       text-white shadow-lg hover:shadow-orange-500/50
                       disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400 disabled:shadow-none"
              >
                <span v-if="claimingDividend">
                  <i class="fa fa-spinner fa-spin mr-2"></i>
                  领取中...
                </span>
                <span v-else>
                  💰 领取分红
                </span>
              </button>
            </div>
          </div>
        </div>

        <!-- NFT版税领取 -->
        <div class="relative group">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl blur-lg opacity-40 group-hover:opacity-60 transition duration-500"></div>
          
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-xl font-bold text-white mb-1">💎 领取NFT版税</h3>
                <p class="text-gray-400 text-sm">您有 {{ formatRoyalty }} BNB 待领取（来自交易市场版税）</p>
              </div>
              <button
                @click="handleClaimRoyalty"
                :disabled="!canClaimRoyalty"
                class="px-8 py-3 font-bold rounded-xl transition-all transform hover:scale-105 active:scale-95
                       bg-gradient-to-r from-purple-500 to-pink-600 hover:from-purple-400 hover:to-pink-500
                       text-white shadow-lg hover:shadow-purple-500/50
                       disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400 disabled:shadow-none"
              >
                <span v-if="claimingRoyalty">
                  <i class="fa fa-spinner fa-spin mr-2"></i>
                  领取中...
                </span>
                <span v-else>
                  💎 领取版税
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 成功/错误提示 -->
      <div v-if="successMessage" class="mt-4 bg-green-500/10 border border-green-500/30 rounded-xl p-4 backdrop-blur-sm">
        <p class="text-green-400 font-semibold text-center">✅ {{ successMessage }}</p>
      </div>

      <div v-if="errorMessage" class="mt-4 bg-red-500/10 border border-red-500/30 rounded-xl p-4 backdrop-blur-sm">
        <p class="text-red-400 font-semibold text-center">❌ {{ errorMessage }}</p>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useMFACSystemStore } from '@/store/mfacSystem'
import { useWalletStore } from '@/store/wallet'

const mfacStore = useMFACSystemStore()
const walletStore = useWalletStore()

const claimingDividend = ref(false)
const claimingRoyalty = ref(false)
const successMessage = ref('')
const errorMessage = ref('')
const pendingDividend = ref(0n)
const pendingRoyalty = ref(0n)
const nftCount = ref(0)

const isConnected = computed(() => walletStore.isConnected)

const formatTokenDividend = computed(() => {
  const value = Number(pendingDividend.value) / 1e18
  return value.toLocaleString(undefined, { maximumFractionDigits: 2 })
})

const formatRoyalty = computed(() => {
  const value = Number(pendingRoyalty.value) / 1e18
  return value.toLocaleString(undefined, { minimumFractionDigits: 4, maximumFractionDigits: 4 })
})

const formatPool = computed(() => {
  if (!mfacStore.stats) return '0'
  const total = Number(mfacStore.stats.circulatingDividendPool) + Number(mfacStore.stats.sbtDividendPool)
  return (total / 1e18).toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const canClaimDividend = computed(() => {
  return isConnected.value && pendingDividend.value > 0n && !claimingDividend.value
})

const canClaimRoyalty = computed(() => {
  return isConnected.value && pendingRoyalty.value > 0n && !claimingRoyalty.value
})

const handleClaimDividend = async () => {
  errorMessage.value = ''
  successMessage.value = ''
  claimingDividend.value = true

  try {
    const success = await mfacStore.claimDividend()

    if (success) {
      successMessage.value = `🎉 成功领取 ${formatTokenDividend.value} MFAC 分红！`
      pendingDividend.value = 0n
    }
  } catch (err: any) {
    errorMessage.value = err.message || '领取失败，请重试'
  } finally {
    claimingDividend.value = false
  }
}

const handleClaimRoyalty = async () => {
  errorMessage.value = ''
  successMessage.value = ''
  claimingRoyalty.value = true

  try {
    const success = await mfacStore.claimNFTRoyalty()

    if (success) {
      successMessage.value = `🎉 成功领取 ${formatRoyalty.value} BNB 版税！`
      pendingRoyalty.value = 0n
    }
  } catch (err: any) {
    errorMessage.value = err.message || '领取失败，请重试'
  } finally {
    claimingRoyalty.value = false
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
    // 加载用户数据
    if (walletStore.connectedAddress) {
      pendingRoyalty.value = await mfacStore.getPendingNFTRoyalty(walletStore.connectedAddress)
    }
  }
})
</script>
