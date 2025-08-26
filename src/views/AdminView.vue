<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useContractStore } from '../store/contract'
import { ArrowPathIcon, CheckCircleIcon, ExclamationCircleIcon } from '@heroicons/vue/24/outline'

const { t } = useI18n()
const contractStore = useContractStore()

// Whitelist states
const singleAddress = ref('')
const batchAddresses = ref('')

// Settings states
const maxMints = ref(contractStore.maxMintsPerUser)
const baseURI = ref('') // Needs a getter in contract to pre-fill
const royalty = ref(0) // Needs a getter in contract to pre-fill

// UI states
const loadingState = ref<{ [key: string]: boolean }>({})
const resultState = ref<{ [key: string]: string | null }>({})

const handleAdminTask = async (key: string, task: Function) => {
  loadingState.value[key] = true
  resultState.value[key] = null
  try {
    await task()
    resultState.value[key] = 'success'
  } catch (error) {
    console.error(`Task ${key} failed:`, error)
    resultState.value[key] = 'error'
  } finally {
    loadingState.value[key] = false
    setTimeout(() => resultState.value[key] = null, 5000)
  }
}

const handleWhitelistUpdate = (isBatch: boolean, add: boolean) => {
  const key = `${isBatch ? 'batch' : 'single'}_${add ? 'add' : 'remove'}`
  const addresses = (isBatch ? batchAddresses.value.split('\n') : [singleAddress.value]).filter(a => a.trim() !== '')
  if (addresses.length === 0) return
  const statuses = Array(addresses.length).fill(add)
  handleAdminTask(key, () => contractStore.updateWhitelist(addresses, statuses))
}
</script>

<template>
  <div class="container mx-auto px-4 py-10">
    <h1 class="text-4xl font-bold text-white">{{ t('admin.title') }}</h1>
    <p class="mt-2 text-lg text-gray-400">{{ t('admin.subtitle') }}</p>

    <div class="mt-12 grid grid-cols-1 lg:grid-cols-2 gap-8">
      <div class="bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700 space-y-8">
        <h2 class="text-2xl font-bold text-white">{{ t('admin.whitelist_title') }}</h2>
        <div>
          <input v-model="singleAddress" type="text" :placeholder="t('admin.whitelist_single_placeholder')" class="w-full bg-slate-800 border border-slate-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none">
          <div class="flex space-x-4 mt-4">
            <button @click="handleWhitelistUpdate(false, true)" class="btn-admin flex-1" :disabled="loadingState['single_add']">
              <ArrowPathIcon v-if="loadingState['single_add']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.whitelist_add') }}
            </button>
            <button @click="handleWhitelistUpdate(false, false)" class="btn-admin btn-danger flex-1" :disabled="loadingState['single_remove']">
              <ArrowPathIcon v-if="loadingState['single_remove']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.whitelist_remove') }}
            </button>
          </div>
          <div v-if="resultState['single_add'] || resultState['single_remove']" class="feedback-box" :class="resultState['single_add'] === 'success' || resultState['single_remove'] === 'success' ? 'text-green-400' : 'text-red-400'">
            {{ resultState['single_add'] || resultState['single_remove'] === 'success' ? t('admin.success_msg') : t('admin.error_msg') }}
          </div>
        </div>
        <div>
          <textarea v-model="batchAddresses" rows="5" :placeholder="t('admin.whitelist_batch_placeholder')" class="w-full bg-slate-800 border border-slate-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"></textarea>
          <div class="flex space-x-4 mt-4">
            <button @click="handleWhitelistUpdate(true, true)" class="btn-admin flex-1" :disabled="loadingState['batch_add']">
              <ArrowPathIcon v-if="loadingState['batch_add']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.whitelist_batch_add') }}
            </button>
            <button @click="handleWhitelistUpdate(true, false)" class="btn-admin btn-danger flex-1" :disabled="loadingState['batch_remove']">
              <ArrowPathIcon v-if="loadingState['batch_remove']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.whitelist_batch_remove') }}
            </button>
          </div>
          <div v-if="resultState['batch_add'] || resultState['batch_remove']" class="feedback-box" :class="resultState['batch_add'] === 'success' || resultState['batch_remove'] === 'success' ? 'text-green-400' : 'text-red-400'">
            {{ resultState['batch_add'] || resultState['batch_remove'] === 'success' ? t('admin.success_msg') : t('admin.error_msg') }}
          </div>
        </div>
      </div>

      <div class="bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700 space-y-6">
        <h2 class="text-2xl font-bold text-white">{{ t('admin.settings_title') }}</h2>
        <div class="setting-item">
          <label>{{ t('admin.settings_max_mints') }}</label>
          <input v-model.number="maxMints" type="number" class="setting-input">
          <button @click="handleAdminTask('maxMints', () => contractStore.setMaxMints(maxMints))" class="btn-admin" :disabled="loadingState['maxMints']">
            <ArrowPathIcon v-if="loadingState['maxMints']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.update_button') }}
          </button>
        </div>
         <div class="setting-item">
          <label>{{ t('admin.settings_base_uri') }}</label>
          <input v-model="baseURI" type="text" class="setting-input">
          <button @click="handleAdminTask('baseURI', () => contractStore.setBaseURI(baseURI))" class="btn-admin" :disabled="loadingState['baseURI']">
             <ArrowPathIcon v-if="loadingState['baseURI']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.update_button') }}
          </button>
        </div>
         <div class="setting-item">
          <label>{{ t('admin.settings_royalty') }}</label>
          <input v-model.number="royalty" type="number" class="setting-input">
          <button @click="handleAdminTask('royalty', () => contractStore.setRoyalty(royalty))" class="btn-admin" :disabled="loadingState['royalty']">
             <ArrowPathIcon v-if="loadingState['royalty']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.update_button') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import "tailwindcss";
.btn-admin {
  @apply inline-flex items-center justify-center px-4 py-2 bg-cyan-600 text-white font-semibold rounded-md hover:bg-cyan-700 transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed;
}
.btn-danger {
  @apply bg-red-600 hover:bg-red-700;
}
.feedback-box {
  @apply mt-4 text-sm font-semibold;
}
.setting-item {
  @apply space-y-2;
}
.setting-input {
  @apply w-full bg-slate-800 border border-slate-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none;
}
</style>