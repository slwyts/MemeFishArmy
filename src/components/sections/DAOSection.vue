<template>
  <section id="dao" class="container mx-auto px-4">
    <div class="max-w-5xl mx-auto">
      <!-- 标题 -->
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-white tracking-tight mb-3">
          🏛️ DAO 治理
        </h2>
        <p class="text-lg text-gray-400">社区自治，守护者提案，选民投票</p>
      </div>

      <!-- 统计卡片 -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">DAO 国库</div>
          <div class="text-3xl font-bold text-yellow-400">{{ formatTreasury }}</div>
          <div class="text-xs text-gray-500 mt-1">BNB</div>
        </div>

        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">活跃提案</div>
          <div class="text-3xl font-bold text-purple-400">{{ activeProposals }}</div>
          <div class="text-xs text-gray-500 mt-1">个</div>
        </div>

        <div class="bg-slate-900/80 backdrop-blur-sm rounded-xl border border-slate-700 p-4">
          <div class="text-sm text-gray-400 mb-1">我的身份</div>
          <div class="text-xl font-bold text-cyan-400">{{ userRole }}</div>
          <div class="text-xs text-gray-500 mt-1">{{ userRoleDesc }}</div>
        </div>
      </div>

      <!-- 主卡片 -->
      <div class="relative group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-purple-500 to-indigo-600 rounded-2xl blur-lg opacity-40"></div>
        
        <div class="relative bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700 p-8">
          <h3 class="text-2xl font-bold text-white mb-6 text-center">DAO 治理机制</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- 守护者 -->
            <div class="bg-slate-800/50 rounded-xl p-6 border border-purple-500/30">
              <h4 class="text-lg font-bold text-purple-400 mb-3">🛡️ 守护者</h4>
              <ul class="space-y-2 text-sm text-gray-300">
                <li>✓ 质押排名前50名</li>
                <li>✓ 发起投资提案权</li>
                <li>✓ 国库≥100 BNB时可用</li>
              </ul>
            </div>

            <!-- 选民 -->
            <div class="bg-slate-800/50 rounded-xl p-6 border border-cyan-500/30">
              <h4 class="text-lg font-bold text-cyan-400 mb-3">🗳️ 选民</h4>
              <ul class="space-y-2 text-sm text-gray-300">
                <li>✓ 所有NFT持有者</li>
                <li>✓ 链上投票决策权</li>
                <li>✓ 参与社区治理</li>
              </ul>
            </div>
          </div>

          <div class="mt-6 bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-4">
            <p class="text-sm text-yellow-400 text-center">
              📋 提案通过后，DAO国库资金用于投资优质项目。盈利50%分发给社区，50%销毁MFAC实现通缩
            </p>
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

const activeProposals = ref(0)
const isGuardian = ref(false)
const isVoter = ref(false)

const formatTreasury = computed(() => {
  if (!mfacStore.stats) return '0'
  const value = Number(mfacStore.stats.daoTreasury) / 1e18
  return value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
})

const userRole = computed(() => {
  if (!walletStore.isConnected) return '未连接'
  if (isGuardian.value) return '🛡️ 守护者'
  if (isVoter.value) return '🗳️ 选民'
  return '👤 游客'
})

const userRoleDesc = computed(() => {
  if (!walletStore.isConnected) return '请连接钱包'
  if (isGuardian.value) return '可发起提案'
  if (isVoter.value) return '可投票'
  return '持有NFT可参与'
})

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
  }
})
</script>
