<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useWalletStore } from '../store/wallet'
import { useWallet } from '../composables/useWallet'

const { t } = useI18n()
const walletStore = useWalletStore()
const { connect, disconnect } = useWallet()

const handleClick = () => {
  if (walletStore.isConnected) {
    disconnect()
  } else {
    connect()
  }
}
</script>

<template>
  <button
    @click="handleClick"
    class="px-4 py-2 font-semibold text-white bg-blue-600 rounded-lg shadow-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-75 transition duration-200 ease-in-out"
    :disabled="walletStore.isConnecting"
  >
    <span v-if="walletStore.isConnecting">{{ t('wallet.connecting') }}</span>
    <span v-else-if="walletStore.isConnected">{{ walletStore.shortAddress }}</span>
    <span v-else>{{ t('wallet.connect') }}</span>
  </button>
</template>