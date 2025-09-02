<script setup lang="ts">
import { ref } from 'vue'

// 生成完整的图片数组
const allImages = Array.from({ length: 30 }, (_, i) => {
  return new URL(`../assets/nfts/${i + 1}.png`, import.meta.url).href
})

// 将图片数组分成两半，用于两行展示
const halfwayIndex = Math.ceil(allImages.length / 2)
const row1Images = ref(allImages.slice(0, halfwayIndex))
const row2Images = ref(allImages.slice(halfwayIndex))
</script>

<template>
  <div class="nft-gallery-container">
    <div class="scroller" data-direction="right">
      <div class="scroller-inner">
        <div v-for="image in row1Images" :key="image" class="image-wrapper">
          <img :src="image" alt="NFT Image" class="nft-image" loading="lazy" />
        </div>
        <div v-for="image in row1Images" :key="image + '-clone'" class="image-wrapper" aria-hidden="true">
          <img :src="image" alt="NFT Image" class="nft-image" loading="lazy" />
        </div>
      </div>
    </div>
    
    <div class="scroller" data-direction="left">
      <div class="scroller-inner">
        <div v-for="image in row2Images" :key="image" class="image-wrapper">
          <img :src="image" alt="NFT Image" class="nft-image" loading="lazy" />
        </div>
        <div v-for="image in row2Images" :key="image + '-clone'" class="image-wrapper" aria-hidden="true">
          <img :src="image" alt="NFT Image" class="nft-image" loading="lazy" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.nft-gallery-container {
  width: 100%;
  max-width: 1200px;
  margin: 4rem auto;
  overflow: hidden;
  position: relative;
  -webkit-mask-image: linear-gradient(
    to right,
    transparent,
    black 15%,
    black 85%,
    transparent
  );
  mask-image: linear-gradient(
    to right,
    transparent,
    black 15%,
    black 85%,
    transparent
  );
}

.scroller {
  width: max-content;
}

/* 默认情况下，第二行会和第一行有一定间距 */
.scroller + .scroller {
  margin-top: 1.5rem;
}

.scroller-inner {
  display: flex;
  gap: 1.5rem;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
}

/* 应用动画 */
.scroller[data-direction="right"] .scroller-inner {
  animation-name: scroll-right;
  animation-duration: 60s;
}

.scroller[data-direction="left"] .scroller-inner {
  animation-name: scroll-left;
  animation-duration: 65s; /* 可以设置不同时长增加错落感 */
}

/* 鼠标悬停时暂停动画 */
.nft-gallery-container:hover .scroller-inner {
  animation-play-state: paused;
}


.image-wrapper {
  flex-shrink: 0;
  width: 250px;
  height: 250px;
  border-radius: 1rem;
  overflow: hidden;
  border: 2px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.05);
  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  transition: all 0.3s ease;
}

.image-wrapper:hover {
  transform: scale(1.05) translateY(-5px);
  border-color: rgba(251, 191, 36, 0.5);
  box-shadow: 0 0 25px rgba(251, 191, 36, 0.3);
}

.nft-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* 定义两种滚动动画 */
@keyframes scroll-left {
  from {
      transform: translateX(0);
  }
  to {
    transform: translateX(calc(-50% - 0.75rem));
  }
}

@keyframes scroll-right {
  from {
    transform: translateX(calc(-50% - 0.75rem));
  }
  to {
      transform: translateX(0);
  }
}

</style>