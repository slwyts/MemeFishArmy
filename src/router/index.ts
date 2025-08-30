import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import { useWalletStore } from '../store/wallet'
import { useContractStore } from '../store/contract'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('../views/AdminView.vue'),
      meta: { requiresAuth: true } // 添加一个元字段，表示此路由需要验证
    }
  ]
})

// 全局前置守卫
router.beforeEach(async (to, from, next) => {
  if (to.meta.requiresAuth) {
    const walletStore = useWalletStore()
    const contractStore = useContractStore()

    // 确保我们已经获取了 owner 地址
    if (!contractStore.ownerAddress) {
      await contractStore.fetchContractData()
    }

    // 检查当前连接的地址是否为 owner
    if (walletStore.connectedAddress && walletStore.connectedAddress.toLowerCase() === contractStore.ownerAddress?.toLowerCase()) {
      next() // 是 owner，放行
    } else {
      next('/') // 不是 owner，重定向到首页
      // next() // 移除或注释掉这行错误的代码
    }
  } else {
    next() // 不需要验证的页面，直接放行
  }
})

export default router