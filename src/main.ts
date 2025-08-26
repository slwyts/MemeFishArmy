import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createI18n } from 'vue-i18n'

import App from './App.vue'
import router from './router'

import en from './locales/en.json'
import zh from './locales/zh.json'

import './style.css'

// 1. 创建 i18n 实例
const i18n = createI18n({
  legacy: false, // 必须为 false 才能在 Composition API 中使用
  locale: 'zh', // 默认语言
  fallbackLocale: 'en', // 回退语言
  messages: {
    en,
    zh,
  },
})

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(i18n) // 2. 在 Vue 应用中使用 i18n

app.mount('#app')