// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IMemeFishNFT {
    function addToWhitelist(address user) external;
    function removeFromWhitelist(address user) external;
    function batchUpdateWhitelist(address[] calldata users, bool[] calldata statuses) external;
    function whitelist(address user) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function AIRDROP_SUPPLY() external view returns (uint256);
    function MAX_TOKEN_ID() external view returns (uint256);
    function setRoyalty(uint96 royaltyFraction) external;
    function setBaseURI(string memory newURI) external;
    function setMaxMintsPerUser(uint256 newLimit) external;
    function owner() external view returns (address);
    function maxMintsPerUser() external view returns (uint256);
}

contract MFACSystem is ERC20, Ownable, ReentrancyGuard {
    
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
    mapping(uint256 => mapping(uint256 => bool)) public airdropClaimed;
    mapping(uint256 => mapping(address => bool)) public hasOwnedToken;
    mapping(uint256 => uint256) public circulatingNFTClaimedDays;
    
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
    
    // 用户质押分数 (基于质押时长 * NFT数量)
    mapping(address => uint256) public stakingScore;
    
    // ============================================
    // 状态变量 - 分红系统
    // ============================================
    
    // 代币手续费分红池 (MFAC 代币)
    uint256 public circulatingNFTDividendPool;  // 流通NFT代币分红
    uint256 public sbtNFTDividendPool;          // SBT代币分红
    
    // NFT 版税分红池 (BNB)
    uint256 public nftRoyaltyPool;
    uint256 public totalNFTRoyaltyReceived;

    mapping(uint256 => uint256) public lastClaimedDividendCirculating;
    mapping(uint256 => uint256) public lastClaimedDividendSBT;
    mapping(uint256 => uint256) public lastClaimedRoyalty;
    
    uint256 public totalDividendCirculating;
    uint256 public totalDividendSBT;
    
    // NFT 版税分配比例
    uint256 public constant ROYALTY_TO_CIRCULATING = 50;
    uint256 public constant ROYALTY_TO_DAO = 50;
    uint256 public daoTreasuryBNB;
    uint256 public daoTreasuryMFAC;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;  // 提案内容（纯文字）
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool closed;
        bool exists;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    uint256 public constant VOTING_DURATION = 7 days;
    uint256 public constant GUARDIAN_COUNT = 50;
    
    uint256 public constant SUPER_BUILDER_POOL = 140_000_000 * 10**18;
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
    
    address public projectWallet;      // 项目方钱包 (营销+俱乐部+团队+Alpha板块 = 11%)
    address public foundationWallet;   // 基金会钱包 (10%)
    address public liquidityPool;      // 流动性池 (Alpha底池 10%)
    
    event NFTPurchased(address indexed buyer, uint256 amount, address indexed referrer);
    event AirdropClaimed(address indexed user, uint256 tokenId, uint256 day, uint256 amount);
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId, uint256 reward);
    event StakingRewardClaimed(address indexed user, uint256 amount);
    event DividendClaimed(address indexed user, uint256 amountCirculating, uint256 amountSBT);
    event NFTRoyaltyReceived(uint256 amount, uint256 toCirculating, uint256 toProject);
    event NFTRoyaltyClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalClosed(uint256 indexed proposalId, bool passed);
    event FeeCollected(uint256 amount, uint256 toCirculating, uint256 toSBT, uint256 toProject);
    event SuperBuilderQualified(address indexed builder);
    event SuperBuilderRewardClaimed(address indexed builder, uint256 amount);

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
        
        _mint(_liquidityPool, 100_000_000 * 10**18);
        _mint(_projectWallet, 110_000_000 * 10**18);
        _mint(_foundationWallet, 100_000_000 * 10**18);

        _mint(address(this), 690_000_000 * 10**18);
        
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[_liquidityPool] = true;
        isExcludedFromFee[_projectWallet] = true;
        isExcludedFromFee[_foundationWallet] = true;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!feesEnabled || 
            isExcludedFromFee[from] || 
            isExcludedFromFee[to] ||
            from == address(0) ||
            to == address(0)) {
            super._update(from, to, amount);
            return;
        }
        uint256 feeAmount = 0;
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
        uint256 toProject = (feeAmount * feeToDAO) / 100;
        
        circulatingNFTDividendPool += toCirculating;
        sbtNFTDividendPool += toSBT;
        
        // 项目方份额直接转账
        _transfer(address(this), projectWallet, toProject);
        
        // 统计（用于前端展示）
        daoTreasuryMFAC += toProject;
        
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
        
        // 5% 直接转给项目方钱包 (BNB)
        uint256 projectAmount = (msg.value * presaleDaoPercent) / 100;
        payable(projectWallet).transfer(projectAmount);
        
        // 统计（用于前端展示）
        daoTreasuryBNB += projectAmount;
        
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
        uint256 maxDays = AIRDROP_DURATION / 1 days; // 100天
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not NFT owner");
            if (tokenId <= nftContract.AIRDROP_SUPPLY()) {
                require(circulatingNFTClaimedDays[tokenId] < maxDays, "Max claims reached for this NFT");
                require(!airdropClaimed[tokenId][currentDay], "Already claimed today");
                airdropClaimed[tokenId][currentDay] = true;
                circulatingNFTClaimedDays[tokenId]++;
            } else {
                require(!airdropClaimed[tokenId][currentDay], "Already claimed today");
                hasOwnedToken[tokenId][msg.sender] = true;
                airdropClaimed[tokenId][currentDay] = true;
            }
            
            totalClaim += AIRDROP_PER_NFT_PER_DAY;
        }
        
        require(totalClaim > 0, "Nothing to claim");
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
        uint256 maxDays = AIRDROP_DURATION / 1 days;
        uint256 claimable = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            if (nftContract.balanceOf(user, tokenId) > 0 &&
                !airdropClaimed[tokenId][currentDay]) {
                
                // 流通NFT额外检查已领取天数
                if (tokenId <= nftContract.AIRDROP_SUPPLY()) {
                    if (circulatingNFTClaimedDays[tokenId] < maxDays) {
                        claimable += AIRDROP_PER_NFT_PER_DAY;
                    }
                } else {
                    // SBT直接可领取
                    claimable += AIRDROP_PER_NFT_PER_DAY;
                }
            }
        }
        
        return claimable;
    }
    

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
    
    /**
     * @dev 更新质押排名（基于质押分数）
     * 质押分数 = Σ(质押时长 * 权重)
     * 使用快速排序算法实时维护排名（降序）
     */
    function _updateStakingRanking(address user) private {
        // 计算用户的质押分数
        uint256 score = _calculateStakingScore(user);
        stakingScore[user] = score;

        // 更新排名列表
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
            // 移除用户
            for (uint256 i = 0; i < stakingRanking.length; i++) {
                if (stakingRanking[i] == user) {
                    stakingRanking[i] = stakingRanking[stakingRanking.length - 1];
                    stakingRanking.pop();
                    break;
                }
            }
        }

        // 使用快速排序按分数降序排序
        if (stakingRanking.length > 1) {
            _quickSort(0, stakingRanking.length - 1);
        }
    }
    
    /**
     * @dev 快速排序算法（降序）
     * @param left 左边界索引
     * @param right 右边界索引
     */
    function _quickSort(uint256 left, uint256 right) private {
        if (left >= right) return;
        
        uint256 i = left;
        uint256 j = right;
        address pivot = stakingRanking[left + (right - left) / 2];
        uint256 pivotScore = stakingScore[pivot];
        
        while (i <= j) {
            // 降序排序：找到左边小于pivot的
            while (stakingScore[stakingRanking[i]] > pivotScore) {
                i++;
            }
            // 降序排序：找到右边大于pivot的
            while (stakingScore[stakingRanking[j]] < pivotScore) {
                if (j == 0) break;
                j--;
            }
            
            if (i <= j) {
                // 交换
                address temp = stakingRanking[i];
                stakingRanking[i] = stakingRanking[j];
                stakingRanking[j] = temp;
                i++;
                if (j > 0) j--;
            }
            
            // 防止无限循环
            if (j == 0 || i >= stakingRanking.length) break;
        }
        
        // 递归排序左右两部分
        if (left < j && j != 0) {
            _quickSort(left, j);
        }
        if (i < right) {
            _quickSort(i, right);
        }
    }
    
    /**
     * @dev 计算用户的质押分数
     * 分数 = Σ(质押天数 * 权重)
     */
    function _calculateStakingScore(address user) private view returns (uint256) {
        StakeInfo[] storage stakes = userStakes[user];
        if (stakes.length == 0) return 0;
        
        uint256 totalScore = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 stakingDays = (block.timestamp - stakes[i].startTime) / 1 days;
            uint256 periods = (block.timestamp - stakes[i].startTime) / WEIGHT_PERIOD;
            
            // 计算权重
            uint256 weight = 100;
            for (uint256 j = 0; j < periods && j < 10; j++) { // 限制最大10期，防止溢出
                weight = (weight * WEIGHT_MULTIPLIER) / 100;
            }
            
            totalScore += (stakingDays * weight) / 100;
        }
        
        return totalScore;
    }
    
    /**
     * @dev 获取质押排名前N名用户
     * 动态计算，不占用存储
     */
    function getTopStakers(uint256 topN) public view returns (address[] memory, uint256[] memory) {
        uint256 length = stakingRanking.length < topN ? stakingRanking.length : topN;
        address[] memory topAddresses = new address[](length);
        uint256[] memory topScores = new uint256[](length);
        
        // 简单的选择排序（仅对前topN个）
        for (uint256 i = 0; i < length; i++) {
            uint256 maxScore = 0;
            address maxAddress = address(0);
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < stakingRanking.length; j++) {
                address candidate = stakingRanking[j];
                uint256 score = _calculateStakingScore(candidate);
                
                // 检查是否已经在结果中
                bool alreadyIncluded = false;
                for (uint256 k = 0; k < i; k++) {
                    if (topAddresses[k] == candidate) {
                        alreadyIncluded = true;
                        break;
                    }
                }
                
                if (!alreadyIncluded && score > maxScore) {
                    maxScore = score;
                    maxAddress = candidate;
                    maxIndex = j;
                }
            }
            
            topAddresses[i] = maxAddress;
            topScores[i] = maxScore;
        }
        
        return (topAddresses, topScores);
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
    
    /**
     * @dev 领取代币手续费分红（优化版：用户提供持有的tokenId）
     * @param circulatingTokenIds 持有的流通NFT的tokenId数组 (1-500)
     * @param sbtTokenIds 持有的SBT的tokenId数组 (501-5000)
     */
    function claimDividend(
        uint256[] calldata circulatingTokenIds,
        uint256[] calldata sbtTokenIds
    ) external nonReentrant {
        uint256 circulatingAmount = 0;
        uint256 sbtAmount = 0;
        
        // 计算流通 NFT 分红 (tokenId 1-500)
        if (circulatingTokenIds.length > 0 && circulatingNFTDividendPool > 0) {
            uint256 validCount = 0;
            for (uint256 i = 0; i < circulatingTokenIds.length; i++) {
                uint256 tokenId = circulatingTokenIds[i];
                require(tokenId > 0 && tokenId <= nftContract.AIRDROP_SUPPLY(), "Invalid circulating tokenId");
                require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not owner of circulating NFT");
                require(lastClaimedDividendCirculating[tokenId] < totalDividendCirculating, "Already claimed");
                
                lastClaimedDividendCirculating[tokenId] = totalDividendCirculating;
                validCount++;
            }
            
            if (validCount > 0) {
                uint256 perNFT = circulatingNFTDividendPool / CIRCULATING_NFT_COUNT;
                circulatingAmount = perNFT * validCount;
            }
        }
        
        // 计算 SBT NFT 分红 (tokenId 501-5000)
        if (sbtTokenIds.length > 0 && sbtNFTDividendPool > 0) {
            uint256 validCount = 0;
            for (uint256 i = 0; i < sbtTokenIds.length; i++) {
                uint256 tokenId = sbtTokenIds[i];
                require(tokenId > nftContract.AIRDROP_SUPPLY() && tokenId <= nftContract.MAX_TOKEN_ID(), "Invalid SBT tokenId");
                require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not owner of SBT");
                require(lastClaimedDividendSBT[tokenId] < totalDividendSBT, "Already claimed");
                
                lastClaimedDividendSBT[tokenId] = totalDividendSBT;
                validCount++;
            }
            
            if (validCount > 0) {
                uint256 perNFT = sbtNFTDividendPool / SBT_NFT_COUNT;
                sbtAmount = perNFT * validCount;
            }
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
    
    /**
     * @dev 查询分红余额（优化版：用户提供持有的tokenId）
     * @param user 用户地址
     * @param circulatingTokenIds 持有的流通NFT的tokenId数组
     * @param sbtTokenIds 持有的SBT的tokenId数组
     */
    function getDividendBalance(
        address user,
        uint256[] calldata circulatingTokenIds,
        uint256[] calldata sbtTokenIds
    ) 
        external 
        view 
        returns (uint256 circulatingAmount, uint256 sbtAmount) 
    {
        // 计算流通 NFT 分红
        if (circulatingTokenIds.length > 0 && circulatingNFTDividendPool > 0) {
            uint256 validCount = 0;
            for (uint256 i = 0; i < circulatingTokenIds.length; i++) {
                uint256 tokenId = circulatingTokenIds[i];
                if (tokenId > 0 && tokenId <= nftContract.AIRDROP_SUPPLY() &&
                    nftContract.balanceOf(user, tokenId) > 0) {
                    validCount++;
                }
            }
            
            if (validCount > 0 && CIRCULATING_NFT_COUNT > 0) {
                uint256 perNFT = circulatingNFTDividendPool / CIRCULATING_NFT_COUNT;
                circulatingAmount = perNFT * validCount;
            }
        }
        
        // 计算 SBT NFT 分红
        if (sbtTokenIds.length > 0 && sbtNFTDividendPool > 0) {
            uint256 validCount = 0;
            for (uint256 i = 0; i < sbtTokenIds.length; i++) {
                uint256 tokenId = sbtTokenIds[i];
                if (tokenId > nftContract.AIRDROP_SUPPLY() && tokenId <= nftContract.MAX_TOKEN_ID() &&
                    nftContract.balanceOf(user, tokenId) > 0) {
                    validCount++;
                }
            }
            
            if (validCount > 0 && SBT_NFT_COUNT > 0) {
                uint256 perNFT = sbtNFTDividendPool / SBT_NFT_COUNT;
                sbtAmount = perNFT * validCount;
            }
        }
        
        return (circulatingAmount, sbtAmount);
    }
    
    // ============================================
    // DAO 治理系统
    // ============================================
    
    /**
     * @dev 创建提案 (仅文字内容，无实际执行权限)
     * @param description 提案描述文字
     * 注意: 提案仅用于展示社区意见，是否执行由项目方决定
     */
    function createProposal(string memory description) external nonReentrant returns (uint256) {
        require(_isGuardian(msg.sender), "Not a guardian");
        require(bytes(description).length > 0, "Empty description");
        require(bytes(description).length <= 1000, "Description too long");
        
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            endTime: block.timestamp + VOTING_DURATION,
            closed: false,
            exists: true
        });
        
        emit ProposalCreated(proposalCount, msg.sender, description);
        
        return proposalCount;
    }
    
    /**
     * @dev NFT持有者投票
     * @param proposalId 提案ID
     * @param support true=赞成，false=反对
     */
    function vote(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.closed, "Proposal closed");
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
    
    /**
     * @dev 关闭提案（仅统计结果，无实际执行）
     * @param proposalId 提案ID
     * 注意: 此函数仅关闭投票并统计结果，不执行任何链上操作
     *      是否采纳提案内容完全由项目方线下决定
     */
    function closeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.closed, "Already closed");
        
        proposal.closed = true;
        
        bool passed = proposal.yesVotes > proposal.noVotes;
        
        emit ProposalClosed(proposalId, passed);
    }
    
    function _isGuardian(address user) private view returns (bool) {
        // 守护者：质押排名前50（基于质押分数）
        if (stakingRanking.length == 0) return false;
        
        uint256 userScore = _calculateStakingScore(user);
        if (userScore == 0) return false;
        
        // 获取前50名
        (address[] memory topStakers, ) = getTopStakers(GUARDIAN_COUNT);
        
        for (uint256 i = 0; i < topStakers.length; i++) {
            if (topStakers[i] == user) {
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
    
    /**
     * @dev 获取提案详情
     */
    function getProposal(uint256 proposalId) 
        external 
        view 
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
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.endTime,
            proposal.closed,
            proposal.yesVotes > proposal.noVotes
        );
    }
    
    /**
     * @dev 获取用户在某提案的投票状态
     */
    function getUserVote(uint256 proposalId, address user) 
        external 
        view 
        returns (bool hasVoted_, uint256 votingPower) 
    {
        hasVoted_ = hasVoted[proposalId][user];
        votingPower = hasVoted_ ? _getVotingPower(user) : 0;
    }
    
    /**
     * @dev 获取提案列表（分页）
     */
    function getProposals(uint256 offset, uint256 limit) 
        external 
        view 
        returns (
            uint256[] memory ids,
            address[] memory proposers,
            uint256[] memory yesVotes_,
            uint256[] memory noVotes_,
            uint256[] memory endTimes,
            bool[] memory closed_
        ) 
    {
        uint256 total = proposalCount;
        if (offset >= total) {
            return (new uint256[](0), new address[](0), new uint256[](0), new uint256[](0), new uint256[](0), new bool[](0));
        }
        
        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }
        
        uint256 length = end - offset;
        ids = new uint256[](length);
        proposers = new address[](length);
        yesVotes_ = new uint256[](length);
        noVotes_ = new uint256[](length);
        endTimes = new uint256[](length);
        closed_ = new bool[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 proposalId = offset + i + 1;
            Proposal storage p = proposals[proposalId];
            ids[i] = p.id;
            proposers[i] = p.proposer;
            yesVotes_[i] = p.yesVotes;
            noVotes_[i] = p.noVotes;
            endTimes[i] = p.endTime;
            closed_[i] = p.closed;
        }
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
     * @dev 设置 NFT 合约的版税比例和接收者
     * 
     * ⚠️ 重要步骤（必须按顺序执行）:
     * 1. 先在老 NFT 合约调用 transferOwnership(MFACSystem合约地址)
     * 2. 再调用本函数，触发版税接收者更新
     * 3. 之后 NFT 在交易市场（如 OpenSea）的版税收入会自动打到本合约
     * 
     * 原理: 老合约的 setRoyalty 内部会调用 _setDefaultRoyalty(owner(), royaltyFraction)
     *      此时 owner() 已经是本合约地址，所以版税接收者会自动设为本合约
     * 
     * @param royaltyFraction 版税比例（基点），例如 500 = 5%，最大 10000 = 100%
     */
    function setNFTRoyalty(uint96 royaltyFraction) external onlyOwner {
        // 确认本合约已是 NFT 合约的 owner
        require(nftContract.owner() == address(this), "MFACSystem must be NFT contract owner first");
        require(royaltyFraction <= 10000, "Royalty fraction cannot exceed 10000 basis points");
        
        // 调用 NFT 合约的 setRoyalty
        // 由于本合约已是 NFT 合约的 owner，版税接收者会自动设为本合约地址
        nftContract.setRoyalty(royaltyFraction);
    }
    
    /**
     * @dev 提取MFAC代币到指定地址
     * @param to 接收地址
     * @param amount 提取数量
     */
    function withdrawMFAC(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        _transfer(address(this), to, amount);
    }
    
    /**
     * @dev 提取BNB到指定地址
     * @param to 接收地址
     * @param amount 提取数量
     */
    function withdrawBNB(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(amount <= address(this).balance, "Insufficient balance");
        payable(to).transfer(amount);
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
    
    function batchUpdateWhitelist(address[] calldata users, bool[] calldata statuses) external onlyOwner {
        nftContract.batchUpdateWhitelist(users, statuses);
    }
    
    function setNFTBaseURI(string memory newURI) external onlyOwner {
        nftContract.setBaseURI(newURI);
    }
    
    function setNFTMaxMintsPerUser(uint256 newLimit) external onlyOwner {
        nftContract.setMaxMintsPerUser(newLimit);
    }

    function getNFTMaxMintsPerUser() external view returns (uint256) {
        return nftContract.maxMintsPerUser();
    }
    
    function isWhitelisted(address user) external view returns (bool) {
        return nftContract.whitelist(user);
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
            uint256 _daoTreasuryBNB,
            uint256 _daoTreasuryMFAC,
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
            daoTreasuryBNB,
            daoTreasuryMFAC,
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
            uint256 toProject = msg.value - toCirculating; // 确保没有舍入损失
            
            // 更新版税池
            nftRoyaltyPool += toCirculating;
            totalNFTRoyaltyReceived += msg.value;
            
            // 项目方份额直接转账 (BNB)
            payable(projectWallet).transfer(toProject);
            
            // 统计（用于前端展示）
            daoTreasuryBNB += toProject;
            
            emit NFTRoyaltyReceived(msg.value, toCirculating, toProject);
        }
    }
    
    /**
     * @dev 流通 NFT 持有者领取 BNB 版税分红（优化版：用户提供tokenId）
     * 只有持有流通NFT（tokenId 1-500）的用户可以领取
     * 按持有NFT数量平均分配
     * @param circulatingTokenIds 持有的流通NFT的tokenId数组 (1-500)
     */
    function claimNFTRoyalty(uint256[] calldata circulatingTokenIds) external nonReentrant {
        require(nftRoyaltyPool > 0, "No royalty to claim");
        require(circulatingTokenIds.length > 0, "No token IDs provided");
        
        // 验证并统计用户持有的流通NFT数量
        uint256 validCount = 0;
        for (uint256 i = 0; i < circulatingTokenIds.length; i++) {
            uint256 tokenId = circulatingTokenIds[i];
            require(tokenId > 0 && tokenId <= nftContract.AIRDROP_SUPPLY(), "Invalid circulating tokenId");
            require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not owner of NFT");
            require(lastClaimedRoyalty[tokenId] < totalNFTRoyaltyReceived, "Already claimed");
            
            lastClaimedRoyalty[tokenId] = totalNFTRoyaltyReceived;
            validCount++;
        }
        
        require(validCount > 0, "No valid circulating NFT");
        
        // 计算可领取金额
        // 版税按流通NFT总数平均分配
        uint256 totalCirculatingNFT = CIRCULATING_NFT_COUNT;
        uint256 perNFT = nftRoyaltyPool / totalCirculatingNFT;
        uint256 claimAmount = perNFT * validCount;
        
        require(claimAmount > 0, "Nothing to claim");
        require(claimAmount <= nftRoyaltyPool, "Insufficient pool");
        
        // 更新池余额
        nftRoyaltyPool -= claimAmount;
        
        // 转账 BNB
        payable(msg.sender).transfer(claimAmount);
        
        emit NFTRoyaltyClaimed(msg.sender, claimAmount);
    }
    
    /**
     * @dev 查询用户可领取的 NFT 版税金额（优化版：用户提供tokenId）
     * @param user 用户地址
     * @param circulatingTokenIds 持有的流通NFT的tokenId数组
     */
    function getPendingNFTRoyalty(
        address user,
        uint256[] calldata circulatingTokenIds
    ) external view returns (uint256) {
        if (nftRoyaltyPool == 0) return 0;
        if (circulatingTokenIds.length == 0) return 0;
        
        // 验证并统计用户持有的流通NFT数量
        uint256 validCount = 0;
        for (uint256 i = 0; i < circulatingTokenIds.length; i++) {
            uint256 tokenId = circulatingTokenIds[i];
            if (tokenId > 0 && tokenId <= nftContract.AIRDROP_SUPPLY() &&
                nftContract.balanceOf(user, tokenId) > 0) {
                validCount++;
            }
        }
        
        if (validCount == 0) return 0;
        
        uint256 totalCirculatingNFT = CIRCULATING_NFT_COUNT;
        uint256 perNFT = nftRoyaltyPool / totalCirculatingNFT;
        return perNFT * validCount;
    }
}

