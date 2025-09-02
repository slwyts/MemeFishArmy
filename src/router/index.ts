import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import AdminView from '../views/AdminView.vue' // 引入AdminView
import SettingsView from '../views/admin/SettingsView.vue' // 引入子页面
import QueriesView from '../views/admin/QueriesView.vue'   // 引入子页面
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
      component: AdminView, // AdminView 现在是布局
      meta: { requiresAuth: true },
      children: [
        {
            path: '',
            redirect: '/admin/settings', // 默认重定向到设置页面
        },
        {
          path: 'settings',
          name: 'admin-settings',
          component: SettingsView
        },
        {
          path: 'queries',
          name: 'admin-queries',
          component: QueriesView
        }
      ]
    }
  ]
})

// 全局前置守卫 (保持不变)
router.beforeEach(async (to, from, next) => {
  if (to.meta.requiresAuth) {
    const walletStore = useWalletStore()
    const contractStore = useContractStore()

    if (!walletStore.isConnected) {
      return next('/')
    }

    if (!contractStore.ownerAddress) {
      await contractStore.fetchContractData()
    }

    if (walletStore.connectedAddress && contractStore.ownerAddress && walletStore.connectedAddress.toLowerCase() === contractStore.ownerAddress.toLowerCase()) {
      next()
    } else {
      next('/')
    }
  } else {
    next()
  }
})

export default router