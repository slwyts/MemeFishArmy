<script setup lang="ts">
import AdminSideNav from '../components/admin/AdminSideNav.vue'
import { RouterView } from 'vue-router'
import { useI18n } from 'vue-i18n'

// 将 useI18n 的调用移入 <script setup> 内部
const { t } = useI18n()
</script>

<template>
  <div class="container mx-auto px-4 py-10">
    <div class="mb-10">
      <h1 class="text-4xl font-bold text-white mb-2">{{ t('admin.title') }}</h1>
      <p class="text-lg text-gray-400">{{ t('admin.subtitle') }}</p>
    </div>

    <div class="flex flex-col md:flex-row">
      <AdminSideNav />
      <main class="flex-grow md:p-8 pb-24 md:pb-8">
        <RouterView />
      </main>
    </div>
  </div>
</template>