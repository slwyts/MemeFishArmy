<script setup lang="ts">
import { RouterView } from 'vue-router'
import TheNavbar from './components/TheNavbar.vue'
import TheFooter from './components/TheFooter.vue'
</script>

<template>
  <div id="app-wrapper" class="flex flex-col min-h-screen">
    <div id="background-overlay"></div>

    <TheNavbar />

    <main class="relative z-10 pt-32 pb-20 flex-grow">
      <RouterView />
    </main>

    <TheFooter /> </div>
</template>

<style>
body {
  background-color: #0c0a09;
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
  background-image: url('/background.png');
  background-size: cover;
  background-position: center;
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