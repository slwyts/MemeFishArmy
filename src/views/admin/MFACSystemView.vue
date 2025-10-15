<template>
  <div class="space-y-8">
    <!-- 重要提示：权限转移和版税设置 -->
    <div class="bg-gradient-to-r from-red-500/20 to-orange-500/20 backdrop-blur-sm p-6 rounded-2xl border-2 border-red-500/50">
      <div class="flex items-start space-x-4">
        <div class="text-4xl">⚠️</div>
        <div class="flex-1">
          <h3 class="text-xl font-bold text-red-400 mb-2">重要：合约权限配置（必须按顺序执行）</h3>
          <div class="space-y-2 text-sm text-gray-300">
            <p class="font-semibold">部署 MFACSystem 后的配置步骤：</p>
            <ol class="list-decimal list-inside space-y-2 ml-4">
              <li>
                <strong class="text-yellow-400">步骤 1：转移 NFT 合约所有权</strong><br/>
                <span class="ml-6">在老 NFT 合约调用 <code class="bg-slate-800 px-2 py-0.5 rounded text-cyan-400">transferOwnership(MFACSystem合约地址)</code></span><br/>
                <span class="ml-6 text-gray-400">→ 这样 MFACSystem 才能调用 NFT 合约的管理员功能</span>
              </li>
              <li>
                <strong class="text-yellow-400">步骤 2：设置 NFT 版税接收者</strong><br/>
                <span class="ml-6">在本页面点击下方 "🎨 设置 NFT 版税" 按钮</span><br/>
                <span class="ml-6 text-gray-400">→ NFT 交易市场的版税会打到 MFACSystem 合约</span>
              </li>
              <li>
                <strong class="text-green-400">完成配置</strong><br/>
                <span class="ml-6 text-gray-400">→ 所有功能通过本页面统一管理</span>
              </li>
            </ol>
            <div class="mt-4 pt-4 border-t border-slate-600 space-y-1">
              <p class="text-yellow-400">
                ⚡ NFT 合约: <code class="bg-slate-800 px-2 py-0.5 rounded">{{ nftContractAddress }}</code>
              </p>
              <p class="text-green-400">
                ✅ MFAC 合约: <code class="bg-slate-800 px-2 py-0.5 rounded">{{ mfacSystemAddress }}</code>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 池子余额统计 -->
    <div class="bg-slate-900/80 backdrop-blur-sm p-8 rounded-2xl border border-slate-700">
      <h2 class="text-2xl font-bold text-white mb-6">📊 系统资金池统计</h2>
      
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <div class="p-4 bg-gradient-to-br from-green-900/30 to-green-800/20 border border-green-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">质押池</div>
          <div class="text-2xl font-bold text-white">{{ formatMFAC(stats?.stakingPoolRemaining) }}</div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-blue-900/30 to-blue-800/20 border border-blue-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">流通NFT分红</div>
          <div class="text-2xl font-bold text-white">{{ formatMFAC(stats?.circulatingDividendPool) }}</div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-purple-900/30 to-purple-800/20 border border-purple-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">SBT分红</div>
          <div class="text-2xl font-bold text-white">{{ formatMFAC(stats?.sbtDividendPool) }}</div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-yellow-900/30 to-yellow-800/20 border border-yellow-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">DAO国库</div>
          <div class="text-2xl font-bold text-white">{{ formatMFAC(stats?.daoTreasury) }}</div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-orange-900/30 to-orange-800/20 border border-orange-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">Builder池</div>
          <div class="text-2xl font-bold text-white">{{ formatMFAC(stats?.superBuilderPoolRemaining) }}</div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-pink-900/30 to-pink-800/20 border border-pink-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">💎 NFT版税池</div>
          <div class="text-2xl font-bold text-white">{{ formatBNB(stats?.nftRoyaltyPool) }}</div>
          <div class="text-xs text-gray-400">BNB</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-indigo-900/30 to-indigo-800/20 border border-indigo-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">📈 累计版税</div>
          <div class="text-2xl font-bold text-white">{{ formatBNB(stats?.totalNFTRoyaltyReceived) }}</div>
          <div class="text-xs text-gray-400">BNB</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-slate-900/30 to-slate-800/20 border border-slate-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">合约余额</div>
          <div class="text-2xl font-bold text-white">{{ formatMFAC(contractBalance) }}</div>
          <div class="text-xs text-gray-400">MFAC</div>
        </div>
        <div class="p-4 bg-gradient-to-br from-emerald-900/30 to-emerald-800/20 border border-emerald-500/30 rounded-xl">
          <div class="text-sm text-gray-300 mb-1">NFT已售</div>
          <div class="text-2xl font-bold text-white">{{ stats?.nftsSold?.toString() || '0' }}</div>
          <div class="text-xs text-gray-400">/ 4500</div>
        </div>
      </div>
    </div>

    <!-- Tab 导航 -->
    <div class="bg-slate-900/80 backdrop-blur-sm rounded-2xl border border-slate-700">
      <div class="flex border-b border-slate-700 overflow-x-auto">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'px-6 py-4 font-semibold whitespace-nowrap transition-all',
            activeTab === tab.id
              ? 'text-cyan-400 border-b-2 border-cyan-400 bg-cyan-500/10'
              : 'text-gray-400 hover:text-gray-300 hover:bg-slate-800/50'
          ]"
        >
          {{ tab.icon }} {{ tab.name }}
        </button>
      </div>

      <div class="p-8">
        <!-- NFT 预售管理 -->
        <div v-show="activeTab === 'presale'">
          <h3 class="text-xl font-bold text-white mb-6">NFT 预售管理</h3>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- 预售状态 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-2">预售状态</label>
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold" :class="presaleActive ? 'text-green-400' : 'text-red-400'">
                  {{ presaleActive ? '✅ 进行中' : '❌ 已关闭' }}
                </span>
                <button
                  @click="togglePresale"
                  :disabled="loading.presale"
                  class="px-6 py-2 font-bold rounded-lg transition-colors disabled:bg-gray-500"
                  :class="presaleActive ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'"
                >
                  <i v-if="loading.presale" class="fa fa-spinner fa-spin mr-2"></i>
                  {{ presaleActive ? '关闭预售' : '开启预售' }}
                </button>
              </div>
            </div>

            <!-- NFT 价格 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-2">NFT 价格</label>
              <div class="flex items-center space-x-3">
                <input
                  v-model="nftPriceInput"
                  type="number"
                  step="0.01"
                  placeholder="1.0"
                  class="flex-1 bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                />
                <span class="text-gray-400">BNB</span>
                <button
                  @click="updateNFTPrice"
                  :disabled="loading.nftPrice"
                  class="px-6 py-2 bg-cyan-600 hover:bg-cyan-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
                >
                  <i v-if="loading.nftPrice" class="fa fa-spinner fa-spin mr-2"></i>
                  更新
                </button>
              </div>
              <p class="text-xs text-gray-400 mt-2">当前价格: {{ formatBNB(nftPrice) }} BNB</p>
            </div>
          </div>
        </div>

        <!-- 空投管理 -->
        <div v-show="activeTab === 'airdrop'">
          <h3 class="text-xl font-bold text-white mb-6">空投管理</h3>
          <div class="bg-slate-800/50 p-6 rounded-xl">
            <div class="flex items-center justify-between mb-4">
              <div>
                <div class="font-semibold text-white text-lg">空投状态</div>
                <div class="text-sm text-gray-400">
                  {{ airdropStarted ? '已开启' : '未开启' }}
                  <span v-if="airdropStarted" class="ml-2">
                    | 剩余 {{ airdropDaysRemaining }} 天
                  </span>
                </div>
              </div>
              <button
                v-if="!airdropStarted"
                @click="handleStartAirdrop"
                :disabled="loading.airdrop"
                class="px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
              >
                <i v-if="loading.airdrop" class="fa fa-spinner fa-spin mr-2"></i>
                🎁 开启空投
              </button>
              <span v-else class="text-green-400 font-bold text-lg">✓ 已开启</span>
            </div>
            
            <div v-if="airdropStarted" class="grid grid-cols-2 gap-4 p-4 bg-blue-900/20 border border-blue-500/30 rounded-lg">
              <div>
                <div class="text-sm text-blue-300">开始时间</div>
                <div class="font-mono text-white">{{ formatTimestamp(stats?.airdropStartTime) }}</div>
              </div>
              <div>
                <div class="text-sm text-blue-300">每NFT每天</div>
                <div class="font-bold text-white">1,000 MFAC</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 手续费配置 -->
        <div v-show="activeTab === 'fees'">
          <h3 class="text-xl font-bold text-white mb-6">交易手续费配置</h3>
          
          <div class="space-y-6">
            <!-- 手续费开关 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <div class="flex items-center justify-between">
                <div>
                  <div class="font-semibold text-white">手续费开关</div>
                  <div class="text-sm text-gray-400">买入1% / 卖出2%</div>
                </div>
                <button
                  @click="toggleFees"
                  :disabled="loading.feesEnabled"
                  class="px-6 py-2 font-bold rounded-lg transition-colors disabled:bg-gray-500"
                  :class="feesEnabled ? 'bg-green-600 hover:bg-green-700' : 'bg-gray-600 hover:bg-gray-700'"
                >
                  <i v-if="loading.feesEnabled" class="fa fa-spinner fa-spin mr-2"></i>
                  {{ feesEnabled ? '已开启' : '已关闭' }}
                </button>
              </div>
            </div>

            <!-- 手续费比例 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">手续费比例</label>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">买入手续费 (%)</label>
                  <input
                    v-model.number="buyFeeInput"
                    type="number"
                    min="0"
                    max="10"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">卖出手续费 (%)</label>
                  <input
                    v-model.number="sellFeeInput"
                    type="number"
                    min="0"
                    max="10"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
              </div>
              <button
                @click="updateFeePercents"
                :disabled="loading.feePercents"
                class="mt-4 w-full px-6 py-2 bg-cyan-600 hover:bg-cyan-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
              >
                <i v-if="loading.feePercents" class="fa fa-spinner fa-spin mr-2"></i>
                更新手续费比例
              </button>
            </div>

            <!-- 手续费分配比例 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">手续费分配比例（总计需为100%）</label>
              <div class="grid grid-cols-3 gap-4">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">流通NFT (%)</label>
                  <input
                    v-model.number="feeDistribution.circulating"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">SBT (%)</label>
                  <input
                    v-model.number="feeDistribution.sbt"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">DAO国库 (%)</label>
                  <input
                    v-model.number="feeDistribution.dao"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
              </div>
              <div class="mt-2 text-sm" :class="feeDistributionTotal === 100 ? 'text-green-400' : 'text-red-400'">
                总计: {{ feeDistributionTotal }}% {{ feeDistributionTotal === 100 ? '✓' : '✗ 必须等于100%' }}
              </div>
              <button
                @click="updateFeeDistribution"
                :disabled="loading.feeDistribution || feeDistributionTotal !== 100"
                class="mt-4 w-full px-6 py-2 bg-cyan-600 hover:bg-cyan-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
              >
                <i v-if="loading.feeDistribution" class="fa fa-spinner fa-spin mr-2"></i>
                更新分配比例
              </button>
            </div>
          </div>
        </div>

        <!-- DEX & 白名单 -->
        <div v-show="activeTab === 'dex'">
          <h3 class="text-xl font-bold text-white mb-6">DEX Pair & 免手续费地址</h3>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- DEX Pair 管理 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-2">DEX Pair 管理</label>
              <p class="text-xs text-gray-400 mb-4">设置 DEX 交易对地址（用于识别买卖方向）</p>
              <div class="space-y-3">
                <input
                  v-model="dexPairInput"
                  type="text"
                  placeholder="0x..."
                  class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                />
                <div class="flex space-x-3">
                  <button
                    @click="setDEXPair(true)"
                    :disabled="loading.dexPair"
                    class="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.dexPair" class="fa fa-spinner fa-spin mr-2"></i>
                    添加 Pair
                  </button>
                  <button
                    @click="setDEXPair(false)"
                    :disabled="loading.dexPair"
                    class="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.dexPair" class="fa fa-spinner fa-spin mr-2"></i>
                    移除 Pair
                  </button>
                </div>
              </div>
            </div>

            <!-- 免手续费地址 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-2">免手续费地址</label>
              <p class="text-xs text-gray-400 mb-4">设置不收取交易手续费的地址</p>
              <div class="space-y-3">
                <input
                  v-model="excludedAddressInput"
                  type="text"
                  placeholder="0x..."
                  class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                />
                <div class="flex space-x-3">
                  <button
                    @click="setExcludedFromFee(true)"
                    :disabled="loading.excludedFee"
                    class="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.excludedFee" class="fa fa-spinner fa-spin mr-2"></i>
                    添加豁免
                  </button>
                  <button
                    @click="setExcludedFromFee(false)"
                    :disabled="loading.excludedFee"
                    class="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors disabled:bg-gray-500"
                  >
                    <i v-if="loading.excludedFee" class="fa fa-spinner fa-spin mr-2"></i>
                    移除豁免
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- NFT 配置代理 -->
        <div v-show="activeTab === 'nft'">
          <h3 class="text-xl font-bold text-white mb-6">NFT 合约代理管理</h3>
          <div class="space-y-6">
            <!-- NFT 版税设置 -->
            <div class="bg-gradient-to-r from-purple-500/20 to-pink-500/20 p-6 rounded-xl border-2 border-purple-500/50">
              <div class="flex items-center justify-between">
                <div>
                  <div class="font-semibold text-purple-300 text-lg">🎨 NFT 版税设置</div>
                  <div class="text-sm text-gray-300 mt-1">
                    设置 NFT 版税比例（单位：基点，500 = 5%）
                  </div>
                </div>
                <div class="flex items-center space-x-3">
                  <input
                    v-model.number="royaltyInput"
                    type="number"
                    min="0"
                    max="10000"
                    placeholder="500"
                    class="w-24 bg-slate-700 border border-slate-600 rounded-lg px-3 py-2 text-white focus:ring-2 focus:ring-purple-500 focus:outline-none"
                  />
                  <button
                    @click="updateNFTRoyalty"
                    :disabled="loading.nftRoyalty"
                    class="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition-all disabled:opacity-50"
                  >
                    <i v-if="loading.nftRoyalty" class="fa fa-spinner fa-spin mr-2"></i>
                    更新版税
                  </button>
                </div>
              </div>
            </div>

            <!-- 白名单管理 -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">白名单管理（通过 MFAC 代理）</label>
              <p class="text-xs text-gray-400 mb-4">⚠️ 白名单管理已移至 "NFT 管理" 页面</p>
              <router-link 
                to="/admin/nft-management"
                class="inline-block px-6 py-2 bg-cyan-600 hover:bg-cyan-700 text-white font-bold rounded-lg transition-colors"
              >
                前往 NFT 管理页面 →
              </router-link>
            </div>
          </div>
        </div>

        <!-- 资金提取 -->
        <div v-show="activeTab === 'withdraw'">
          <h3 class="text-xl font-bold text-white mb-6">资金提取</h3>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- 提取 MFAC -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">提取 MFAC 代币</label>
              <div class="space-y-3">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">接收地址</label>
                  <input
                    v-model="withdrawMFAC.to"
                    type="text"
                    placeholder="0x..."
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">数量（MFAC）</label>
                  <input
                    v-model="withdrawMFAC.amount"
                    type="number"
                    step="0.01"
                    placeholder="1000"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <button
                  @click="handleWithdrawMFAC"
                  :disabled="loading.withdrawMFAC"
                  class="w-full px-6 py-2 bg-orange-600 hover:bg-orange-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
                >
                  <i v-if="loading.withdrawMFAC" class="fa fa-spinner fa-spin mr-2"></i>
                  💰 提取 MFAC
                </button>
              </div>
            </div>

            <!-- 提取 BNB -->
            <div class="bg-slate-800/50 p-6 rounded-xl">
              <label class="block text-sm font-semibold text-gray-300 mb-4">提取 BNB</label>
              <div class="space-y-3">
                <div>
                  <label class="block text-xs text-gray-400 mb-2">接收地址</label>
                  <input
                    v-model="withdrawBNB.to"
                    type="text"
                    placeholder="0x..."
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-2">数量（BNB）</label>
                  <input
                    v-model="withdrawBNB.amount"
                    type="number"
                    step="0.001"
                    placeholder="1.0"
                    class="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-cyan-500 focus:outline-none"
                  />
                </div>
                <button
                  @click="handleWithdrawBNB"
                  :disabled="loading.withdrawBNB"
                  class="w-full px-6 py-2 bg-yellow-600 hover:bg-yellow-700 text-white font-bold rounded-lg transition-colors disabled:bg-gray-500"
                >
                  <i v-if="loading.withdrawBNB" class="fa fa-spinner fa-spin mr-2"></i>
                  💎 提取 BNB
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 成功/错误提示 -->
    <Transition name="fade">
      <div v-if="successMessage" class="bg-green-500/20 border border-green-500/50 rounded-lg p-4">
        <p class="text-green-400 font-semibold">✓ {{ successMessage }}</p>
      </div>
    </Transition>

    <Transition name="fade">
      <div v-if="errorMessage" class="bg-red-500/20 border border-red-500/50 rounded-lg p-4">
        <p class="text-red-400 font-semibold">✗ {{ errorMessage }}</p>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useMFACSystemStore } from '@/store/mfacSystem'
import { useWalletStore } from '@/store/wallet'
import { ethers } from 'ethers'

const mfacStore = useMFACSystemStore()
const walletStore = useWalletStore()

// Refs
const activeTab = ref('presale')
const nftContractAddress = import.meta.env.VITE_NFT_CONTRACT_ADDRESS
const mfacSystemAddress = import.meta.env.VITE_MFAC_SYSTEM_CONTRACT_ADDRESS

const tabs = [
  { id: 'presale', name: '预售管理', icon: '🎫' },
  { id: 'airdrop', name: '空投管理', icon: '🎁' },
  { id: 'fees', name: '手续费配置', icon: '💰' },
  { id: 'dex', name: 'DEX & 白名单', icon: '🔄' },
  { id: 'nft', name: 'NFT 配置', icon: '🎨' },
  { id: 'withdraw', name: '资金提取', icon: '💸' },
]

// Form inputs
const nftPriceInput = ref('1.0')
const buyFeeInput = ref(1)
const sellFeeInput = ref(2)
const feeDistribution = ref({
  circulating: 30,
  sbt: 20,
  dao: 50,
})
const dexPairInput = ref('')
const excludedAddressInput = ref('')
const royaltyInput = ref(500)
const withdrawMFAC = ref({ to: '', amount: '' })
const withdrawBNB = ref({ to: '', amount: '' })

// Loading states
const loading = ref({
  presale: false,
  nftPrice: false,
  airdrop: false,
  feesEnabled: false,
  feePercents: false,
  feeDistribution: false,
  dexPair: false,
  excludedFee: false,
  nftRoyalty: false,
  withdrawMFAC: false,
  withdrawBNB: false,
})

// Messages
const successMessage = ref('')
const errorMessage = ref('')

// Computed
const stats = computed(() => mfacStore.stats)
const contractBalance = computed(() => mfacStore.userTokenBalance) // 需要获取合约地址的余额
const presaleActive = computed(() => mfacStore.presaleActive)
const nftPrice = computed(() => mfacStore.nftPrice)
const feesEnabled = computed(() => mfacStore.feesEnabled)
const airdropStarted = computed(() => mfacStore.airdropStarted)
const airdropDaysRemaining = computed(() => mfacStore.airdropDaysRemaining)
const feeDistributionTotal = computed(() => 
  feeDistribution.value.circulating + feeDistribution.value.sbt + feeDistribution.value.dao
)

// Helper functions
const formatMFAC = (amount: bigint | undefined): string => {
  if (!amount) return '0'
  return (Number(amount) / 1e18).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })
}

const formatBNB = (amount: bigint | undefined): string => {
  if (!amount) return '0'
  return (Number(amount) / 1e18).toLocaleString(undefined, { minimumFractionDigits: 4, maximumFractionDigits: 4 })
}

const formatTimestamp = (timestamp: bigint | undefined): string => {
  if (!timestamp) return '--'
  return new Date(Number(timestamp) * 1000).toLocaleString('zh-CN')
}

const clearMessages = () => {
  setTimeout(() => {
    successMessage.value = ''
    errorMessage.value = ''
  }, 5000)
}

const showSuccess = (msg: string) => {
  successMessage.value = msg
  errorMessage.value = ''
  clearMessages()
}

const showError = (msg: string) => {
  errorMessage.value = msg
  successMessage.value = ''
  clearMessages()
}

// Actions
const togglePresale = async () => {
  loading.value.presale = true
  try {
    const result = await mfacStore.setPresaleActive(!presaleActive.value)
    if (result) {
      showSuccess(`预售已${presaleActive.value ? '开启' : '关闭'}`)
    } else {
      showError('操作失败')
    }
  } catch (err: any) {
    showError(err.message || '操作失败')
  } finally {
    loading.value.presale = false
  }
}

const updateNFTPrice = async () => {
  loading.value.nftPrice = true
  try {
    const price = ethers.parseEther(nftPriceInput.value)
    const result = await mfacStore.setNFTPrice(price)
    if (result) {
      showSuccess(`NFT 价格已更新为 ${nftPriceInput.value} BNB`)
    } else {
      showError('更新失败')
    }
  } catch (err: any) {
    showError(err.message || '更新失败')
  } finally {
    loading.value.nftPrice = false
  }
}

const handleStartAirdrop = async () => {
  loading.value.airdrop = true
  try {
    const result = await mfacStore.startAirdrop()
    if (result) {
      showSuccess('✓ 空投已成功开启！')
    } else {
      showError('开启失败')
    }
  } catch (err: any) {
    showError(err.message || '开启失败')
  } finally {
    loading.value.airdrop = false
  }
}

const toggleFees = async () => {
  loading.value.feesEnabled = true
  try {
    const result = await mfacStore.setFeesEnabled(!feesEnabled.value)
    if (result) {
      showSuccess(`手续费已${feesEnabled.value ? '开启' : '关闭'}`)
    } else {
      showError('操作失败')
    }
  } catch (err: any) {
    showError(err.message || '操作失败')
  } finally {
    loading.value.feesEnabled = false
  }
}

const updateFeePercents = async () => {
  loading.value.feePercents = true
  try {
    const result = await mfacStore.setFeePercents(buyFeeInput.value, sellFeeInput.value)
    if (result) {
      showSuccess(`手续费比例已更新：买入${buyFeeInput.value}% / 卖出${sellFeeInput.value}%`)
    } else {
      showError('更新失败')
    }
  } catch (err: any) {
    showError(err.message || '更新失败')
  } finally {
    loading.value.feePercents = false
  }
}

const updateFeeDistribution = async () => {
  loading.value.feeDistribution = true
  try {
    const result = await mfacStore.setFeeDistribution(
      feeDistribution.value.circulating,
      feeDistribution.value.sbt,
      feeDistribution.value.dao
    )
    if (result) {
      showSuccess('分配比例已更新')
    } else {
      showError('更新失败')
    }
  } catch (err: any) {
    showError(err.message || '更新失败')
  } finally {
    loading.value.feeDistribution = false
  }
}

const setDEXPair = async (isPair: boolean) => {
  if (!dexPairInput.value || !ethers.isAddress(dexPairInput.value)) {
    showError('请输入有效的地址')
    return
  }
  
  loading.value.dexPair = true
  try {
    const result = await mfacStore.setDEXPair(dexPairInput.value, isPair)
    if (result) {
      showSuccess(`DEX Pair 已${isPair ? '添加' : '移除'}`)
      dexPairInput.value = ''
    } else {
      showError('操作失败')
    }
  } catch (err: any) {
    showError(err.message || '操作失败')
  } finally {
    loading.value.dexPair = false
  }
}

const setExcludedFromFee = async (excluded: boolean) => {
  if (!excludedAddressInput.value || !ethers.isAddress(excludedAddressInput.value)) {
    showError('请输入有效的地址')
    return
  }
  
  loading.value.excludedFee = true
  try {
    const result = await mfacStore.setExcludedFromFee(excludedAddressInput.value, excluded)
    if (result) {
      showSuccess(`地址豁免已${excluded ? '添加' : '移除'}`)
      excludedAddressInput.value = ''
    } else {
      showError('操作失败')
    }
  } catch (err: any) {
    showError(err.message || '操作失败')
  } finally {
    loading.value.excludedFee = false
  }
}

const updateNFTRoyalty = async () => {
  loading.value.nftRoyalty = true
  try {
    const result = await mfacStore.setNFTRoyalty(royaltyInput.value)
    if (result) {
      showSuccess(`NFT 版税已更新为 ${royaltyInput.value / 100}%`)
    } else {
      showError('更新失败')
    }
  } catch (err: any) {
    if (err.message.includes('MFACSystem must be NFT contract owner first')) {
      showError('❌ 失败：请先在 NFT 合约执行 transferOwnership(MFACSystem地址)')
    } else {
      showError(err.message || '更新失败')
    }
  } finally {
    loading.value.nftRoyalty = false
  }
}

const handleWithdrawMFAC = async () => {
  if (!withdrawMFAC.value.to || !ethers.isAddress(withdrawMFAC.value.to)) {
    showError('请输入有效的接收地址')
    return
  }
  if (!withdrawMFAC.value.amount || Number(withdrawMFAC.value.amount) <= 0) {
    showError('请输入有效的数量')
    return
  }
  
  loading.value.withdrawMFAC = true
  try {
    const amount = ethers.parseEther(withdrawMFAC.value.amount)
    const result = await mfacStore.withdrawMFAC(withdrawMFAC.value.to, amount)
    if (result) {
      showSuccess(`成功提取 ${withdrawMFAC.value.amount} MFAC`)
      withdrawMFAC.value = { to: '', amount: '' }
    } else {
      showError('提取失败')
    }
  } catch (err: any) {
    showError(err.message || '提取失败')
  } finally {
    loading.value.withdrawMFAC = false
  }
}

const handleWithdrawBNB = async () => {
  if (!withdrawBNB.value.to || !ethers.isAddress(withdrawBNB.value.to)) {
    showError('请输入有效的接收地址')
    return
  }
  if (!withdrawBNB.value.amount || Number(withdrawBNB.value.amount) <= 0) {
    showError('请输入有效的数量')
    return
  }
  
  loading.value.withdrawBNB = true
  try {
    const amount = ethers.parseEther(withdrawBNB.value.amount)
    const result = await mfacStore.withdrawBNB(withdrawBNB.value.to, amount)
    if (result) {
      showSuccess(`成功提取 ${withdrawBNB.value.amount} BNB`)
      withdrawBNB.value = { to: '', amount: '' }
    } else {
      showError('提取失败')
    }
  } catch (err: any) {
    showError(err.message || '提取失败')
  } finally {
    loading.value.withdrawBNB = false
  }
}

onMounted(async () => {
  if (walletStore.isConnected) {
    await mfacStore.initContract()
    await mfacStore.fetchContractStats()
  }
})
</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
