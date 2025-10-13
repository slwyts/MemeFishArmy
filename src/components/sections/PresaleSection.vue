<template>
  <section id="presale" class="container mx-auto px-4">
    <div class="max-w-5xl mx-auto">
      <!-- 标题 -->
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-white tracking-tight mb-3">
          🔥 NFT 预售
        </h2>
        <p class="text-lg text-gray-400">购买 SBT NFT，获取空投和推荐奖励资格</p>
      </div>

      <!-- 主卡片 -->
      <div class="relative group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-green-500 to-emerald-600 rounded-2xl blur-lg opacity-40 group-hover:opacity-60 transition duration-500"></div>
        
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 shadow-2xl overflow-hidden">
          <!-- 统计信息 -->
          <div class="grid grid-cols-3 gap-6 p-8 border-b border-slate-700">
            <div class="text-center">
              <div class="text-sm text-gray-400 mb-1">NFT 价格</div>
              <div class="text-3xl font-bold text-green-400">{{ formatPrice }}</div>
              <div class="text-xs text-gray-500 mt-1">BNB</div>
            </div>
            
            <div class="text-center">
              <div class="text-sm text-gray-400 mb-1">已售出</div>
              <div class="text-3xl font-bold text-white">{{ nftsSold }}</div>
              <div class="text-xs text-gray-500 mt-1">/ 4500</div>
            </div>
            
            <div class="text-center">
              <div class="text-sm text-gray-400 mb-1">预售状态</div>
              <div class="flex items-center justify-center">
                <span v-if="presaleActive" class="px-4 py-1 bg-green-500/20 text-green-400 rounded-full text-sm font-bold border border-green-500/30">
                  ✅ 进行中
                </span>
                <span v-else class="px-4 py-1 bg-gray-500/20 text-gray-400 rounded-full text-sm font-bold border border-gray-500/30">
                  ⏸️ 已暂停
                </span>
              </div>
            </div>
          </div>

          <!-- 购买表单 -->
          <div class="p-8">
            <div class="max-w-md mx-auto space-y-4">
              <!-- 推荐人地址 -->
              <div>
                <label class="block text-sm font-semibold text-gray-300 mb-2">
                  推荐人地址（可选）
                </label>
                <input
                  v-model="referrerAddress"
                  type="text"
                  placeholder="0x..."
                  class="w-full bg-slate-800/50 border border-slate-600 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:ring-2 focus:ring-green-500 focus:outline-none transition-all"
                />
                <p class="text-xs text-gray-500 mt-1">填写推荐人地址，对方可获得 Super Builder 奖励</p>
              </div>

              <!-- 购买按钮 -->
              <button
                @click="handlePurchase"
                :disabled="!canPurchase"
                class="w-full py-4 font-bold text-lg rounded-xl transition-all transform hover:scale-105 active:scale-95
                       bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-400 hover:to-emerald-500
                       text-white shadow-lg hover:shadow-green-500/50
                       disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400 disabled:shadow-none"
              >
                <span v-if="purchasing">
                  <i class="fa fa-spinner fa-spin mr-2"></i>
                  购买中...
                </span>
                <span v-else-if="!isConnected">
                  连接钱包购买
                </span>
                <span v-else-if="!presaleActive">
                  预售未开始
                </span>
                <span v-else>
                  购买 NFT ({{ formatPrice }} BNB)
                </span>
              </button>
            </div>
          </div>

          <!-- NFT 权益说明 -->
          <div class="bg-gradient-to-r from-slate-800/50 to-slate-900/50 p-6 border-t border-slate-700">
            <h3 class="text-lg font-bold text-white mb-4 text-center">🎁 NFT 权益</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div class="text-center">
                <div class="text-2xl mb-1">🪂</div>
                <div class="text-xs text-gray-400">100天空投</div>
                <div class="text-sm font-bold text-green-400">1000 MFAC/天</div>
              </div>
              
              <div class="text-center">
                <div class="text-2xl mb-1">⛏️</div>
                <div class="text-xs text-gray-400">质押挖矿</div>
                <div class="text-sm font-bold text-blue-400">时间加权</div>
              </div>
              
              <div class="text-center">
                <div class="text-2xl mb-1">💰</div>
                <div class="text-xs text-gray-400">交易税分红</div>
                <div class="text-sm font-bold text-orange-400">MFAC</div>
              </div>
              
              <div class="text-center">
                <div class="text-2xl mb-1">🗳️</div>
                <div class="text-xs text-gray-400">DAO 投票</div>
                <div class="text-sm font-bold text-purple-400">治理权</div>
              </div>
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
import { useRoute } from 'vue-router'
import { useMFACSystemStore } from '@/store/mfacSystem'
import { useWalletStore } from '@/store/wallet'
import { ethers } from 'ethers'

const route = useRoute()
const mfacStore = useMFACSystemStore()
const walletStore = useWalletStore()

const referrerAddress = ref('')
const purchasing = ref(false)
const successMessage = ref('')
const errorMessage = ref('')

const isConnected = computed(() => walletStore.isConnected)
const presaleActive = computed(() => mfacStore.presaleActive)
const nftsSold = computed(() => Number(mfacStore.stats?.nftsSold || 0))

const formatPrice = computed(() => {
  if (!mfacStore.nftPrice) return '1.0'
  return (Number(mfacStore.nftPrice) / 1e18).toFixed(1)
})

const canPurchase = computed(() => {
  return isConnected.value && presaleActive.value && !purchasing.value
})

const handlePurchase = async () => {
  if (!isConnected.value) {
    // 触发钱包连接
    return
  }

  errorMessage.value = ''
  successMessage.value = ''
  purchasing.value = true

  try {
    const referrer = referrerAddress.value.trim() || ethers.ZeroAddress
    const success = await mfacStore.purchaseNFT(referrer)

    if (success) {
      successMessage.value = '🎉 成功购买 NFT！已自动添加到白名单'
      referrerAddress.value = ''
    }
  } catch (err: any) {
    errorMessage.value = err.message || '购买失败，请重试'
  } finally {
    purchasing.value = false
  }
}

// 从 URL 读取推荐码参数
const loadReferrerFromUrl = () => {
  const refParam = route.query.ref
  if (refParam && typeof refParam === 'string' && refParam.startsWith('0x')) {
    referrerAddress.value = refParam
    console.log('Loaded referrer from URL:', refParam)
  }
}

onMounted(async () => {
  // 读取 URL 中的推荐码
  loadReferrerFromUrl()
  
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
  }
})
</script>
