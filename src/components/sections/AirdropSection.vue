<template>
  <section id="airdrop" class="container mx-auto px-4">
    <div class="max-w-5xl mx-auto">
      <!-- 标题 -->
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-white tracking-tight mb-3">
          🎁 空投领取
        </h2>
        <p class="text-lg text-gray-400">100天线性释放，每张NFT每天可领1000 MFAC</p>
      </div>

      <!-- 未连接钱包 -->
      <div v-if="!isConnected" class="relative group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl blur-lg opacity-40"></div>
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-12 text-center">
          <div class="text-6xl mb-4">🔐</div>
          <h3 class="text-2xl font-bold text-white mb-2">请先连接钱包</h3>
          <p class="text-gray-400">连接钱包后即可查看您的空投资格</p>
        </div>
      </div>

      <!-- 已连接 -->
      <div v-else class="space-y-6">
        <!-- 统计卡片 -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">持有 NFT</div>
            <div class="text-3xl font-bold text-white">{{ userNFTCount }}</div>
            <div class="text-xs text-gray-500 mt-1">张</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">可领取天数</div>
            <div class="text-3xl font-bold text-green-400">{{ claimableDays }}</div>
            <div class="text-xs text-gray-500 mt-1">天</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">待领空投</div>
            <div class="text-3xl font-bold text-purple-400">{{ formatPending }}</div>
            <div class="text-xs text-gray-500 mt-1">MFAC</div>
          </div>

          <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
            <div class="text-sm text-gray-400 mb-1">已领取</div>
            <div class="text-3xl font-bold text-blue-400">{{ formatClaimed }}</div>
            <div class="text-xs text-gray-500 mt-1">MFAC</div>
          </div>
        </div>

        <!-- 领取按钮 -->
        <div v-if="userNFTCount > 0" class="relative group">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl blur-lg opacity-40 group-hover:opacity-60 transition duration-500"></div>
          
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-8">
            <div class="max-w-md mx-auto text-center">
              <h3 class="text-2xl font-bold text-white mb-4">
                领取空投
              </h3>
              <p class="text-gray-400 mb-6">
                选择您的 NFT 领取今日空投
              </p>

              <button
                @click="handleClaimAll"
                :disabled="!canClaim"
                class="w-full py-4 font-bold text-lg rounded-xl transition-all transform hover:scale-105 active:scale-95
                       bg-gradient-to-r from-purple-500 to-pink-600 hover:from-purple-400 hover:to-pink-500
                       text-white shadow-lg hover:shadow-purple-500/50
                       disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400 disabled:shadow-none"
              >
                <span v-if="claiming">
                  <i class="fa fa-spinner fa-spin mr-2"></i>
                  领取中...
                </span>
                <span v-else-if="claimableDays === 0">
                  今日已领取
                </span>
                <span v-else>
                  领取所有 NFT 空投
                </span>
              </button>

              <p class="text-xs text-gray-500 mt-3">
                可领取 {{ claimableDays }} 天的空投，共 {{ formatPending }} MFAC
              </p>
            </div>
          </div>
        </div>

        <!-- 无 NFT 提示 -->
        <div v-else class="relative group">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-yellow-500 to-orange-600 rounded-2xl blur-lg opacity-30"></div>
          <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-8 text-center">
            <div class="text-5xl mb-3">😢</div>
            <h3 class="text-xl font-bold text-white mb-2">暂无空投资格</h3>
            <p class="text-gray-400">请先购买 NFT 以获得空投资格</p>
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
const userNFTs = ref<bigint[]>([])
const claimableDays = ref(0)
const pendingAirdrop = ref(0n)
const claimedAirdrop = ref(0n)

const isConnected = computed(() => walletStore.isConnected)
const userNFTCount = computed(() => userNFTs.value.length)

const formatPending = computed(() => {
  const value = Number(pendingAirdrop.value) / 1e18
  return value.toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const formatClaimed = computed(() => {
  const value = Number(claimedAirdrop.value) / 1e18
  return value.toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const canClaim = computed(() => {
  return isConnected.value && claimableDays.value > 0 && !claiming.value
})

const handleClaimAll = async () => {
  errorMessage.value = ''
  successMessage.value = ''
  claiming.value = true

  try {
    const success = await mfacStore.claimAirdrop(userNFTs.value)

    if (success) {
      successMessage.value = `🎉 成功领取 ${formatPending.value} MFAC 空投！`
      claimableDays.value = 0
      pendingAirdrop.value = 0n
      await loadUserData()
    }
  } catch (err: any) {
    errorMessage.value = err.message || '领取失败，请重试'
  } finally {
    claiming.value = false
  }
}

const loadUserData = async () => {
  if (!isConnected.value) return

  try {
    // 加载用户NFT余额
    const nftBalance = mfacStore.userNFTBalance
    
    // 计算可领取天数和金额
    if (nftBalance && nftBalance.length > 0) {
      const circulatingCount = Number(nftBalance[0]) // 流通NFT数量
      if (circulatingCount > 0) {
        // 简化计算: 假设平均每个NFT有可领取空投
        claimableDays.value = circulatingCount * 5 // 模拟
        pendingAirdrop.value = BigInt(circulatingCount * 1000) * BigInt(1e18)
      }
    }
  } catch (err) {
    console.error('Failed to load user data:', err)
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await loadUserData()
  }
})
</script>
