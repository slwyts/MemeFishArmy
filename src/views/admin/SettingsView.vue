<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useContractStore } from '../../store/contract'
import { ArrowPathIcon } from '@heroicons/vue/24/outline'

const { t } = useI18n()
const contractStore = useContractStore()

// ... (此处省略所有 <script> 部分的代码，和之前 AdminView.vue 的 <script> 完全一样) ...
// Whitelist states
const singleAddress = ref('')
const batchAddresses = ref('')

// Settings states
const maxMints = ref(0)
const baseURI = ref('')
const royalty = ref(0)

// UI states
const loadingState = ref<{ [key: string]: boolean }>({})
const resultState = ref<{ [key: string]: string | null }>({})
const isFetchingInitialData = ref(true)

// 当从 Store 获取到数据后，更新本地的 ref
const updateLocalState = () => {
  maxMints.value = contractStore.maxMintsPerUser
  baseURI.value = contractStore.baseURI || ''
  royalty.value = contractStore.royaltyBps || 0
}

// 在组件挂载时首次获取合约数据
onMounted(async () => {
  isFetchingInitialData.value = true
  try {
    if(!contractStore.ownerAddress) {
        await contractStore.fetchContractData()
    }
    updateLocalState()
  } catch (error) {
    console.error("Failed to fetch initial admin data:", error)
  } finally {
    isFetchingInitialData.value = false
  }
})

// 监听 store 的变化，保持同步 (例如，在一次成功的更新后)
watch(() => [contractStore.maxMintsPerUser, contractStore.baseURI, contractStore.royaltyBps], () => {
  updateLocalState()
})

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
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
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
        </div>
      </div>

      <div class="bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700 space-y-6">
        <h2 class="text-2xl font-bold text-white">{{ t('admin.settings_title') }}</h2>
        <div v-if="isFetchingInitialData" class="text-center text-gray-400">
          <ArrowPathIcon class="animate-spin h-8 w-8 mx-auto"/>
          <p>正在从合约加载当前设置...</p>
        </div>
        <div v-else class="space-y-6">
            <div class="setting-item">
              <label class="font-semibold text-gray-300">{{ t('admin.settings_max_mints') }}</label>
              <p class="text-sm text-cyan-400">当前值: {{ contractStore.maxMintsPerUser }}</p>
              <div class="flex items-center space-x-4">
                  <input v-model.number="maxMints" type="number" class="setting-input flex-grow">
                  <button @click="handleAdminTask('maxMints', () => contractStore.setMaxMints(maxMints))" class="btn-admin" :disabled="loadingState['maxMints'] || maxMints === contractStore.maxMintsPerUser">
                      <ArrowPathIcon v-if="loadingState['maxMints']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.update_button') }}
                  </button>
              </div>
            </div>

            <div class="setting-item">
              <label class="font-semibold text-gray-300">{{ t('admin.settings_base_uri') }}</label>
              <p class="text-sm text-cyan-400 break-all">当前值: {{ contractStore.baseURI || '未设置' }}</p>
              <div class="flex items-center space-x-4">
                  <input v-model="baseURI" type="text" class="setting-input flex-grow" placeholder="输入新的 URI (例如: ipfs://CID/)">
                  <button @click="handleAdminTask('baseURI', () => contractStore.setBaseURI(baseURI))" class="btn-admin" :disabled="loadingState['baseURI'] || !baseURI || baseURI === contractStore.baseURI">
                      <ArrowPathIcon v-if="loadingState['baseURI']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.update_button') }}
                  </button>
              </div>
            </div>

            <div class="setting-item">
              <label class="font-semibold text-gray-300">{{ t('admin.settings_royalty') }}</label>
              <p class="text-sm text-cyan-400">当前值: {{ contractStore.royaltyBps }} 基点 ({{ (contractStore.royaltyBps || 0) / 100 }}%)</p>
              <div class="flex items-center space-x-4">
                  <input v-model.number="royalty" type="number" class="setting-input flex-grow" placeholder="输入基点 (例如 500 表示 5%)">
                  <button @click="handleAdminTask('royalty', () => contractStore.setRoyalty(royalty))" class="btn-admin" :disabled="loadingState['royalty'] || royalty === contractStore.royaltyBps">
                      <ArrowPathIcon v-if="loadingState['royalty']" class="animate-spin h-5 w-5 mr-2"/> {{ t('admin.update_button') }}
                  </button>
              </div>
            </div>
        </div>
      </div>
    </div>
</template>
<style scoped>
/* 样式保持不变 */
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