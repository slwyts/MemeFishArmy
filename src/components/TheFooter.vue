<template>
  <footer class="bg-slate-900 opacity-50 border-t border-slate-700 mt-32">
    <div class="container mx-auto px-6 py-12">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-8 text-center md:text-left">
        <div class="col-span-1">
          <h2 class="text-xl font-bold text-white tracking-wider">MemeFish Army</h2>
          <p class="mt-2 text-gray-400">{{ t('footer.about') }}</p>
        </div>
        
        <div class="col-span-1">
          <h3 class="font-semibold text-gray-200 uppercase tracking-wider">{{ t('footer.links_title') }}</h3>
          <div class="mt-4 space-y-2">
            <a v-for="link in navLinks" :key="link.name" :href="link.href" class="block text-gray-400 hover:text-amber-400 transition-colors">
              {{ t(link.name) }}
            </a>
          </div>
        </div>

        <div class="col-span-1">
          <h3 class="font-semibold text-gray-200 uppercase tracking-wider">{{ t('footer.social_title') }}</h3>
          <div class="mt-4 flex justify-center md:justify-start space-x-6">
            <a v-for="social in socialLinks" :key="social.name" :href="social.href" target="_blank" rel="noopener noreferrer" class="text-gray-400 hover:text-amber-400 transition-colors">
              <component :is="social.icon" class="h-6 w-6" />
            </a>
          </div>
        </div>
      </div>
      <div class="mt-12 border-t border-slate-800 pt-8 text-center text-gray-500">
        <p>&copy; {{ new Date().getFullYear() }} MemeFish Army. {{ t('footer.rights') }}</p>
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref } from 'vue'
import { BeakerIcon } from '@heroicons/vue/24/solid' // Placeholder for actual social icons

const { t } = useI18n()

const navLinks = ref([
  { name: 'nav.home', href: '#home' },
  { name: 'nav.features', href: '#features' },
  { name: 'nav.roadmap', href: '#roadmap' },
  { name: 'nav.faq', href: '#faq' },
])

// You would typically use SVG icons for these
const socialLinks = ref([
  { name: 'Twitter', href: '#', icon: BeakerIcon },
  { name: 'Discord', href: '#', icon: BeakerIcon },
  { name: 'Telegram', href: '#', icon: BeakerIcon },
])
</script>