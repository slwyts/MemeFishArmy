import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import AdminView from '../views/AdminView.vue'
import SettingsView from '../views/admin/SettingsView.vue'
import QueriesView from '../views/admin/QueriesView.vue'
import MFACSystemView from '../views/admin/MFACSystemView.vue'
import { useWalletStore } from '../store/wallet'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(to, _from, savedPosition) {
    if (to.hash) {
      return {
        el: to.hash,
        behavior: 'smooth',
        top: 100, // 为导航栏留出空间
      }
    }
    if (savedPosition) {
      return savedPosition
    }
    return { top: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    // 重定向旧的独立页面路由到首页对应的 section(保留查询参数)
    {
      path: '/presale',
      redirect: to => {
        return { path: '/', hash: '#presale', query: to.query }
      }
    },
    {
      path: '/airdrop',
      redirect: { path: '/', hash: '#airdrop' }
    },
    {
      path: '/staking',
      redirect: { path: '/', hash: '#staking' }
    },
    {
      path: '/dividend',
      redirect: { path: '/', hash: '#dividend' }
    },
    {
      path: '/dao',
      redirect: { path: '/', hash: '#dao' }
    },
    {
      path: '/builder',
      redirect: { path: '/', hash: '#builder' }
    },
    {
      path: '/admin',
      component: AdminView, // AdminView 现在是布局
      meta: { requiresAuth: true },
      children: [
        {
            path: '',
            redirect: '/admin/mfac-system', // 默认重定向到 MFAC 系统管理
        },
        {
          path: 'mfac-system',
          name: 'admin-mfac-system',
          component: MFACSystemView
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

// 全局前置守卫
router.beforeEach(async (to, _from, next) => {
  if (to.meta.requiresAuth) {
    const walletStore = useWalletStore()

    // 检查钱包是否连接
    if (!walletStore.isConnected) {
      console.log('Admin access denied: wallet not connected')
      return next('/')
    }

    try {
      // 开发模式：检查环境变量，如果设置了 VITE_ADMIN_ADDRESS，直接比对
      const adminAddress = import.meta.env.VITE_ADMIN_ADDRESS
      if (adminAddress) {
        console.log('Using VITE_ADMIN_ADDRESS for admin check')
        if (walletStore.connectedAddress?.toLowerCase() === adminAddress.toLowerCase()) {
          console.log('Admin access granted (via VITE_ADMIN_ADDRESS)')
          return next()
        } else {
          console.log('Admin access denied: not matching VITE_ADMIN_ADDRESS')
          return next('/')
        }
      }

      // 生产模式：使用 MFACSystem 合约检查 owner
      const mfacSystemAddress = import.meta.env.VITE_MFAC_SYSTEM_CONTRACT_ADDRESS
      
      if (!mfacSystemAddress) {
        console.error('MFAC System contract address not configured')
        return next('/')
      }

      const provider = new (await import('ethers')).ethers.BrowserProvider(window.ethereum)
      const contract = new (await import('ethers')).ethers.Contract(
        mfacSystemAddress,
        ['function owner() view returns (address)'],
        provider
      )

      const ownerAddress = await contract.owner()
      
      console.log('Connected address:', walletStore.connectedAddress)
      console.log('MFACSystem contract owner:', ownerAddress)

      if (walletStore.connectedAddress && ownerAddress && 
          walletStore.connectedAddress.toLowerCase() === ownerAddress.toLowerCase()) {
        console.log('Admin access granted (via MFACSystem owner)')
        next()
      } else {
        console.log('Admin access denied: not MFACSystem contract owner')
        next('/')
      }
    } catch (err) {
      console.error('Failed to check admin access:', err)
      next('/')
    }
  } else {
    next()
  }
})

export default router