<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWalletStore } from '../store/wallet'
import ConnectWalletButton from './ConnectWalletButton.vue'
import LanguageSwitcher from './LanguageSwitcher.vue'
import { RouterLink } from 'vue-router'
import { ethers } from 'ethers'

const { t } = useI18n()
const walletStore = useWalletStore()
const isMobileMenuOpen = ref(false)
const mfacSystemOwner = ref<string>('')

// 从环境变量获取管理员地址和合约地址
const adminAddress = import.meta.env.VITE_ADMIN_ADDRESS?.toLowerCase()
const mfacSystemAddress = import.meta.env.VITE_MFAC_SYSTEM_CONTRACT_ADDRESS

const isAdmin = computed(() => {
  if (!walletStore.isConnected || !walletStore.connectedAddress) {
    return false
  }

  const connectedAddr = walletStore.connectedAddress.toLowerCase()

  // 优先检查环境变量配置的管理员地址（开发模式）
  if (adminAddress && connectedAddr === adminAddress) {
    return true
  }

  // 检查是否是 MFACSystem 合约的 owner（生产模式）
  if (mfacSystemOwner.value && connectedAddr === mfacSystemOwner.value.toLowerCase()) {
    return true
  }

  return false
})

// 获取 MFACSystem 合约的 owner
async function fetchMFACSystemOwner() {
  if (!mfacSystemAddress) return
  
  try {
    const provider = new ethers.BrowserProvider(window.ethereum)
    const contract = new ethers.Contract(
      mfacSystemAddress,
      ['function owner() view returns (address)'],
      provider
    )
    mfacSystemOwner.value = await contract.owner()
  } catch (error) {
    console.error('Failed to fetch MFACSystem owner:', error)
  }
}

onMounted(() => {
  fetchMFACSystemOwner()
  
  // 监听钱包连接变化
  walletStore.$subscribe(() => {
    if (walletStore.isConnected) {
      fetchMFACSystemOwner()
    }
  })
})

function closeMobileMenu() {
  isMobileMenuOpen.value = false
}
</script>

<template>
  <header class="fixed top-0 left-0 w-full z-50">
    <nav class="container mx-auto px-6 py-4 flex justify-between items-center bg-black/30 backdrop-blur-lg border-b border-white/10">
      <div class="flex items-center min-w-0">
        <img src="@/assets/logo.webp" alt="MemeFish Army Logo" class="h-10 w-10 mr-3 flex-shrink-0">
        <span class="font-bold text-white tracking-wider text-base sm:text-lg md:text-xl">
          MemeFishArmy
        </span>
      </div>

      <div class="hidden md:flex items-center space-x-5">
        <a href="/#home" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300">{{ t('nav.home') }}</a>
        <a href="/#presale" class="font-semibold text-green-400 hover:text-green-300 transition-colors duration-300">🔥 预售</a>
        <a href="/#airdrop" class="font-semibold text-purple-400 hover:text-purple-300 transition-colors duration-300">🎁 空投</a>
        <a href="/#staking" class="font-semibold text-blue-400 hover:text-blue-300 transition-colors duration-300">⛏️ 质押</a>
        <a href="/#dividend" class="font-semibold text-orange-400 hover:text-orange-300 transition-colors duration-300">💰 分红</a>
        <a href="/#dao" class="font-semibold text-purple-400 hover:text-purple-300 transition-colors duration-300">🏛️ DAO</a>
        <a href="/#builder" class="font-semibold text-yellow-400 hover:text-yellow-300 transition-colors duration-300">🌟 推荐</a>
        <a href="/#features" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300">{{ t('nav.features') }}</a>
        <RouterLink v-if="isAdmin" to="/admin" class="font-semibold text-amber-400 hover:text-amber-300 transition-colors duration-300">
          ⚙️ 管理
        </RouterLink>
      </div>

      <div class="hidden md:flex items-center space-x-4">
        <LanguageSwitcher />
        <div class="w-px h-6 bg-white/20"></div>
        <ConnectWalletButton />
      </div>
      
      <div class="md:hidden flex items-center space-x-2">
        <LanguageSwitcher />
        <button @click="isMobileMenuOpen = !isMobileMenuOpen" class="text-white focus:outline-none">
          <svg v-if="!isMobileMenuOpen" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7"></path></svg>
          <svg v-else class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
        </button>
      </div>
    </nav>

    <div v-if="isMobileMenuOpen" class="md:hidden bg-black/30 backdrop-blur-lg border-b border-white/10 shadow-xl">
      <div class="container mx-auto px-6 py-6 flex flex-col space-y-4">
        <a href="/#home" @click="closeMobileMenu" class="font-semibold text-gray-200 hover:text-cyan-400 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">{{ t('nav.home') }}</a>
        <a href="/#presale" @click="closeMobileMenu" class="font-semibold text-green-400 hover:text-green-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">🔥 预售</a>
        <a href="/#airdrop" @click="closeMobileMenu" class="font-semibold text-purple-400 hover:text-purple-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">🎁 空投</a>
        <a href="/#staking" @click="closeMobileMenu" class="font-semibold text-blue-400 hover:text-blue-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">⛏️ 质押</a>
        <a href="/#dividend" @click="closeMobileMenu" class="font-semibold text-orange-400 hover:text-orange-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">💰 分红</a>
        <a href="/#dao" @click="closeMobileMenu" class="font-semibold text-purple-400 hover:text-purple-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">🏛️ DAO</a>
        <a href="/#builder" @click="closeMobileMenu" class="font-semibold text-yellow-400 hover:text-yellow-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">🌟 推荐</a>
        <a href="/#features" @click="closeMobileMenu" class="font-semibold text-gray-200 hover:text-cyan-400 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">{{ t('nav.features') }}</a>
        <RouterLink v-if="isAdmin" to="/admin" @click="closeMobileMenu" class="font-semibold text-amber-400 hover:text-amber-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">
          ⚙️ 管理
        </RouterLink>
        
        <div class="flex items-center justify-center pt-6 mt-4 border-t border-white/10">
          <ConnectWalletButton />
        </div>
      </div>
    </div>
  </header>
</template>