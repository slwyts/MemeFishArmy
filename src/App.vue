<script setup lang="ts">
import { RouterView } from 'vue-router'
import TheNavbar from './components/TheNavbar.vue' // 1. 导入新的导航栏组件
</script>

<template>
  <div id="app-wrapper">
    <div id="background-overlay"></div>

    <TheNavbar />

    <main class="relative z-10 pt-32 pb-20">
      <RouterView />
    </main>
  </div>
</template>

<style>
body {
  background-color: #0c0a09; /* 一个非常深的底色，防止图片加载慢时穿帮 */
}

#app-wrapper {
  position: relative;
  min-height: 100vh;
  overflow-x: hidden;
}

#background-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 0;

  /* 你的背景图片 */
  background-image: url('/background.png'); /* 确保图片放在 src/assets/ 目录下 */
  background-size: cover;
  background-position: center;

  /* 在背景图上叠加一层渐变，让顶部更暗，突出导航栏 */
  &::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: radial-gradient(ellipse at center, rgba(12, 10, 9, 0.6) 0%, rgba(12, 10, 9, 1) 100%);
  }
}

main {
  /* pt-32 (padding-top: 8rem) 给顶部留出足够空间，防止内容被固定导航栏遮挡 */
}
</style>