import { defineStore } from 'pinia'
import { ethers } from 'ethers'
import { mfacSystemAddress, mfacSystemAbi } from '@/contracts'
import { useWalletStore } from './wallet'

export interface ContractStats {
  nftsSold: bigint
  airdropStartTime: bigint
  stakingPoolRemaining: bigint
  circulatingDividendPool: bigint
  sbtDividendPool: bigint
  daoTreasury: bigint
  superBuilderPoolRemaining: bigint
  nftRoyaltyPool: bigint
  totalNFTRoyaltyReceived: bigint
}

export interface ReferralInfo {
  referrer: string
  directSales: bigint
  communitySales: bigint
  qualified: boolean
  claimed: bigint
}

export interface StakeInfo {
  tokenId: bigint
  startTime: bigint
  lastClaimTime: bigint
}

export interface Proposal {
  id: bigint
  proposer: string
  description: string
  yesVotes: bigint
  noVotes: bigint
  endTime: bigint
  closed: boolean
  exists: boolean
}

export const useMFACSystemStore = defineStore('mfacSystem', {
  state: () => ({
    contract: null as ethers.Contract | null,
    loading: false,
    error: null as string | null,
    
    // 合约统计数据
    stats: null as ContractStats | null,
    
    // 用户数据
    userTokenBalance: 0n,
    userNFTBalance: [] as bigint[],
    userStakes: [] as StakeInfo[],
    userReferralInfo: null as ReferralInfo | null,
    userClaimableAirdrop: 0n,
    userDividendBalance: { circulating: 0n, sbt: 0n },
    
    // DAO 数据
    proposals: [] as Proposal[],
    isGuardian: false,
    isVoter: false,
    
    // NFT 预售
    nftPrice: 0n,
    presaleActive: false,
    
    // 手续费配置
    feesEnabled: false,
    
    // 质押排名
    stakingRanking: [] as string[],
  }),

  getters: {
    // 格式化代币余额
    formattedTokenBalance(): string {
      return ethers.formatEther(this.userTokenBalance)
    },
    
    // 格式化合约统计
    formattedStats(): any {
      if (!this.stats) return null
      return {
        nftsSold: Number(this.stats.nftsSold),
        airdropStartTime: Number(this.stats.airdropStartTime),
        stakingPoolRemaining: ethers.formatEther(this.stats.stakingPoolRemaining),
        circulatingDividendPool: ethers.formatEther(this.stats.circulatingDividendPool),
        sbtDividendPool: ethers.formatEther(this.stats.sbtDividendPool),
        daoTreasury: ethers.formatEther(this.stats.daoTreasury),
        superBuilderPoolRemaining: ethers.formatEther(this.stats.superBuilderPoolRemaining),
      }
    },
    
    // 是否已开始空投
    airdropStarted(): boolean {
      return this.stats ? this.stats.airdropStartTime > 0n : false
    },
    
    // 空投剩余天数
    airdropDaysRemaining(): number {
      if (!this.stats || this.stats.airdropStartTime === 0n) return 100
      const elapsed = Math.floor(Date.now() / 1000) - Number(this.stats.airdropStartTime)
      const remaining = 100 - Math.floor(elapsed / 86400)
      return Math.max(0, remaining)
    },
  },

  actions: {
    // 初始化合约
    async initContract() {
      if (!mfacSystemAddress) {
        this.error = 'Contract address not available'
        return
      }

      try {
        if (typeof window.ethereum === 'undefined') {
          this.error = 'Please install MetaMask'
          return
        }

        const provider = new ethers.BrowserProvider(window.ethereum)
        const signer = await provider.getSigner()
        this.contract = new ethers.Contract(
          mfacSystemAddress,
          mfacSystemAbi,
          signer
        )
        this.error = null
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to initialize MFAC contract:', err)
      }
    },

    // 获取合约统计数据
    async fetchContractStats() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const stats = await this.contract.getContractStats()
        this.stats = {
          nftsSold: stats[0],
          airdropStartTime: stats[1],
          stakingPoolRemaining: stats[2],
          circulatingDividendPool: stats[3],
          sbtDividendPool: stats[4],
          daoTreasury: stats[5],
          superBuilderPoolRemaining: stats[6],
          nftRoyaltyPool: stats[7],
          totalNFTRoyaltyReceived: stats[8],
        }
        
        // 同时获取预售信息和手续费状态
        this.nftPrice = await this.contract.nftPrice()
        this.presaleActive = await this.contract.presaleActive()
        this.feesEnabled = await this.contract.feesEnabled()
        
        this.error = null
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to fetch contract stats:', err)
      } finally {
        this.loading = false
      }
    },

    // 获取用户代币余额
    async fetchUserTokenBalance() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      const walletStore = useWalletStore()
      if (!walletStore.connectedAddress) return

      try {
        this.userTokenBalance = await this.contract.balanceOf(walletStore.connectedAddress)
      } catch (err: any) {
        console.error('Failed to fetch token balance:', err)
      }
    },

    // 获取用户质押信息
    async fetchUserStakes() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      const walletStore = useWalletStore()
      if (!walletStore.connectedAddress) return

      try {
        const stakes = await this.contract.getUserStakes(walletStore.connectedAddress)
        this.userStakes = stakes.map((s: any) => ({
          tokenId: s.tokenId,
          startTime: s.startTime,
          lastClaimTime: s.lastClaimTime,
        }))
      } catch (err: any) {
        console.error('Failed to fetch user stakes:', err)
      }
    },

    // 获取用户推荐信息
    async fetchUserReferralInfo() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      const walletStore = useWalletStore()
      if (!walletStore.connectedAddress) return

      try {
        const info = await this.contract.getReferralInfo(walletStore.connectedAddress)
        this.userReferralInfo = {
          referrer: info[0],
          directSales: info[1],
          communitySales: info[2],
          qualified: info[3],
          claimed: info[4],
        }
      } catch (err: any) {
        console.error('Failed to fetch referral info:', err)
      }
    },

    // 获取可领取的空投
    async fetchClaimableAirdrop(tokenIds: bigint[]) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      const walletStore = useWalletStore()
      if (!walletStore.connectedAddress) return

      try {
        this.userClaimableAirdrop = await this.contract.getClaimableAirdrop(
          walletStore.connectedAddress,
          tokenIds
        )
      } catch (err: any) {
        console.error('Failed to fetch claimable airdrop:', err)
      }
    },

    // 获取分红余额
    async fetchDividendBalance() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      const walletStore = useWalletStore()
      if (!walletStore.connectedAddress) return

      try {
        const balance = await this.contract.getDividendBalance(walletStore.connectedAddress)
        this.userDividendBalance = {
          circulating: balance[0],
          sbt: balance[1],
        }
      } catch (err: any) {
        console.error('Failed to fetch dividend balance:', err)
      }
    },

    // 获取质押排名
    async fetchStakingRanking() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      try {
        this.stakingRanking = await this.contract.getStakingRanking()
      } catch (err: any) {
        console.error('Failed to fetch staking ranking:', err)
      }
    },

    // 获取 DAO 状态
    async fetchDAOStatus() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      const walletStore = useWalletStore()
      if (!walletStore.connectedAddress) return

      try {
        this.isGuardian = await this.contract.isGuardian(walletStore.connectedAddress)
        this.isVoter = await this.contract.isVoter(walletStore.connectedAddress)
      } catch (err: any) {
        console.error('Failed to fetch DAO status:', err)
      }
    },

    // ========================================
    // 交易方法
    // ========================================

    // 购买 NFT
    async purchaseNFT(referrer: string = ethers.ZeroAddress) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.purchaseNFT(referrer, {
          value: this.nftPrice
        })
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to purchase NFT:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 领取空投
    async claimAirdrop(tokenIds: bigint[]) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.claimAirdrop(tokenIds)
        await tx.wait()
        await this.fetchUserTokenBalance()
        await this.fetchClaimableAirdrop(tokenIds)
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to claim airdrop:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 质押 NFT
    async stakeNFT(tokenId: bigint) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.stake(tokenId)
        await tx.wait()
        await this.fetchUserStakes()
        await this.fetchStakingRanking()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to stake NFT:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 解押 NFT
    async unstakeNFT(tokenId: bigint) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.unstake(tokenId)
        await tx.wait()
        await this.fetchUserStakes()
        await this.fetchUserTokenBalance()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to unstake NFT:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 领取质押奖励
    async claimStakingReward() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.claimStakingReward()
        await tx.wait()
        await this.fetchUserTokenBalance()
        await this.fetchUserStakes()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to claim staking reward:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 领取分红
    async claimDividend() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.claimDividend()
        await tx.wait()
        await this.fetchUserTokenBalance()
        await this.fetchDividendBalance()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to claim dividend:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 创建 DAO 提案
    async createProposal(description: string) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.createProposal(description)
        await tx.wait()
        await this.fetchProposals()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to create proposal:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 获取提案列表
    async fetchProposals() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      try {
        const proposalCount = await this.contract.proposalCount()
        const proposals: Proposal[] = []
        
        for (let i = 1n; i <= proposalCount; i++) {
          const proposal = await this.contract.proposals(i)
          proposals.push({
            id: i,
            proposer: proposal.proposer,
            description: proposal.description,
            yesVotes: proposal.yesVotes,
            noVotes: proposal.noVotes,
            endTime: proposal.endTime,
            closed: proposal.closed,
            exists: proposal.exists || true,
          })
        }
        
        this.proposals = proposals
      } catch (err) {
        console.error('Failed to fetch proposals:', err)
      }
    },

    // DAO 投票
    async voteProposal(proposalId: bigint, support: boolean) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.vote(proposalId, support)
        await tx.wait()
        await this.fetchProposals()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to vote:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 执行提案
    async executeProposal(proposalId: bigint) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.executeProposal(proposalId)
        await tx.wait()
        await this.fetchProposals()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to execute proposal:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 领取 Super Builder 奖励
    async claimBuilderReward() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.claimSuperBuilderReward()
        await tx.wait()
        await this.fetchUserTokenBalance()
        await this.fetchUserReferralInfo()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to claim builder reward:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 查询用户可领取的 NFT 版税 (BNB)
    async getPendingNFTRoyalty(address: string): Promise<bigint> {
      if (!this.contract) this.initContract()
      if (!this.contract) return 0n

      try {
        const amount = await this.contract.getPendingNFTRoyalty(address)
        return amount
      } catch (err: any) {
        console.error('Failed to get pending NFT royalty:', err)
        return 0n
      }
    },

    // 领取 NFT 版税 (BNB)
    async claimNFTRoyalty() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.claimNFTRoyalty()
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to claim NFT royalty:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 刷新所有用户数据
    async refreshUserData(tokenIds: bigint[] = []) {
      await Promise.all([
        this.fetchContractStats(),
        this.fetchUserTokenBalance(),
        this.fetchUserStakes(),
        this.fetchUserReferralInfo(),
        this.fetchDividendBalance(),
        this.fetchDAOStatus(),
        tokenIds.length > 0 ? this.fetchClaimableAirdrop(tokenIds) : Promise.resolve(),
      ])
    },

    // ========================================
    // 管理员方法
    // ========================================

    // 设置预售状态
    async setPresaleActive(active: boolean) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setPresaleActive(active)
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set presale active:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置 NFT 价格
    async setNFTPrice(price: bigint) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setNFTPrice(price)
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set NFT price:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 开启空投
    async startAirdrop() {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.startAirdrop()
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to start airdrop:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置 DEX Pair
    async setDEXPair(pair: string, isPair: boolean) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setDEXPair(pair, isPair)
        await tx.wait()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set DEX pair:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置免手续费地址
    async setExcludedFromFee(account: string, excluded: boolean) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setExcludedFromFee(account, excluded)
        await tx.wait()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set excluded from fee:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置手续费比例
    async setFeePercents(buyFee: number, sellFee: number) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setFeePercents(buyFee, sellFee)
        await tx.wait()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set fee percents:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置手续费开关
    async setFeesEnabled(enabled: boolean) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setFeesEnabled(enabled)
        await tx.wait()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set fees enabled:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置手续费分配比例
    async setFeeDistribution(circulating: number, sbt: number, dao: number) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setFeeDistribution(circulating, sbt, dao)
        await tx.wait()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set fee distribution:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 提取 MFAC 代币
    async withdrawMFAC(to: string, amount: bigint) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.withdrawMFAC(to, amount)
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to withdraw MFAC:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 提取 BNB
    async withdrawBNB(to: string, amount: bigint) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.withdrawBNB(to, amount)
        await tx.wait()
        await this.fetchContractStats()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to withdraw BNB:', err)
        return false
      } finally {
        this.loading = false
      }
    },

    // 设置 NFT 版税（通过代理）
    async setNFTRoyalty(royaltyFraction: number) {
      if (!this.contract) this.initContract()
      if (!this.contract) return

      this.loading = true
      try {
        const tx = await this.contract.setNFTRoyalty(royaltyFraction)
        await tx.wait()
        this.error = null
        return true
      } catch (err: any) {
        this.error = err.message
        console.error('Failed to set NFT royalty:', err)
        return false
      } finally {
        this.loading = false
      }
    },
  },
})
