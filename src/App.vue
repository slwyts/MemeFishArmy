<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
// 导入 Vue 的核心功能：ref, computed, onMounted, onUnmounted
import { ref, computed, onMounted, onUnmounted } from 'vue'
import TheNavbar from './components/TheNavbar.vue'
import TheFooter from './components/TheFooter.vue'

// 获取当前路由实例
const route = useRoute()

// 创建一个计算属性来判断当前路由是否为管理员页面
const isAdminRoute = computed(() => {
  return route.path.startsWith('/admin')
})

// --- 新增代码开始 ---

// 1. 创建一个 ref 来存储垂直滚动距离
const scrollTop = ref(0)

// 2. 定义一个处理滚动事件的函数
const handleScroll = () => {
  // window.scrollY 能获取页面垂直滚动的像素值
  scrollTop.value = window.scrollY
}

// 3. 在组件挂载后，添加全局滚动事件监听
onMounted(() => {
  window.addEventListener('scroll', handleScroll)
})

// 4. 在组件卸载前，移除事件监听，防止内存泄漏
onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

// 5. 创建一个计算属性，根据滚动距离动态生成背景样式
const backgroundStyle = computed(() => {
  // 定义最大模糊值，防止无限增大影响性能
  const maxBlur = 50 // 单位 px
  // 定义一个系数，控制模糊程度随滚动距离变化的速率
  const scrollFactor = 0.02
  
  // 计算当前的模糊值
  let blurValue = scrollTop.value * scrollFactor
  
  // 确保模糊值不超过我们设定的最大值
  blurValue = Math.min(blurValue + 2, maxBlur)
  
  // 返回一个样式对象，用于绑定到模板上
  return {
    filter: `blur(${blurValue}px)`
  }
})

// --- 新增代码结束 ---
</script>

<template>
  <div id="app-wrapper" class="flex flex-col min-h-screen">
    <div id="background-overlay" :style="backgroundStyle"></div>

    <TheNavbar />

    <main class="relative z-10 pt-32 pb-20 flex-grow">
      <RouterView />
    </main>

    <TheFooter v-if="!isAdminRoute" />
  </div>
</template>

<style>
/* 强制显示垂直滚动条，防止页面切换时闪烁 */
html {
  overflow-y: scroll;
}

body {
  background-color: #010101;
}

#app-wrapper {
  position: relative;
  overflow-x: hidden;
}

#background-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: -1;
  background-image: url('@/assets/background.png');
  background-size: cover;
  background-position: center;
  transition: filter 0.2s ease-out;
  will-change: filter;
}

#background-overlay::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(ellipse at center, rgba(12, 10, 9, 0.6) 0%, rgba(12, 10, 9, 1) 100%);
}
</style>