<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { locale } = useI18n()

function switchLanguage() {
  locale.value = locale.value === 'en' ? 'zh' : 'en'
}
</script>

<template>
  <button @click="switchLanguage" class="font-semibold text-gray-300 hover:text-cyan-400 transition-colors duration-300 flex items-center space-x-2">
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9V3m-9 9h18" />
    </svg>
    <span v-if="locale === 'en'">中文</span>
    <span v-else>English</span>
  </button>
</template>