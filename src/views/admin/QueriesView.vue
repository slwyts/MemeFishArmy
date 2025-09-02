<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useContractStore } from '../../store/contract'
import { ArrowPathIcon, ChevronLeftIcon, ChevronRightIcon, ChevronDownIcon } from '@heroicons/vue/24/outline'

const { t } = useI18n()
const contractStore = useContractStore()

// Whitelist Pagination State
const whitelistCurrentPage = ref(1)
const whitelistItemsPerPage = ref(10)

// Holders UI State
const expandedHolders = ref<Record<string, boolean>>({})

onMounted(() => {
  // Fetch data only if it hasn't been fetched before
  if (!contractStore.hasScanned) {
    contractStore.fetchAllQueryData()
  }
})

// Whitelist computed properties
const totalWhitelistPages = computed(() => {
  return Math.ceil(contractStore.whitelist.length / whitelistItemsPerPage.value)
})

const paginatedWhitelist = computed(() => {
  const start = (whitelistCurrentPage.value - 1) * whitelistItemsPerPage.value
  const end = start + whitelistItemsPerPage.value
  return contractStore.whitelist.slice(start, end)
})

const setWhitelistPage = (page: number) => {
  if (page > 0 && page <= totalWhitelistPages.value) {
    whitelistCurrentPage.value = page
  }
}

// Holders methods
const toggleHolderTokens = (holderAddress: string) => {
  expandedHolders.value[holderAddress] = !expandedHolders.value[holderAddress]
}
</script>

<template>
  <div v-if="contractStore.isLoading" class="flex flex-col items-center justify-center text-center text-gray-400 p-8">
    <ArrowPathIcon class="animate-spin h-12 w-12 mx-auto mb-4 text-cyan-500"/>
    <p class="text-lg font-semibold">{{ t('admin.loading') }}</p>
  </div>
  
  <div v-else class="space-y-12">
    <div class="bg-slate-900/80 backdrop-blur-lg p-6 rounded-2xl border border-slate-700 shadow-2xl shadow-black/20">
      <h3 class="text-xl font-bold text-white mb-1">{{ t('admin.whitelist_scan_title') }}</h3>
      <p class="text-sm text-gray-400 mb-6">{{ t('admin.whitelist_scan_desc') }}</p>

      <div class="result-box bg-slate-800/50 border border-slate-700 rounded-lg overflow-hidden">
        <div v-if="paginatedWhitelist.length > 0">
          <div v-for="address in paginatedWhitelist" :key="address" class="font-mono text-sm text-gray-300 break-all p-3 border-b border-slate-700/50 last:border-b-0">
            {{ address }}
          </div>
        </div>
        <div v-else class="text-center p-8 text-gray-500">
          No whitelisted addresses found.
        </div>
      </div>
      
      <div v-if="totalWhitelistPages > 1" class="flex items-center justify-between mt-4 text-sm text-gray-400">
        <span class="font-semibold">{{ t('admin.total_items', { total: contractStore.whitelist.length }) }}</span>
        <div class="flex items-center space-x-2">
          <button @click="setWhitelistPage(whitelistCurrentPage - 1)" :disabled="whitelistCurrentPage === 1" class="inline-flex items-center space-x-1 px-3 py-1.5 bg-slate-700/50 rounded-md hover:bg-slate-600/50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
            <ChevronLeftIcon class="h-4 w-4" />
            <span>{{ t('admin.pagination_prev') }}</span>
          </button>
          <span class="px-2 font-mono">{{ t('admin.page_of', { currentPage: whitelistCurrentPage, totalPages: totalWhitelistPages }) }}</span>
          <button @click="setWhitelistPage(whitelistCurrentPage + 1)" :disabled="whitelistCurrentPage === totalWhitelistPages" class="inline-flex items-center space-x-1 px-3 py-1.5 bg-slate-700/50 rounded-md hover:bg-slate-600/50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
            <span>{{ t('admin.pagination_next') }}</span>
            <ChevronRightIcon class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <div class="bg-slate-900/80 backdrop-blur-lg p-6 rounded-2xl border border-slate-700 shadow-2xl shadow-black/20">
       <h3 class="text-xl font-bold text-white mb-1">{{ t('admin.holders_scan_title') }}</h3>
       <p class="text-sm text-gray-400 mb-6">{{ t('admin.holders_scan_desc') }}</p>

      <div class="bg-slate-800/50 border border-slate-700 rounded-lg overflow-hidden">
        <div v-if="Object.keys(contractStore.holders).length > 0">
          <div v-for="(tokens, holder) in contractStore.holders" :key="holder" class="border-b border-slate-700/50 last:border-b-0">
            <div class="flex items-center justify-between p-3 cursor-pointer hover:bg-slate-800/40 transition-colors" @click="toggleHolderTokens(holder)">
              <p class="font-mono text-sm text-cyan-400 break-all">{{ holder }}</p>
              <div class="flex items-center space-x-2">
                  <span class="text-xs font-semibold bg-slate-700 text-slate-300 px-2 py-0.5 rounded-full">{{ tokens.length }} Tokens</span>
                  <ChevronDownIcon class="h-5 w-5 text-gray-400 transition-transform duration-300" :class="{'rotate-180': expandedHolders[holder]}" />
              </div>
            </div>
            <div v-if="expandedHolders[holder]" class="bg-slate-900/50 p-4">
              <p class="text-xs text-gray-400 mb-2">Token IDs:</p>
              <div class="flex flex-wrap gap-2">
                <span v-for="tokenId in tokens" :key="tokenId" class="font-mono text-xs bg-cyan-900/50 text-cyan-300 px-2 py-1 rounded">
                  #{{ tokenId }}
                </span>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="text-center p-8 text-gray-500">
          No NFT holders found.
        </div>
      </div>
    </div>
  </div>
</template>