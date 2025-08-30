<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { Transition } from 'vue'

const { locale } = useI18n()
const isDropdownOpen = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)

function selectLanguage(lang: 'en' | 'zh') {
  locale.value = lang
  isDropdownOpen.value = false
}

// Click outside to close the dropdown
const handleClickOutside = (event: MouseEvent) => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    isDropdownOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="relative" ref="dropdownRef">
    <button @click="isDropdownOpen = !isDropdownOpen" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300 flex items-center space-x-1.5 px-2 py-1 rounded-md hover:bg-white/10">
      <svg xmlns="http://www.w.3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
      </svg>
      <span class="text-sm font-semibold">{{ locale === 'en' ? 'English' : '中文' }}</span>
      <svg class="w-4 h-4 transition-transform duration-200" :class="{'rotate-180': isDropdownOpen}" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
    </button>
    
    <Transition
      enter-active-class="transition ease-out duration-100"
      enter-from-class="transform opacity-0 scale-95"
      enter-to-class="transform opacity-100 scale-100"
      leave-active-class="transition ease-in duration-75"
      leave-from-class="transform opacity-100 scale-100"
      leave-to-class="transform opacity-0 scale-95"
    >
      <div v-if="isDropdownOpen" class="absolute top-full right-0 mt-2 w-36 bg-black/30 backdrop-blur-lg border border-white/10 rounded-lg shadow-xl py-1 z-20 overflow-hidden">
        <a @click.prevent="selectLanguage('en')" href="#" class="block px-4 py-2 text-sm text-gray-200 hover:bg-white/5 hover:text-cyan-400 transition-colors duration-200">English</a>
        <a @click.prevent="selectLanguage('zh')" href="#" class="block px-4 py-2 text-sm text-gray-200 hover:bg-white/5 hover:text-cyan-400 transition-colors duration-200">中文</a>
      </div>
    </Transition>
  </div>
</template>