<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import ConnectWalletButton from './ConnectWalletButton.vue'
import LanguageSwitcher from './LanguageSwitcher.vue'

const { t } = useI18n()
</script>

<template>
  <header class="fixed top-0 left-0 w-full z-50">
    <nav class="container mx-auto px-6 py-4 flex justify-between items-center bg-black/20 backdrop-blur-md border-b border-white/10">
      <div class="flex items-center space-x-4">
        <span class="text-2xl font-bold text-white tracking-wider">
          MemeFish Army
        </span>
      </div>

      <div class="hidden md:flex items-center space-x-8 font-semibold text-gray-300">
        <a href="#home" class="hover:text-cyan-400 transition-colors duration-300">{{ t('nav.home') }}</a>
        <a href="#features" class="hover:text-cyan-400 transition-colors duration-300">{{ t('nav.features') }}</a>
        <a href="#roadmap" class="hover:text-cyan-400 transition-colors duration-300">{{ t('nav.roadmap') }}</a>
        <a href="#faq" class="hover:text-cyan-400 transition-colors duration-300">{{ t('nav.faq') }}</a>
      </div>

      <div class="flex items-center space-x-6">
        <LanguageSwitcher />
        <div class="w-px h-6 bg-white/20"></div>
        <ConnectWalletButton />
      </div>
    </nav>
  </header>
</template>