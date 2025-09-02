<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWalletStore } from '../store/wallet'
import { useContractStore } from '../store/contract'
import ConnectWalletButton from './ConnectWalletButton.vue'
import LanguageSwitcher from './LanguageSwitcher.vue'
import { RouterLink } from 'vue-router'

const { t } = useI18n()
const walletStore = useWalletStore()
const contractStore = useContractStore()
const isMobileMenuOpen = ref(false)

// 计算属性，判断当前连接的用户是否是管理员
const isAdmin = computed(() => {
  return (
    walletStore.isConnected &&
    contractStore.ownerAddress &&
    walletStore.connectedAddress?.toLowerCase() === contractStore.ownerAddress.toLowerCase()
  )
})

function closeMobileMenu() {
  isMobileMenuOpen.value = false
}
</script>

<template>
  <header class="fixed top-0 left-0 w-full z-50">
    <nav class="container mx-auto px-6 py-4 flex justify-between items-center bg-black/30 backdrop-blur-lg border-b border-white/10">
      <div class="flex items-center">
        <img src="@/assets/logo.webp" alt="MemeFish Army Logo" class="h-10 w-10 mr-3">
        <span class="text-xl font-bold text-white tracking-wider">
          MemeFishArmy
        </span>
      </div>

      <div class="hidden md:flex items-center space-x-8">
        <a href="/#home" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300">{{ t('nav.home') }}</a>
        <a href="/#features" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300">{{ t('nav.features') }}</a>
        <!-- <a href="/#roadmap" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300">{{ t('nav.roadmap') }}</a> -->
        <a href="/#faq" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300">{{ t('nav.faq') }}</a>
        <RouterLink v-if="isAdmin" to="/admin" class="font-semibold text-amber-400 hover:text-amber-300 transition-colors duration-300">
          仪表盘
        </RouterLink>
      </div>

      <div class="hidden md:flex items-center space-x-4">
        <LanguageSwitcher />
        <div class="w-px h-6 bg-white/20"></div>
        <ConnectWalletButton />
      </div>
      
      <div class="md:hidden flex items-center space-x-4">
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
        <a href="/#features" @click="closeMobileMenu" class="font-semibold text-gray-200 hover:text-cyan-400 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">{{ t('nav.features') }}</a>
        <!-- <a href="/#roadmap" @click="closeMobileMenu" class="font-semibold text-gray-200 hover:text-cyan-400 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">{{ t('nav.roadmap') }}</a> -->
        <a href="/#faq" @click="closeMobileMenu" class="font-semibold text-gray-200 hover:text-cyan-400 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">{{ t('nav.faq') }}</a>
        <RouterLink v-if="isAdmin" to="/admin" @click="closeMobileMenu" class="font-semibold text-amber-400 hover:text-amber-300 text-center py-2 rounded-md hover:bg-white/5 transition-colors duration-300">
          仪表盘
        </RouterLink>
        
        <div class="flex items-center justify-center pt-6 mt-4 border-t border-white/10">
          <ConnectWalletButton />
        </div>
      </div>
    </div>
  </header>
</template>