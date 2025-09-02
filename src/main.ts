import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createI18n } from 'vue-i18n'

import App from './App.vue'
import router from './router'

import en from './locales/en.json'
import zh from './locales/zh.json'

import '@/style.css'

import iconUrl from '@/assets/logo.webp'

const favicon = document.querySelector<HTMLLinkElement>('link#favicon')
if (favicon) {
  favicon.href = iconUrl
}
const i18n = createI18n({
  legacy: false,
  locale: 'zh',
  fallbackLocale: 'en',
  messages: {
    en,
    zh,
  },
})

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(i18n)
app.mount('#app')