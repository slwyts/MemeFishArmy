<template>
  <section id="builder" class="container mx-auto px-4">
    <div class="max-w-5xl mx-auto">
      <!-- 标题 -->
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-white tracking-tight mb-3">
          🌟 Super Builder
        </h2>
        <p class="text-lg text-gray-400">推荐系统，达成条件获得额外空投奖励</p>
      </div>

      <!-- 统计卡片 -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">直推销售</div>
          <div class="text-3xl font-bold text-green-400">{{ directSales }}</div>
          <div class="text-xs text-gray-500 mt-1">/ 5 张</div>
        </div>

        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">社区销售</div>
          <div class="text-3xl font-bold text-blue-400">{{ communitySales }}</div>
          <div class="text-xs text-gray-500 mt-1">/ 30 张</div>
        </div>

        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">待领奖励</div>
          <div class="text-3xl font-bold text-yellow-400">{{ formatReward }}</div>
          <div class="text-xs text-gray-500 mt-1">MFAC</div>
        </div>

        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">资格状态</div>
          <div class="text-xl font-bold" :class="isQualified ? 'text-green-400' : 'text-gray-400'">
            {{ isQualified ? '✅ 已达成' : '⏳ 未达成' }}
          </div>
        </div>
      </div>

      <!-- 条件卡片 -->
      <div class="relative group mb-6">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-yellow-500 to-orange-600 rounded-2xl blur-lg opacity-40"></div>
        
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-8">
          <h3 class="text-2xl font-bold text-white mb-6 text-center">成为 Super Builder 的条件</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- 条件1 -->
            <div class="bg-slate-800/50 rounded-xl p-6 border" :class="directSales >= 5 ? 'border-green-500/50' : 'border-slate-700'">
              <div class="flex items-center justify-between mb-3">
                <h4 class="text-lg font-bold text-white">📊 条件一</h4>
                <span v-if="directSales >= 5" class="text-green-400">✅</span>
                <span v-else class="text-gray-500">⏳</span>
              </div>
              <p class="text-gray-300 mb-2">直接推荐销售 ≥ 5 张 NFT</p>
              <div class="w-full bg-slate-700 rounded-full h-2 mt-3">
                <div class="bg-gradient-to-r from-green-500 to-emerald-600 h-2 rounded-full transition-all"
                     :style="`width: ${Math.min((directSales / 5) * 100, 100)}%`">
                </div>
              </div>
              <p class="text-xs text-gray-400 mt-2">当前: {{ directSales }} / 5</p>
            </div>

            <!-- 条件2 -->
            <div class="bg-slate-800/50 rounded-xl p-6 border" :class="communitySales >= 30 ? 'border-green-500/50' : 'border-slate-700'">
              <div class="flex items-center justify-between mb-3">
                <h4 class="text-lg font-bold text-white">🌐 条件二</h4>
                <span v-if="communitySales >= 30" class="text-green-400">✅</span>
                <span v-else class="text-gray-500">⏳</span>
              </div>
              <p class="text-gray-300 mb-2">社区累计销售 ≥ 30 张 NFT</p>
              <div class="w-full bg-slate-700 rounded-full h-2 mt-3">
                <div class="bg-gradient-to-r from-blue-500 to-cyan-600 h-2 rounded-full transition-all"
                     :style="`width: ${Math.min((communitySales / 30) * 100, 100)}%`">
                </div>
              </div>
              <p class="text-xs text-gray-400 mt-2">当前: {{ communitySales }} / 30</p>
            </div>
          </div>

          <!-- 领取按钮 -->
          <div v-if="isQualified" class="mt-6 text-center">
            <button
              @click="handleClaimReward"
              :disabled="pendingReward === 0n || claiming"
              class="px-10 py-3 font-bold text-lg rounded-xl transition-all transform hover:scale-105 active:scale-95
                     bg-gradient-to-r from-yellow-500 to-orange-600 hover:from-yellow-400 hover:to-orange-500
                     text-white shadow-lg hover:shadow-yellow-500/50
                     disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400 disabled:shadow-none"
            >
              <span v-if="claiming">
                <i class="fa fa-spinner fa-spin mr-2"></i>
                领取中...
              </span>
              <span v-else>
                🌟 领取 Builder 奖励
              </span>
            </button>
          </div>
        </div>
      </div>

      <!-- 推荐链接 -->
      <div class="relative group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-cyan-500 to-blue-600 rounded-2xl blur-lg opacity-30"></div>
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-6">
          <h3 class="text-lg font-bold text-white mb-3 text-center">📋 您的推荐链接</h3>
          <div class="flex items-center gap-3">
            <input
              :value="referralLink"
              readonly
              class="flex-1 bg-slate-800/50 border border-slate-600 rounded-lg px-4 py-3 text-white font-mono text-sm"
            />
            <button
              @click="copyLink"
              class="px-6 py-3 bg-cyan-600 hover:bg-cyan-500 text-white font-bold rounded-lg transition-all"
            >
              📋 复制
            </button>
          </div>
        </div>
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
const directSales = ref(0)
const communitySales = ref(0)
const pendingReward = ref(0n)
const isQualified = ref(false)

const formatReward = computed(() => {
  const value = Number(pendingReward.value) / 1e18
  return value.toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const referralLink = computed(() => {
  if (!walletStore.connectedAddress) return ''
  return `${window.location.origin}/presale?ref=${walletStore.connectedAddress}`
})

const copyLink = () => {
  navigator.clipboard.writeText(referralLink.value)
  alert('推荐链接已复制!')
}

const handleClaimReward = async () => {
  claiming.value = true
  try {
    await mfacStore.claimBuilderReward()
  } catch (err) {
    console.error(err)
  } finally {
    claiming.value = false
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    // 加载推荐数据
    if (walletStore.connectedAddress) {
      await mfacStore.fetchUserReferralInfo()
      const info = mfacStore.userReferralInfo
      if (info) {
        directSales.value = Number(info.directSales)
        communitySales.value = Number(info.communitySales)
        isQualified.value = info.qualified
        pendingReward.value = info.claimed
      }
    }
  }
})
</script>
