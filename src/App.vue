<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { ref, computed, onMounted, onUnmounted } from 'vue'
import TheNavbar from './components/TheNavbar.vue'
import TheFooter from './components/TheFooter.vue'

const route = useRoute()

const isAdminRoute = computed(() => {
  return route.path.startsWith('/admin')
})

const scrollTop = ref(0)

const handleScroll = () => {
  scrollTop.value = window.scrollY
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

const backgroundStyle = computed(() => {
  const maxBlur = 50
  const scrollFactor = 0.02
  let blurValue = scrollTop.value * scrollFactor
  blurValue = Math.min(blurValue + 2, maxBlur)
  return {
    filter: `blur(${blurValue}px)`
  }
})

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