<template>
  <section id="staking" class="container mx-auto px-4">
    <div class="max-w-5xl mx-auto">
      <!-- 标题 -->
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-white tracking-tight mb-3">
          ⛏️ NFT 质押
        </h2>
        <p class="text-lg text-gray-400">质押流通NFT，获取时间加权挖矿奖励</p>
      </div>

      <!-- 未连接钱包 -->
      <div v-if="!isConnected" class="relative group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-blue-500 to-cyan-600 rounded-2xl blur-lg opacity-40"></div>
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-12 text-center">
          <div class="text-6xl mb-4">🔐</div>
          <h3 class="text-2xl font-bold text-white mb-2">请先连接钱包</h3>
          <p class="text-gray-400">连接钱包后即可质押您的 NFT</p>
        </div>
      </div>

      <!-- 已连接 -->
      <div v-else>
        <!-- 统计卡片 -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">我的质押</div>
            <div class="text-3xl font-bold text-blue-400">{{ stakingCount }}</div>
            <div class="text-xs text-gray-500 mt-1">张 NFT</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">待领奖励</div>
            <div class="text-3xl font-bold text-green-400">{{ formatRewards }}</div>
            <div class="text-xs text-gray-500 mt-1">MFAC</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">质押池余额</div>
            <div class="text-3xl font-bold text-purple-400">{{ formatPoolBalance }}</div>
            <div class="text-xs text-gray-500 mt-1">MFAC</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">基础奖励</div>
            <div class="text-3xl font-bold text-orange-400">500</div>
            <div class="text-xs text-gray-500 mt-1">MFAC/天</div>
          </div>
        </div>

        <!-- 质押说明 -->
        <div class="relative group mb-6">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-blue-500 to-cyan-600 rounded-2xl blur-lg opacity-30"></div>
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-6">
            <h3 class="text-lg font-bold text-white mb-3">⏰ 时间加权机制</h3>
            <div class="grid grid-cols-3 gap-4 text-center">
              <div>
                <div class="text-sm text-gray-400 mb-1">初始奖励</div>
                <div class="text-xl font-bold text-white">500 MFAC/天</div>
              </div>
              <div>
                <div class="text-sm text-gray-400 mb-1">30天加权</div>
                <div class="text-xl font-bold text-blue-400">×1.1</div>
              </div>
              <div>
                <div class="text-sm text-gray-400 mb-1">60天加权</div>
                <div class="text-xl font-bold text-cyan-400">×1.21</div>
              </div>
            </div>
            <p class="text-xs text-gray-500 mt-3 text-center">
              每30天权重增加10%，取消质押后重新计算
            </p>
          </div>
        </div>

        <!-- 快速操作 -->
        <div v-if="stakingCount > 0" class="relative group">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-green-500 to-emerald-600 rounded-2xl blur-lg opacity-40 group-hover:opacity-60 transition duration-500"></div>
          
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-xl font-bold text-white mb-1">领取质押奖励</h3>
                <p class="text-gray-400 text-sm">您有 {{ formatRewards }} MFAC 待领取</p>
              </div>
              <button
                @click="handleClaimRewards"
                :disabled="!canClaimRewards"
                class="px-8 py-3 font-bold rounded-xl transition-all transform hover:scale-105 active:scale-95
                       bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-400 hover:to-emerald-500
                       text-white shadow-lg hover:shadow-green-500/50
                       disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400 disabled:shadow-none"
              >
                <span v-if="claiming">
                  <i class="fa fa-spinner fa-spin mr-2"></i>
                  领取中...
                </span>
                <span v-else>
                  💰 领取奖励
                </span>
              </button>
            </div>
          </div>
        </div>

        <!-- 无质押提示 -->
        <div v-else class="relative group">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-yellow-500 to-orange-600 rounded-2xl blur-lg opacity-30"></div>
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-8 text-center">
            <div class="text-5xl mb-3">😢</div>
            <h3 class="text-xl font-bold text-white mb-2">暂无质押的 NFT</h3>
            <p class="text-gray-400">购买流通NFT后即可开始质押挖矿</p>
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

const claiming = ref(false)
const successMessage = ref('')
const errorMessage = ref('')
const stakingCount = ref(0)
const pendingRewards = ref(0n)

const isConnected = computed(() => walletStore.isConnected)

const formatRewards = computed(() => {
  const value = Number(pendingRewards.value) / 1e18
  return value.toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const formatPoolBalance = computed(() => {
  if (!mfacStore.stats) return '0'
  const value = Number(mfacStore.stats.stakingPoolRemaining) / 1e18
  return value.toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const canClaimRewards = computed(() => {
  return isConnected.value && pendingRewards.value > 0n && !claiming.value
})

const handleClaimRewards = async () => {
  errorMessage.value = ''
  successMessage.value = ''
  claiming.value = true

  try {
    const success = await mfacStore.claimStakingReward()

    if (success) {
      successMessage.value = `🎉 成功领取 ${formatRewards.value} MFAC 质押奖励！`
      pendingRewards.value = 0n
    }
  } catch (err: any) {
    errorMessage.value = err.message || '领取失败，请重试'
  } finally {
    claiming.value = false
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
    // 加载用户质押数据
    stakingCount.value = 0 // 待实现
    pendingRewards.value = 0n
  }
})
</script>
