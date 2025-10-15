# DAO 治理机制说明

## 📋 概述

MFACSystem 的 DAO 治理系统是一个**展示型投票系统**，用于收集社区意见和展示社区参与度。

**重要说明：提案投票结果仅供参考，不具备链上自动执行权限，实际执行权完全由项目方决定。**

---

## 🎯 DAO 功能定位

### ✅ 有的功能
- ✅ 守护者可以创建文字提案
- ✅ NFT持有者可以投票（赞成/反对）
- ✅ 自动统计投票结果
- ✅ 展示提案列表和详情
- ✅ 记录投票权重（基于NFT持有数量）

### ❌ 没有的功能
- ❌ 不会自动执行任何链上操作
- ❌ 不会转移任何资金
- ❌ 不会调用任何合约函数
- ❌ 提案中不包含金额、目标地址等参数

---

## 👥 角色体系

### 守护者 (Guardians)
- **资格**: 质押排名前50名用户（基于质押分数）
- **权限**: 可以创建提案
- **数量**: 最多50人

### 选民 (Voters)
- **资格**: 所有NFT持有者
- **权限**: 可以对提案投票
- **投票权重**: 持有NFT数量 = 投票权重

---

## 📝 提案流程

### 1️⃣ 创建提案
```solidity
function createProposal(string memory description) external
```

- **谁可以创建**: 守护者（质押前50名）
- **提案内容**: 纯文字描述，最多1000字符
- **示例提案**:
  - "建议降低交易手续费至1%"
  - "建议增加空投池奖励"
  - "建议开发新功能XXX"

### 2️⃣ 社区投票
```solidity
function vote(uint256 proposalId, bool support) external
```

- **谁可以投票**: 所有NFT持有者
- **投票期限**: 7天
- **投票权重**: 1个NFT = 1票
- **投票选项**: 赞成 / 反对

### 3️⃣ 关闭提案
```solidity
function closeProposal(uint256 proposalId) external
```

- **谁可以关闭**: 任何人（投票期结束后）
- **效果**: 
  - 统计最终结果
  - 标记提案已关闭
  - 触发 `ProposalClosed` 事件

### 4️⃣ 项目方决策
- **链下执行**: 项目方查看投票结果
- **自主决定**: 是否采纳提案内容
- **灵活执行**: 可以部分采纳或修改后执行

---

## 💰 资金流向

### 原本的"DAO国库"改为项目方直接收款

#### MFAC代币收入
- **来源**: 交易手续费的50%
- **流向**: 直接转入项目方钱包
- **统计**: `daoTreasuryMFAC` 变量记录累计金额（仅用于展示）

#### BNB收入
- **来源1**: NFT预售收入的5%
- **来源2**: NFT版税收入的50%
- **流向**: 直接转入项目方钱包
- **统计**: `daoTreasuryBNB` 变量记录累计金额（仅用于展示）

---

## 🔍 查询函数

### 获取提案详情
```solidity
function getProposal(uint256 proposalId) external view
    returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 endTime,
        bool closed,
        bool passed
    )
```

### 获取用户投票状态
```solidity
function getUserVote(uint256 proposalId, address user) external view
    returns (bool hasVoted, uint256 votingPower)
```

### 获取提案列表（分页）
```solidity
function getProposals(uint256 offset, uint256 limit) external view
    returns (
        uint256[] memory ids,
        address[] memory proposers,
        uint256[] memory yesVotes,
        uint256[] memory noVotes,
        uint256[] memory endTimes,
        bool[] memory closed
    )
```

### 检查角色
```solidity
function isGuardian(address user) external view returns (bool)
function isVoter(address user) external view returns (bool)
```

---

## 📊 前端展示建议

### 提案页面
```
提案 #1 - 进行中
提案人: 0x123...abc (守护者)
创建时间: 2025-10-14
截止时间: 2025-10-21

提案内容:
"建议降低买入手续费至0.5%，以吸引更多用户参与"

投票结果:
✅ 赞成: 1,234票 (67%)
❌ 反对: 612票 (33%)

状态: 投票中 (剩余3天)
```

### 提案列表
```
最新提案           状态      赞成率    截止时间
#3 增加空投奖励    进行中    82%      剩余2天
#2 开发移动端APP   已通过    91%      已结束
#1 降低手续费      未通过    45%      已结束
```

---

## ⚠️ 重要提醒

1. **仅供参考**: 投票结果仅作为社区意见参考，不具备强制执行效力

2. **项目方决定**: 是否采纳提案内容完全由项目方决定

3. **无资金风险**: 提案不会自动转移任何资金或执行任何操作

4. **透明展示**: 所有提案和投票记录都在链上公开可查

5. **社区参与**: 提供了一个让社区表达意见的正式渠道

---

## 🎯 设计优势

### 对项目方
- ✅ 保持完全控制权
- ✅ 了解社区真实想法
- ✅ 增强项目透明度
- ✅ 提升社区参与度

### 对用户
- ✅ 有渠道表达意见
- ✅ 参与项目治理讨论
- ✅ 增强归属感
- ✅ 透明的投票记录

---

## 📝 示例场景

### 场景1: 手续费调整提案
1. 守护者A创建提案: "建议降低卖出手续费至1%"
2. 社区投票7天，67%赞成
3. 投票结束，提案显示"已通过"
4. 项目方查看结果，认为合理
5. 项目方调用 `setFeePercents(1, 1)` 实际执行
6. 在社区公告: "根据#5提案，我们已降低手续费"

### 场景2: 功能开发提案
1. 守护者B创建提案: "建议开发质押排行榜功能"
2. 社区投票7天，88%赞成
3. 投票结束，提案显示"已通过"
4. 项目方评估技术和成本
5. 决定在下个版本实现
6. 在社区公告: "感谢#6提案，该功能将在v2.0实现"

---

## 🔐 安全性

- ✅ 无法执行任何危险操作
- ✅ 无法转移资金
- ✅ 无法修改合约参数
- ✅ 完全由项目方控制实际执行

---

## 总结

这是一个**社区意见收集系统**，而不是传统的链上自治DAO。它在保持项目中心化控制的同时，提供了社区参与和表达的渠道，是一个很好的平衡方案。
