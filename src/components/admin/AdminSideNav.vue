<script setup lang="ts">
import { Cog6ToothIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'
import { RouterLink } from 'vue-router'

const navItems = [
  { name: '合约设置', to: '/admin/settings', icon: Cog6ToothIcon },
  { name: '数据查询', to: '/admin/queries', icon: MagnifyingGlassIcon },
]
</script>

<template>
  <nav class="hidden md:block w-64 flex-shrink-0 p-4 border-r border-slate-700/50">
    <h2 class="text-xl font-bold text-white mb-8">管理员菜单</h2>
    <ul class="space-y-2">
      <li v-for="item in navItems" :key="item.name">
        <RouterLink :to="item.to" v-slot="{ isActive }">
          <span
            :class="[
              'flex items-center space-x-3 px-4 py-3 rounded-lg transition-all duration-300 ease-in-out',
              isActive
                ? 'bg-cyan-500/10 text-cyan-400 shadow-lg shadow-cyan-500/5 ring-1 ring-cyan-500/20'
                : 'text-gray-400 hover:bg-slate-800/60 hover:text-white'
            ]"
          >
            <component :is="item.icon" class="h-6 w-6" />
            <span class="font-semibold">{{ item.name }}</span>
          </span>
        </RouterLink>
      </li>
    </ul>
  </nav>

  <nav class="md:hidden fixed bottom-4 left-1/2 -translate-x-1/2 w-[90%] max-w-sm z-50">
    <ul class="flex justify-around items-center bg-slate-900/70 backdrop-blur-xl border border-white/10 rounded-full shadow-2xl shadow-black/40 p-2">
      <li v-for="item in navItems" :key="item.name" class="flex-1">
        <RouterLink :to="item.to" v-slot="{ isActive }">
          <span
            :class="[
              'flex flex-col items-center justify-center text-center py-2 px-3 rounded-full transition-all duration-300 ease-in-out',
               isActive ? 'bg-cyan-500/20 text-cyan-300' : 'text-gray-400'
            ]"
          >
            <component :is="item.icon" class="h-6 w-6" />
            <span class="text-xs font-medium mt-1">{{ item.name }}</span>
          </span>
        </RouterLink>
      </li>
    </ul>
  </nav>
</template>