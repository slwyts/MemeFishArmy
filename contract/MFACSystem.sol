// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ============================================
// NFT 合约接口 (仅用于调用外部 NFT 合约)
// 注意: 这个接口不需要部署，只用于 MFACSystem 调用老的 NFT 合约
// ============================================
interface IMemeFishNFT {
    function addToWhitelist(address user) external;
    function removeFromWhitelist(address user) external;
    function whitelist(address user) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function AIRDROP_SUPPLY() external view returns (uint256);
    function MAX_TOKEN_ID() external view returns (uint256);
    function setRoyalty(uint96 royaltyFraction) external;
    function owner() external view returns (address);
}

/**
 * @title MFACSystem
 * @dev 整合 MFAC 代币、NFT 管理、空投、质押、分红、DAO 等所有功能
 * 总供应量: 10亿 MFAC
 * 支持的功能:
 * - MFAC 代币 (带交易手续费)
 * - NFT 预售与白名单管理
 * - 空投系统 (100天线性释放)
 * - 质押挖矿 (时间权重加成)
 * - 分红系统
 * - DAO 治理与国库
 * - 推荐系统 (Super Builder)
 */
contract MFACSystem is ERC20, Ownable, ReentrancyGuard {
    
    // ============================================
    // 状态变量 - 基础配置
    // ============================================
    
    IMemeFishNFT public nftContract;
    
    // 代币总量相关
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 10亿
    
    // 交易手续费
    uint256 public buyFeePercent = 1;  // 买入手续费 1%
    uint256 public sellFeePercent = 2; // 卖出手续费 2%
    bool public feesEnabled = true;
    
    // 手续费分配比例 (总计100%)
    uint256 public feeToCirculatingNFT = 30; // 流通NFT持有者 30%
    uint256 public feeToSBTNFT = 20;         // SBT NFT持有者 20%
    uint256 public feeToDAO = 50;            // DAO国库 50%
    
    // 免手续费地址
    mapping(address => bool) public isExcludedFromFee;
    
    // DEX 配置 (用于判断买卖方向)
    mapping(address => bool) public isDEXPair;
    
    // ============================================
    // 状态变量 - NFT 预售
    // ============================================
    
    uint256 public constant SBT_NFT_COUNT = 4500;
    uint256 public constant CIRCULATING_NFT_COUNT = 500;
    uint256 public nftPrice = 1 ether; // 1 BNB per NFT
    uint256 public nftsSold = 0;
    bool public presaleActive = true;
    
    // NFT 预售收入的 5% 进入 DAO 国库
    uint256 public presaleDaoPercent = 5;
    
    // ============================================
    // 状态变量 - 空投系统
    // ============================================
    
    uint256 public constant AIRDROP_DURATION = 100 days;
    uint256 public constant AIRDROP_PER_NFT_PER_DAY = 1000 * 10**18; // 1000 MFAC/天
    uint256 public constant SBT_AIRDROP_POOL = 450_000_000 * 10**18; // 4.5亿
    uint256 public constant CIRCULATING_AIRDROP_POOL = 50_000_000 * 10**18; // 5000万
    
    uint256 public airdropStartTime;
    bool public airdropStarted = false;
    
    // tokenId => day => claimed
    mapping(uint256 => mapping(uint256 => bool)) public airdropClaimed;
    
    // tokenId 的历史持有者 (防止转移后重复领取)
    mapping(uint256 => mapping(address => bool)) public hasOwnedToken;
    
    // ============================================
    // 状态变量 - 质押系统
    // ============================================
    
    uint256 public constant STAKING_POOL = 50_000_000 * 10**18; // 5000万
    uint256 public constant BASE_DAILY_REWARD = 500 * 10**18; // 500 MFAC/天
    uint256 public constant WEIGHT_MULTIPLIER = 110; // 1.1倍 = 110/100
    uint256 public constant WEIGHT_PERIOD = 30 days;
    
    uint256 public stakingPoolRemaining = STAKING_POOL;
    
    struct StakeInfo {
        uint256 tokenId;
        uint256 startTime;
        uint256 lastClaimTime;
    }
    
    // user => StakeInfo[]
    mapping(address => StakeInfo[]) public userStakes;
    
    // tokenId => isStaked
    mapping(uint256 => bool) public isTokenStaked;
    
    // tokenId => staker address
    mapping(uint256 => address) public tokenStaker;
    
    // 质押排名 (用于 DAO 守护者资格)
    address[] public stakingRanking;
    
    // ============================================
    // 状态变量 - 分红系统
    // ============================================
    
    // 代币手续费分红池 (MFAC 代币)
    uint256 public circulatingNFTDividendPool;  // 流通NFT代币分红
    uint256 public sbtNFTDividendPool;          // SBT代币分红
    
    // NFT 版税分红池 (BNB)
    uint256 public nftRoyaltyPool;              // NFT版税总池
    uint256 public totalNFTRoyaltyReceived;     // 历史累计版税收入
    
    // user => lastClaimedDividend
    mapping(address => uint256) public lastClaimedDividendCirculating;
    mapping(address => uint256) public lastClaimedDividendSBT;
    mapping(address => uint256) public lastClaimedRoyalty; // BNB版税领取记录
    
    uint256 public totalDividendCirculating;
    uint256 public totalDividendSBT;
    
    // NFT 版税分配比例
    uint256 public constant ROYALTY_TO_CIRCULATING = 50; // 50% 给流通NFT持有者
    uint256 public constant ROYALTY_TO_DAO = 50;         // 50% 进入DAO国库
    
    // ============================================
    // 状态变量 - DAO 国库
    // ============================================
    
    uint256 public daoTreasury;        // DAO国库 (BNB + 代币手续费)
    uint256 public constant PROPOSAL_THRESHOLD = 100 ether; // 100 BNB
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 amount;
        address target;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool executed;
        bool exists;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    uint256 public constant VOTING_DURATION = 7 days;
    uint256 public constant GUARDIAN_COUNT = 50;
    
    // ============================================
    // 状态变量 - 推荐系统 (Super Builder)
    // ============================================
    
    uint256 public constant SUPER_BUILDER_POOL = 140_000_000 * 10**18; // 1.4亿
    uint256 public superBuilderPoolRemaining = SUPER_BUILDER_POOL;
    
    uint256 public constant DIRECT_REFERRAL_REQUIREMENT = 5;
    uint256 public constant COMMUNITY_SALES_REQUIREMENT = 30;
    
    struct ReferralInfo {
        address referrer;
        uint256 directSales;
        uint256 communitySales;
        bool qualifiedForBuilder;
        uint256 rewardClaimed;
    }
    
    mapping(address => ReferralInfo) public referrals;
    mapping(address => address[]) public directReferrals;
    
    address[] public superBuilders;
    uint256 public currentBuilderPhase = 1; // 分3期
    
    // ============================================
    // 状态变量 - 代币分配地址
    // ============================================
    
    address public projectWallet;      // 项目方钱包 (营销+俱乐部+团队+Alpha板块 = 11%)
    address public foundationWallet;   // 基金会钱包 (10%)
    address public liquidityPool;      // 流动性池 (Alpha底池 10%)
    
    // ============================================
    // 事件
    // ============================================
    
    event NFTPurchased(address indexed buyer, uint256 amount, address indexed referrer);
    event AirdropClaimed(address indexed user, uint256 tokenId, uint256 day, uint256 amount);
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId, uint256 reward);
    event StakingRewardClaimed(address indexed user, uint256 amount);
    event DividendClaimed(address indexed user, uint256 amountCirculating, uint256 amountSBT);
    event NFTRoyaltyReceived(uint256 amount, uint256 toCirculating, uint256 toDAO);
    event NFTRoyaltyClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FeeCollected(uint256 amount, uint256 toCirculating, uint256 toSBT, uint256 toDAO);
    event SuperBuilderQualified(address indexed builder);
    event SuperBuilderRewardClaimed(address indexed builder, uint256 amount);
    
    // ============================================
    // 构造函数
    // ============================================
    
    constructor(
        address _nftContract,
        address _projectWallet,
        address _foundationWallet,
        address _liquidityPool
    ) ERC20("Meme Fish Army Coin", "MFAC") Ownable(msg.sender) {
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_projectWallet != address(0), "Invalid project wallet");
        require(_foundationWallet != address(0), "Invalid foundation wallet");
        require(_liquidityPool != address(0), "Invalid liquidity pool");
        
        nftContract = IMemeFishNFT(_nftContract);
        
        projectWallet = _projectWallet;
        foundationWallet = _foundationWallet;
        liquidityPool = _liquidityPool;
        
        // 铸造总量
        _mint(address(this), TOTAL_SUPPLY);
        
        // 分配代币
        _distributeTokens();
        
        // 排除手续费
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[_liquidityPool] = true;
        isExcludedFromFee[_projectWallet] = true;
    }
    
    // ============================================
    // 代币分配
    // ============================================
    
    function _distributeTokens() private {
        // 流动性池 (Alpha底池) 10% = 1亿
        _transfer(address(this), liquidityPool, 100_000_000 * 10**18);
        
        // 项目方钱包 11% = 1.1亿
        // 包含: Alpha板块8% + 营销1% + 俱乐部1% + 团队1%
        _transfer(address(this), projectWallet, 110_000_000 * 10**18);
        
        // 基金会 10% = 1亿
        _transfer(address(this), foundationWallet, 100_000_000 * 10**18);
        
        // 剩余 69% = 6.9亿 留在合约中:
        // - SBT 空投池: 45% (4.5亿)
        // - 流通 NFT 空投池: 5% (5000万)
        // - 质押池: 5% (5000万)
        // - Super Builder 池: 14% (1.4亿)
    }
    
    // ============================================
    // ERC20 重写 - 交易手续费
    // ============================================
    
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // 如果是免手续费地址或合约内部转账，直接执行
        if (!feesEnabled || 
            isExcludedFromFee[from] || 
            isExcludedFromFee[to] ||
            from == address(0) ||
            to == address(0)) {
            super._update(from, to, amount);
            return;
        }
        
        uint256 feeAmount = 0;
        
        // 判断是买入还是卖出
        if (isDEXPair[from]) {
            // 买入
            feeAmount = (amount * buyFeePercent) / 100;
        } else if (isDEXPair[to]) {
            // 卖出
            feeAmount = (amount * sellFeePercent) / 100;
        }
        
        if (feeAmount > 0) {
            uint256 amountAfterFee = amount - feeAmount;
            
            // 收取手续费到合约
            super._update(from, address(this), feeAmount);
            
            // 分配手续费
            _distributeFee(feeAmount);
            
            // 转账扣除手续费后的金额
            super._update(from, to, amountAfterFee);
            
            emit FeeCollected(
                feeAmount,
                (feeAmount * feeToCirculatingNFT) / 100,
                (feeAmount * feeToSBTNFT) / 100,
                (feeAmount * feeToDAO) / 100
            );
        } else {
            super._update(from, to, amount);
        }
    }
    
    function _distributeFee(uint256 feeAmount) private {
        uint256 toCirculating = (feeAmount * feeToCirculatingNFT) / 100;
        uint256 toSBT = (feeAmount * feeToSBTNFT) / 100;
        uint256 toDAO = (feeAmount * feeToDAO) / 100;
        
        circulatingNFTDividendPool += toCirculating;
        sbtNFTDividendPool += toSBT;
        daoTreasury += toDAO;
        
        totalDividendCirculating += toCirculating;
        totalDividendSBT += toSBT;
    }
    
    // ============================================
    // NFT 预售功能
    // ============================================
    
    function purchaseNFT(address referrer) external payable nonReentrant {
        require(presaleActive, "Presale not active");
        require(msg.value == nftPrice, "Incorrect BNB amount");
        require(nftsSold < SBT_NFT_COUNT, "All NFTs sold");
        
        // 添加到白名单
        nftContract.addToWhitelist(msg.sender);
        
        nftsSold++;
        
        // 5% 进入 DAO 国库
        uint256 daoAmount = (msg.value * presaleDaoPercent) / 100;
        daoTreasury += daoAmount;
        
        // 处理推荐关系
        if (referrer != address(0) && referrer != msg.sender) {
            if (referrals[msg.sender].referrer == address(0)) {
                referrals[msg.sender].referrer = referrer;
                directReferrals[referrer].push(msg.sender);
                
                // 更新推荐人统计
                referrals[referrer].directSales++;
                referrals[referrer].communitySales++;
                
                // 向上追溯更新社区销售
                address currentReferrer = referrals[referrer].referrer;
                while (currentReferrer != address(0)) {
                    referrals[currentReferrer].communitySales++;
                    currentReferrer = referrals[currentReferrer].referrer;
                }
                
                // 检查是否满足 Super Builder 条件
                _checkSuperBuilderQualification(referrer);
            }
        }
        
        emit NFTPurchased(msg.sender, msg.value, referrer);
    }
    
    function _checkSuperBuilderQualification(address user) private {
        ReferralInfo storage info = referrals[user];
        
        if (!info.qualifiedForBuilder &&
            info.directSales >= DIRECT_REFERRAL_REQUIREMENT &&
            info.communitySales >= COMMUNITY_SALES_REQUIREMENT) {
            
            info.qualifiedForBuilder = true;
            superBuilders.push(user);
            emit SuperBuilderQualified(user);
        }
    }
    
    function setPresaleActive(bool _active) external onlyOwner {
        presaleActive = _active;
    }
    
    function setNFTPrice(uint256 _price) external onlyOwner {
        nftPrice = _price;
    }
    
    // ============================================
    // 空投系统
    // ============================================
    
    function startAirdrop() external onlyOwner {
        require(!airdropStarted, "Airdrop already started");
        airdropStarted = true;
        airdropStartTime = block.timestamp;
    }
    
    function claimAirdrop(uint256[] calldata tokenIds) external nonReentrant {
        require(airdropStarted, "Airdrop not started");
        require(block.timestamp < airdropStartTime + AIRDROP_DURATION, "Airdrop ended");
        
        uint256 currentDay = (block.timestamp - airdropStartTime) / 1 days;
        uint256 totalClaim = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // 检查用户是否持有该 NFT
            require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not NFT owner");
            
            // 检查该 tokenId 今天是否已领取
            require(!airdropClaimed[tokenId][currentDay], "Already claimed today");
            
            // 检查是否是历史持有者 (防止转移后重复领取)
            require(!hasOwnedToken[tokenId][msg.sender] || 
                    nftContract.balanceOf(msg.sender, tokenId) > 0, 
                    "Token transferred");
            
            // 标记领取
            airdropClaimed[tokenId][currentDay] = true;
            hasOwnedToken[tokenId][msg.sender] = true;
            
            totalClaim += AIRDROP_PER_NFT_PER_DAY;
        }
        
        require(totalClaim > 0, "Nothing to claim");
        
        // 转账
        _transfer(address(this), msg.sender, totalClaim);
        
        emit AirdropClaimed(msg.sender, tokenIds[0], currentDay, totalClaim);
    }
    
    function getClaimableAirdrop(address user, uint256[] calldata tokenIds) 
        external 
        view 
        returns (uint256) 
    {
        if (!airdropStarted || block.timestamp >= airdropStartTime + AIRDROP_DURATION) {
            return 0;
        }
        
        uint256 currentDay = (block.timestamp - airdropStartTime) / 1 days;
        uint256 claimable = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            if (nftContract.balanceOf(user, tokenId) > 0 &&
                !airdropClaimed[tokenId][currentDay] &&
                !hasOwnedToken[tokenId][user]) {
                claimable += AIRDROP_PER_NFT_PER_DAY;
            }
        }
        
        return claimable;
    }
    
    // ============================================
    // 质押系统
    // ============================================
    
    function stake(uint256 tokenId) external nonReentrant {
        // 只有流通 NFT (501-5000) 可以质押
        require(tokenId > nftContract.AIRDROP_SUPPLY(), "Only circulating NFTs can be staked");
        require(tokenId <= nftContract.MAX_TOKEN_ID(), "Invalid token ID");
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not NFT owner");
        require(!isTokenStaked[tokenId], "Already staked");
        
        // 标记质押
        isTokenStaked[tokenId] = true;
        tokenStaker[tokenId] = msg.sender;
        
        // 记录质押信息
        userStakes[msg.sender].push(StakeInfo({
            tokenId: tokenId,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp
        }));
        
        // 更新排名
        _updateStakingRanking(msg.sender);
        
        emit Staked(msg.sender, tokenId);
    }
    
    function unstake(uint256 tokenId) external nonReentrant {
        require(isTokenStaked[tokenId], "Not staked");
        require(tokenStaker[tokenId] == msg.sender, "Not your stake");
        
        // 计算并发放奖励
        uint256 reward = _calculateStakingReward(msg.sender, tokenId);
        
        // 移除质押信息
        _removeStake(msg.sender, tokenId);
        
        isTokenStaked[tokenId] = false;
        delete tokenStaker[tokenId];
        
        // 更新排名
        _updateStakingRanking(msg.sender);
        
        // 发放奖励
        if (reward > 0 && stakingPoolRemaining >= reward) {
            stakingPoolRemaining -= reward;
            _transfer(address(this), msg.sender, reward);
        }
        
        emit Unstaked(msg.sender, tokenId, reward);
    }
    
    function claimStakingReward() external nonReentrant {
        uint256 totalReward = 0;
        
        StakeInfo[] storage stakes = userStakes[msg.sender];
        
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 reward = _calculateStakingRewardForStake(stakes[i]);
            totalReward += reward;
            stakes[i].lastClaimTime = block.timestamp;
        }
        
        require(totalReward > 0, "No reward to claim");
        require(stakingPoolRemaining >= totalReward, "Insufficient pool");
        
        stakingPoolRemaining -= totalReward;
        _transfer(address(this), msg.sender, totalReward);
        
        emit StakingRewardClaimed(msg.sender, totalReward);
    }
    
    function _calculateStakingReward(address user, uint256 tokenId) 
        private 
        view 
        returns (uint256) 
    {
        StakeInfo[] storage stakes = userStakes[user];
        
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].tokenId == tokenId) {
                return _calculateStakingRewardForStake(stakes[i]);
            }
        }
        
        return 0;
    }
    
    function _calculateStakingRewardForStake(StakeInfo memory stakeInfo) 
        private 
        view 
        returns (uint256) 
    {
        uint256 stakingDuration = block.timestamp - stakeInfo.lastClaimTime;
        uint256 totalStakingTime = block.timestamp - stakeInfo.startTime;
        
        // 计算权重 (每30天 * 1.1)
        uint256 periods = totalStakingTime / WEIGHT_PERIOD;
        uint256 weight = 100; // 初始权重 100%
        
        for (uint256 i = 0; i < periods; i++) {
            weight = (weight * WEIGHT_MULTIPLIER) / 100;
        }
        
        // 计算奖励
        uint256 dayCount = stakingDuration / 1 days;
        uint256 reward = (BASE_DAILY_REWARD * dayCount * weight) / 100;
        
        return reward;
    }
    
    function _removeStake(address user, uint256 tokenId) private {
        StakeInfo[] storage stakes = userStakes[user];
        
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].tokenId == tokenId) {
                stakes[i] = stakes[stakes.length - 1];
                stakes.pop();
                break;
            }
        }
    }
    
    function _updateStakingRanking(address user) private {
        // 简化版排名更新
        // 实际应该按质押时长排序
        bool exists = false;
        for (uint256 i = 0; i < stakingRanking.length; i++) {
            if (stakingRanking[i] == user) {
                exists = true;
                break;
            }
        }
        
        if (!exists && userStakes[user].length > 0) {
            stakingRanking.push(user);
        } else if (exists && userStakes[user].length == 0) {
            for (uint256 i = 0; i < stakingRanking.length; i++) {
                if (stakingRanking[i] == user) {
                    stakingRanking[i] = stakingRanking[stakingRanking.length - 1];
                    stakingRanking.pop();
                    break;
                }
            }
        }
    }
    
    function getUserStakes(address user) external view returns (StakeInfo[] memory) {
        return userStakes[user];
    }
    
    function getStakingRanking() external view returns (address[] memory) {
        return stakingRanking;
    }
    
    // ============================================
    // 分红系统
    // ============================================
    
    function claimDividend() external nonReentrant {
        uint256 circulatingAmount = 0;
        uint256 sbtAmount = 0;
        
        // 计算流通 NFT 分红 (tokenId 501-5000)
        uint256 circulatingBalance = 0;
        for (uint256 i = nftContract.AIRDROP_SUPPLY() + 1; i <= nftContract.MAX_TOKEN_ID(); i++) {
            if (nftContract.balanceOf(msg.sender, i) > 0) {
                circulatingBalance++;
            }
        }
        
        if (circulatingBalance > 0) {
            uint256 perNFT = circulatingNFTDividendPool / CIRCULATING_NFT_COUNT;
            circulatingAmount = perNFT * circulatingBalance;
        }
        
        // 计算 SBT NFT 分红 (tokenId 1-500)
        uint256 sbtBalance = 0;
        for (uint256 i = 1; i <= nftContract.AIRDROP_SUPPLY(); i++) {
            if (nftContract.balanceOf(msg.sender, i) > 0) {
                sbtBalance++;
            }
        }
        
        if (sbtBalance > 0) {
            uint256 perNFT = sbtNFTDividendPool / SBT_NFT_COUNT;
            sbtAmount = perNFT * sbtBalance;
        }
        
        uint256 totalClaim = circulatingAmount + sbtAmount;
        require(totalClaim > 0, "No dividend to claim");
        
        // 扣除分红池
        if (circulatingAmount > 0) {
            circulatingNFTDividendPool -= circulatingAmount;
        }
        if (sbtAmount > 0) {
            sbtNFTDividendPool -= sbtAmount;
        }
        
        // 转账
        _transfer(address(this), msg.sender, totalClaim);
        
        emit DividendClaimed(msg.sender, circulatingAmount, sbtAmount);
    }
    
    function getDividendBalance(address user) 
        external 
        view 
        returns (uint256 circulatingAmount, uint256 sbtAmount) 
    {
        // 计算流通 NFT 分红
        uint256 circulatingBalance = 0;
        for (uint256 i = nftContract.AIRDROP_SUPPLY() + 1; i <= nftContract.MAX_TOKEN_ID(); i++) {
            if (nftContract.balanceOf(user, i) > 0) {
                circulatingBalance++;
            }
        }
        
        if (circulatingBalance > 0 && CIRCULATING_NFT_COUNT > 0) {
            uint256 perNFT = circulatingNFTDividendPool / CIRCULATING_NFT_COUNT;
            circulatingAmount = perNFT * circulatingBalance;
        }
        
        // 计算 SBT NFT 分红
        uint256 sbtBalance = 0;
        for (uint256 i = 1; i <= nftContract.AIRDROP_SUPPLY(); i++) {
            if (nftContract.balanceOf(user, i) > 0) {
                sbtBalance++;
            }
        }
        
        if (sbtBalance > 0 && SBT_NFT_COUNT > 0) {
            uint256 perNFT = sbtNFTDividendPool / SBT_NFT_COUNT;
            sbtAmount = perNFT * sbtBalance;
        }
        
        return (circulatingAmount, sbtAmount);
    }
    
    // ============================================
    // DAO 治理系统
    // ============================================
    
    function createProposal(
        string memory description,
        uint256 amount,
        address target
    ) external nonReentrant returns (uint256) {
        require(daoTreasury >= PROPOSAL_THRESHOLD, "Treasury below threshold");
        require(_isGuardian(msg.sender), "Not a guardian");
        
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: description,
            amount: amount,
            target: target,
            yesVotes: 0,
            noVotes: 0,
            endTime: block.timestamp + VOTING_DURATION,
            executed: false,
            exists: true
        });
        
        emit ProposalCreated(proposalCount, msg.sender, description);
        
        return proposalCount;
    }
    
    function vote(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(block.timestamp < proposal.endTime, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(_isVoter(msg.sender), "Not a voter");
        
        hasVoted[proposalId][msg.sender] = true;
        
        // 投票权重：持有的 NFT 数量
        uint256 votingPower = _getVotingPower(msg.sender);
        
        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        
        emit Voted(proposalId, msg.sender, support);
    }
    
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(proposal.yesVotes > proposal.noVotes, "Proposal rejected");
        
        proposal.executed = true;
        
        // 执行提案 (转账到目标地址)
        if (proposal.amount > 0 && proposal.target != address(0)) {
            require(daoTreasury >= proposal.amount, "Insufficient treasury");
            daoTreasury -= proposal.amount;
            payable(proposal.target).transfer(proposal.amount);
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    function _isGuardian(address user) private view returns (bool) {
        // 守护者：质押排名前50
        if (stakingRanking.length < GUARDIAN_COUNT) {
            for (uint256 i = 0; i < stakingRanking.length; i++) {
                if (stakingRanking[i] == user) {
                    return true;
                }
            }
            return false;
        }
        
        for (uint256 i = 0; i < GUARDIAN_COUNT; i++) {
            if (stakingRanking[i] == user) {
                return true;
            }
        }
        
        return false;
    }
    
    function _isVoter(address user) private view returns (bool) {
        // 选民：所有 NFT 持有者
        for (uint256 i = 1; i <= nftContract.MAX_TOKEN_ID(); i++) {
            if (nftContract.balanceOf(user, i) > 0) {
                return true;
            }
        }
        return false;
    }
    
    function _getVotingPower(address user) private view returns (uint256) {
        uint256 power = 0;
        for (uint256 i = 1; i <= nftContract.MAX_TOKEN_ID(); i++) {
            power += nftContract.balanceOf(user, i);
        }
        return power;
    }
    
    function isGuardian(address user) external view returns (bool) {
        return _isGuardian(user);
    }
    
    function isVoter(address user) external view returns (bool) {
        return _isVoter(user);
    }
    
    // ============================================
    // Super Builder 系统
    // ============================================
    
    function claimSuperBuilderReward() external nonReentrant {
        ReferralInfo storage info = referrals[msg.sender];
        require(info.qualifiedForBuilder, "Not qualified");
        require(superBuilderPoolRemaining > 0, "Pool empty");
        
        // 计算本期应得奖励
        uint256 reward = _calculateBuilderReward(msg.sender);
        require(reward > info.rewardClaimed, "No new reward");
        
        uint256 toClaim = reward - info.rewardClaimed;
        require(superBuilderPoolRemaining >= toClaim, "Insufficient pool");
        
        info.rewardClaimed = reward;
        superBuilderPoolRemaining -= toClaim;
        
        _transfer(address(this), msg.sender, toClaim);
        
        emit SuperBuilderRewardClaimed(msg.sender, toClaim);
    }
    
    function _calculateBuilderReward(address user) private view returns (uint256) {
        // 简化版：按贡献度加权分配
        // 实际应该根据直推数和社区销售数计算权重
        ReferralInfo storage info = referrals[user];
        
        if (!info.qualifiedForBuilder) {
            return 0;
        }
        
        // 每期奖励池 = 总池 / 3
        uint256 phasePool = SUPER_BUILDER_POOL / 3;
        
        // 按社区销售数加权
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < superBuilders.length; i++) {
            totalWeight += referrals[superBuilders[i]].communitySales;
        }
        
        if (totalWeight == 0) return 0;
        
        uint256 userWeight = info.communitySales;
        uint256 reward = (phasePool * userWeight) / totalWeight;
        
        return reward;
    }
    
    function getReferralInfo(address user) 
        external 
        view 
        returns (
            address referrer,
            uint256 directSales,
            uint256 communitySales,
            bool qualified,
            uint256 claimed
        ) 
    {
        ReferralInfo storage info = referrals[user];
        return (
            info.referrer,
            info.directSales,
            info.communitySales,
            info.qualifiedForBuilder,
            info.rewardClaimed
        );
    }
    
    function getDirectReferrals(address user) external view returns (address[] memory) {
        return directReferrals[user];
    }
    
    function getSuperBuilders() external view returns (address[] memory) {
        return superBuilders;
    }
    
    // ============================================
    // 管理员函数
    // ============================================
    
    function setDEXPair(address pair, bool isPair) external onlyOwner {
        isDEXPair[pair] = isPair;
    }
    
    function setExcludedFromFee(address account, bool excluded) external onlyOwner {
        isExcludedFromFee[account] = excluded;
    }
    
    function setFeePercents(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 10 && _sellFee <= 10, "Fee too high");
        buyFeePercent = _buyFee;
        sellFeePercent = _sellFee;
    }
    
    function setFeesEnabled(bool _enabled) external onlyOwner {
        feesEnabled = _enabled;
    }
    
    function setFeeDistribution(
        uint256 _circulating,
        uint256 _sbt,
        uint256 _dao
    ) external onlyOwner {
        require(_circulating + _sbt + _dao == 100, "Must equal 100");
        feeToCirculatingNFT = _circulating;
        feeToSBTNFT = _sbt;
        feeToDAO = _dao;
    }
    
    function setBuilderPhase(uint256 _phase) external onlyOwner {
        require(_phase >= 1 && _phase <= 3, "Invalid phase");
        currentBuilderPhase = _phase;
    }
    
    /**
     * @dev 设置老 NFT 合约的版税接收者为本合约
     * 
     * ⚠️ 重要步骤（必须按顺序执行）:
     * 1. 先在老 NFT 合约调用 transferOwnership(MFACSystem合约地址)
     * 2. 再调用本函数，触发版税接收者更新
     * 3. 之后 NFT 在交易市场（如 OpenSea）的版税收入会自动打到本合约
     * 
     * 原理: 老合约的 setRoyalty 内部会调用 _setDefaultRoyalty(owner(), royaltyFraction)
     *      此时 owner() 已经是本合约地址，所以版税接收者会自动设为本合约
     */
    function setNFTRoyaltyReceiver() external onlyOwner {
        // 确认本合约已是老 NFT 合约的 owner
        require(nftContract.owner() == address(this), "MFACSystem must be NFT contract owner first");
        
        // 调用老 NFT 合约的 setRoyalty(500) - 保持 5% 版税比例
        // 由于本合约已是老合约的 owner，版税接收者会自动设为本合约地址
        nftContract.setRoyalty(500);
    }
    
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance - daoTreasury;
        payable(owner()).transfer(balance);
    }
    
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // ============================================
    // 白名单管理 (代理 NFT 合约)
    // ============================================
    
    function addToWhitelist(address user) external onlyOwner {
        nftContract.addToWhitelist(user);
    }
    
    function removeFromWhitelist(address user) external onlyOwner {
        nftContract.removeFromWhitelist(user);
    }
    
    // ============================================
    // 查询函数
    // ============================================
    
    function getContractStats() 
        external 
        view 
        returns (
            uint256 _nftsSold,
            uint256 _airdropStartTime,
            uint256 _stakingPoolRemaining,
            uint256 _circulatingDividendPool,
            uint256 _sbtDividendPool,
            uint256 _daoTreasury,
            uint256 _superBuilderPoolRemaining,
            uint256 _nftRoyaltyPool,
            uint256 _totalNFTRoyaltyReceived
        ) 
    {
        return (
            nftsSold,
            airdropStartTime,
            stakingPoolRemaining,
            circulatingNFTDividendPool,
            sbtNFTDividendPool,
            daoTreasury,
            superBuilderPoolRemaining,
            nftRoyaltyPool,
            totalNFTRoyaltyReceived
        );
    }
    
    // ============================================
    // NFT 版税收入处理
    // ============================================
    
    /**
     * @dev 接收 NFT 版税收入（BNB）
     * 当 NFT 在交易市场（如 OpenSea）交易时，5% 版税会自动打到本合约
     * 自动分配：50% 给流通NFT持有者，50% 进入DAO国库
     */
    receive() external payable {
        if (msg.value > 0) {
            // 分配版税收入
            uint256 toCirculating = (msg.value * ROYALTY_TO_CIRCULATING) / 100;
            uint256 toDAO = msg.value - toCirculating; // 确保没有舍入损失
            
            // 更新版税池
            nftRoyaltyPool += toCirculating;
            totalNFTRoyaltyReceived += msg.value;
            
            // 更新 DAO 国库
            daoTreasury += toDAO;
            
            emit NFTRoyaltyReceived(msg.value, toCirculating, toDAO);
        }
    }
    
    /**
     * @dev 流通 NFT 持有者领取 BNB 版税分红
     * 只有持有流通NFT（tokenId > 500）的用户可以领取
     * 按持有NFT数量平均分配
     */
    function claimNFTRoyalty() external nonReentrant {
        require(nftRoyaltyPool > 0, "No royalty to claim");
        
        // 统计用户持有的流通NFT数量
        uint256 circulatingBalance = 0;
        uint256 maxTokenId = nftContract.MAX_TOKEN_ID();
        uint256 airdropSupply = nftContract.AIRDROP_SUPPLY();
        
        for (uint256 i = airdropSupply + 1; i <= maxTokenId; i++) {
            if (nftContract.balanceOf(msg.sender, i) > 0) {
                circulatingBalance++;
            }
        }
        
        require(circulatingBalance > 0, "No circulating NFT");
        
        // 计算可领取金额
        // 版税按流通NFT总数平均分配
        uint256 totalCirculatingNFT = CIRCULATING_NFT_COUNT;
        uint256 perNFT = nftRoyaltyPool / totalCirculatingNFT;
        uint256 claimAmount = perNFT * circulatingBalance;
        
        require(claimAmount > 0, "Nothing to claim");
        require(claimAmount <= nftRoyaltyPool, "Insufficient pool");
        
        // 更新池余额
        nftRoyaltyPool -= claimAmount;
        lastClaimedRoyalty[msg.sender] = block.timestamp;
        
        // 转账 BNB
        payable(msg.sender).transfer(claimAmount);
        
        emit NFTRoyaltyClaimed(msg.sender, claimAmount);
    }
    
    /**
     * @dev 查询用户可领取的 NFT 版税金额
     */
    function getPendingNFTRoyalty(address user) external view returns (uint256) {
        if (nftRoyaltyPool == 0) return 0;
        
        // 统计用户持有的流通NFT数量
        uint256 circulatingBalance = 0;
        uint256 maxTokenId = nftContract.MAX_TOKEN_ID();
        uint256 airdropSupply = nftContract.AIRDROP_SUPPLY();
        
        for (uint256 i = airdropSupply + 1; i <= maxTokenId; i++) {
            if (nftContract.balanceOf(user, i) > 0) {
                circulatingBalance++;
            }
        }
        
        if (circulatingBalance == 0) return 0;
        
        uint256 totalCirculatingNFT = CIRCULATING_NFT_COUNT;
        uint256 perNFT = nftRoyaltyPool / totalCirculatingNFT;
        return perNFT * circulatingBalance;
    }
}

