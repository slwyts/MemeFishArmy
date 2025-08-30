<script setup lang="ts">
import { onMounted, watch, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useContractStore } from '../store/contract'
import { useWalletStore } from '../store/wallet'
import { useWallet } from '../composables/useWallet'

import { CheckCircleIcon, XCircleIcon, ShieldCheckIcon, CpuChipIcon, EyeIcon, PaintBrushIcon, CubeTransparentIcon } from '@heroicons/vue/24/solid'
import { BeakerIcon, BookOpenIcon, MapIcon, UserGroupIcon, CodeBracketIcon, PencilSquareIcon } from '@heroicons/vue/24/outline'

const { t } = useI18n()
const contractStore = useContractStore()
const walletStore = useWalletStore()
const { connect } = useWallet()

onMounted(() => {
  contractStore.fetchContractData()
  if (walletStore.isConnected) {
    contractStore.fetchUserData()
  }
})

watch(() => walletStore.isConnected, (newVal) => {
  if (newVal) {
    contractStore.fetchUserData()
  }
})

const mintButtonText = computed(() => {
  if (!walletStore.isConnected) return t('home.mint_card.button_connect')
  if (contractStore.isMinting) return t('home.mint_card.button_minting')
  if (!contractStore.isWhitelisted) return t('home.mint_card.button_not_whitelisted')
  if (contractStore.userMintCount >= contractStore.maxMintsPerUser && contractStore.maxMintsPerUser > 0) return t('home.mint_card.button_limit_reached')
  return t('home.mint_card.button_mint_now')
})

const isMintDisabled = computed(() => {
  if (!walletStore.isConnected) return false
  return contractStore.isMinting ||
         !contractStore.isWhitelisted ||
         (contractStore.userMintCount >= contractStore.maxMintsPerUser && contractStore.maxMintsPerUser > 0)
})

const handleMintAction = () => {
  if (!walletStore.isConnected) {
    connect()
  } else {
    contractStore.handleMint()
  }
}

const txUrl = computed(() => contractStore.mintTxHash ? `https://bscscan.com/tx/${contractStore.mintTxHash}` : '#')
</script>

<template>
  <div class="space-y-36">
    <section id="home" class="container mx-auto px-4 text-center">
      <h1 class="text-5xl font-extrabold tracking-tight text-white sm:text-6xl md:text-7xl">
        <span class="block">{{ t('home.title1') }}</span>
        <span class="block text-amber-400 text-3xl sm:text-4xl md:text-5xl mt-2">{{ t('home.title2') }}</span>
      </h1>
      <p class="mt-6 max-w-3xl mx-auto text-lg text-gray-300 sm:text-xl">{{ t('home.subtitle') }}</p>

      <div class="relative mt-12 max-w-md mx-auto group">
        <div class="absolute -inset-0.5 bg-gradient-to-r from-amber-500 to-yellow-600 rounded-2xl blur-lg opacity-60 group-hover:opacity-80 transition duration-500 animate-tilt"></div>
        <div class="relative bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700 shadow-2xl">
            <div class="flex items-center justify-center space-x-3 mb-6">
                <ShieldCheckIcon class="h-8 w-8 text-amber-400" />
                <h2 class="text-3xl font-bold text-white">{{ t('home.mint_card.title') }}</h2>
            </div>

            <div v-if="walletStore.isConnected" class="space-y-4 mb-8 text-left">
                <div class="flex items-center justify-between bg-slate-800/50 p-3 rounded-lg border border-slate-700">
                    <span class="font-semibold text-gray-300">{{ t('home.mint_card.status_whitelist') }}</span>
                    <div class="flex items-center space-x-2">
                        <span :class="contractStore.isWhitelisted ? 'text-green-400' : 'text-red-400'" class="font-bold">{{ contractStore.isWhitelisted ? t('home.mint_card.status_whitelisted') : t('home.mint_card.status_not_whitelisted') }}</span>
                        <CheckCircleIcon v-if="contractStore.isWhitelisted" class="h-6 w-6 text-green-400" />
                        <XCircleIcon v-else class="h-6 w-6 text-red-400" />
                    </div>
                </div>
                <div class="flex items-center justify-between bg-slate-800/50 p-3 rounded-lg border border-slate-700">
                    <span class="font-semibold text-gray-300">{{ t('home.mint_card.status_minted') }}</span>
                    <span class="font-mono text-xl font-bold text-white">{{ contractStore.userMintCount }} / {{ contractStore.maxMintsPerUser }}</span>
                </div>
            </div>
            
            <p v-else class="text-gray-400 mb-8 h-[104px] flex items-center justify-center">{{ t('home.mint_card.status_connect_prompt') }}</p>

            <button @click="handleMintAction" :disabled="isMintDisabled" class="w-full py-4 font-bold text-lg text-slate-900 rounded-lg transition duration-300 ease-in-out transform hover:scale-105 bg-gradient-to-r from-amber-400 to-yellow-500 hover:from-amber-300 hover:to-yellow-400 focus:outline-none focus:ring-4 focus:ring-amber-500/50 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:text-gray-400">
                {{ mintButtonText }}
            </button>
            
            <div class="mt-4 text-sm min-h-[40px]">
                <div v-if="contractStore.isMinting && contractStore.mintTxHash" class="text-amber-300 animate-pulse">
                    {{ t('home.mint_card.feedback_sending') }}<br>
                    <a :href="txUrl" target="_blank" class="hover:underline">{{ t('home.mint_card.view_on_explorer') }}</a>
                </div>
                <div v-else-if="!contractStore.isMinting && contractStore.mintTxHash" class="text-green-400">
                    {{ t('home.mint_card.feedback_success') }}<br>
                    <a :href="txUrl" target="_blank" class="hover:underline">{{ t('home.mint_card.view_on_explorer') }}</a>
                </div>
                <div v-if="contractStore.mintError" class="text-red-400">
                    {{ t('home.mint_card.feedback_error') }}: {{ contractStore.mintError }}
                </div>
            </div>
        </div>
      </div>
    </section>

    <section id="lore" class="container mx-auto px-4 text-center">
        <h2 class="text-4xl font-bold text-white tracking-tight">{{ t('lore.title') }}</h2>
        <div class="mt-8 max-w-3xl mx-auto space-y-4 text-lg text-gray-300 text-left leading-relaxed">
            <p>{{ t('lore.p1') }}</p>
            <p>{{ t('lore.p2') }}</p>
            <p class="text-amber-400 font-semibold">{{ t('lore.p3') }}</p>
        </div>
    </section>

    <section id="features" class="container mx-auto px-4 text-center">
      <h2 class="text-4xl font-bold text-white tracking-tight">{{ t('features.title') }}</h2>
      <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-400">{{ t('features.subtitle') }}</p>
      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-8 mt-12">
        <div class="feature-card">
          <CpuChipIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
          <h3 class="text-2xl font-bold text-white">{{ t('features.item1_title') }}</h3>
          <p class="mt-2 text-gray-400">{{ t('features.item1_desc') }}</p>
        </div>
        <div class="feature-card">
          <EyeIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
          <h3 class="text-2xl font-bold text-white">{{ t('features.item2_title') }}</h3>
          <p class="mt-2 text-gray-400">{{ t('features.item2_desc') }}</p>
        </div>
        <div class="feature-card">
          <PaintBrushIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
          <h3 class="text-2xl font-bold text-white">{{ t('features.item3_title') }}</h3>
          <p class="mt-2 text-gray-400">{{ t('features.item3_desc') }}</p>
        </div>
        <div class="feature-card">
          <CubeTransparentIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
          <h3 class="text-2xl font-bold text-white">{{ t('features.item4_title') }}</h3>
          <p class="mt-2 text-gray-400">{{ t('features.item4_desc') }}</p>
        </div>
      </div>
    </section>

    <section id="team" class="container mx-auto px-4 text-center">
        <h2 class="text-4xl font-bold text-white tracking-tight">{{ t('team.title') }}</h2>
        <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-400">{{ t('team.subtitle') }}</p>
        <div class="grid md:grid-cols-3 gap-8 mt-12 max-w-4xl mx-auto">
            <div class="team-member-card">
                <CodeBracketIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
                <h3 class="text-2xl font-bold text-white">{{ t('team.member1_name') }}</h3>
                <p class="text-amber-400 font-semibold">{{ t('team.member1_role') }}</p>
                <p class="mt-2 text-gray-400">{{ t('team.member1_desc') }}</p>
            </div>
            <div class="team-member-card">
                <PencilSquareIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
                <h3 class="text-2xl font-bold text-white">{{ t('team.member2_name') }}</h3>
                <p class="text-amber-400 font-semibold">{{ t('team.member2_role') }}</p>
                <p class="mt-2 text-gray-400">{{ t('team.member2_desc') }}</p>
            </div>
            <div class="team-member-card">
                <UserGroupIcon class="h-12 w-12 text-amber-400 mx-auto mb-4" />
                <h3 class="text-2xl font-bold text-white">{{ t('team.member3_name') }}</h3>
                <p class="text-amber-400 font-semibold">{{ t('team.member3_role') }}</p>
                <p class="mt-2 text-gray-400">{{ t('team.member3_desc') }}</p>
            </div>
        </div>
    </section>

    <section id="faq" class="container mx-auto px-4 max-w-3xl">
      <h2 class="text-4xl font-bold text-white text-center tracking-tight">{{ t('faq.title') }}</h2>
      <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-400 text-center">{{ t('faq.subtitle') }}</p>
      <div class="mt-12 space-y-4">
        <div class="faq-item">
          <h3 class="font-semibold text-lg text-amber-400">{{ t('faq.q1') }}</h3>
          <p class="mt-2 text-gray-300">{{ t('faq.a1') }}</p>
        </div>
        <div class="faq-item">
          <h3 class="font-semibold text-lg text-amber-400">{{ t('faq.q2') }}</h3>
          <p class="mt-2 text-gray-300">{{ t('faq.a2') }}</p>
        </div>
        <div class="faq-item">
          <h3 class="font-semibold text-lg text-amber-400">{{ t('faq.q3') }}</h3>
          <p class="mt-2 text-gray-300">{{ t('faq.a3') }}</p>
        </div>
        <div class="faq-item">
          <h3 class="font-semibold text-lg text-amber-400">{{ t('faq.q4') }}</h3>
          <p class="mt-2 text-gray-300">{{ t('faq.a4') }}</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
@import "tailwindcss";

.feature-card, .team-member-card, .faq-item {
  @apply bg-slate-900 opacity-50 p-8 rounded-xl border border-slate-700 transition duration-300 hover:border-amber-400/50 hover:shadow-2xl hover:shadow-amber-500/10;
}
</style>