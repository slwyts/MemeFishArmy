// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IMemeFishNFT {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function AIRDROP_SUPPLY() external view returns (uint256);
    function MAX_TOKEN_ID() external view returns (uint256);
}

contract MFACSystem is ERC20, Ownable, ReentrancyGuard {
    IMemeFishNFT private nftContract;
    uint256 private buyFeePercent = 1;
    uint256 private sellFeePercent = 2;
    bool private constant FEES_ENABLED = true; // 手续费永久开启
    uint256 private feeToCirculatingNFT = 30;
    uint256 private feeToSBTNFT = 20;
    uint256 private feeToDAO = 50;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isDEXPair;
    uint256 private constant SBT_NFT_COUNT = 4500;
    uint256 private constant CIRCULATING_NFT_COUNT = 500;
    uint256 private constant NFT_PRICE = 1 ether; // 固定价格 1 BNB
    uint256 private nftsSold = 0;
    
    // NFT 预售收入的 5% 进入 DAO 国库
    uint256 private presaleDaoPercent = 5;
    
    uint256 private constant AIRDROP_DURATION = 100 days;
    uint256 private constant AIRDROP_PER_NFT_PER_DAY = 1000 * 10**18; // 1000 MFAC/天
    uint256 private constant SBT_AIRDROP_POOL = 450_000_000 * 10**18; // 4.5亿
    uint256 private constant CIRCULATING_AIRDROP_POOL = 50_000_000 * 10**18; // 5000万
    uint256 private airdropStartTime; // 第一次领取时自动设置
    mapping(uint256 => mapping(uint256 => bool)) private airdropClaimed;
    mapping(uint256 => mapping(address => bool)) private hasOwnedToken;
    mapping(uint256 => uint256) private circulatingNFTClaimedDays;
    
    uint256 private constant STAKING_POOL = 50_000_000 * 10**18; // 5000万
    uint256 private constant BASE_DAILY_REWARD = 500 * 10**18; // 500 MFAC/天
    uint256 private constant WEIGHT_MULTIPLIER = 110; // 1.1倍 = 110/100
    uint256 private constant WEIGHT_PERIOD = 30 days;
    
    uint256 private stakingPoolRemaining = STAKING_POOL;
    
    struct StakeInfo {
        uint256 tokenId;
        uint256 startTime;
        uint256 lastClaimTime;
    }
    
    // user => StakeInfo[]
    mapping(address => StakeInfo[]) private userStakes;
    
    // tokenId => isStaked
    mapping(uint256 => bool) private isTokenStaked;
    
    // tokenId => staker address
    mapping(uint256 => address) private tokenStaker;
    
    // 质押排名 (用于 DAO 守护者资格)
    address[] private stakingRanking;
    
    // 用户质押分数 (基于质押时长 * NFT数量)
    mapping(address => uint256) private stakingScore;
    
    // ============================================
    // 状态变量 - 分红系统
    // ============================================
    
    // 代币手续费分红池 (MFAC 代币)
    uint256 private circulatingNFTDividendPool;  // 流通NFT代币分红
    uint256 private sbtNFTDividendPool;          // SBT代币分红
    
    // NFT 版税分红池 (BNB)
    uint256 private nftRoyaltyPool;
    uint256 private totalNFTRoyaltyReceived;

    mapping(uint256 => uint256) private lastClaimedDividendCirculating;
    mapping(uint256 => uint256) private lastClaimedDividendSBT;
    mapping(uint256 => uint256) private lastClaimedRoyalty;
    
    uint256 private totalDividendCirculating;
    uint256 private totalDividendSBT;
    
    // NFT 版税分配比例
    uint256 private constant ROYALTY_TO_CIRCULATING = 50;
    uint256 private constant ROYALTY_TO_DAO = 50;
    uint256 private daoTreasuryBNB;
    uint256 private daoTreasuryMFAC;
    
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
    
    uint256 private proposalCount;
    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => mapping(address => bool)) private hasVoted;
    
    uint256 private constant VOTING_DURATION = 7 days;
    uint256 private constant GUARDIAN_COUNT = 50;
    
    uint256 private constant SUPER_BUILDER_POOL = 140_000_000 * 10**18;
    uint256 private superBuilderPoolRemaining = SUPER_BUILDER_POOL;
    
    uint256 private constant DIRECT_REFERRAL_REQUIREMENT = 5;
    uint256 private constant COMMUNITY_SALES_REQUIREMENT = 30;
    
    struct ReferralInfo {
        address referrer;
        uint256 directSales;
        uint256 communitySales;
        bool qualifiedForBuilder;
        uint256 rewardClaimed;
    }
    
    mapping(address => ReferralInfo) private referrals;
    mapping(address => address[]) private directReferrals;
    
    address[] private superBuilders;
    uint256 private currentBuilderPhase = 1; // 分3期
    
    address private projectWallet;      // 项目方钱包 (营销+俱乐部+团队+Alpha板块 = 11%)
    address private foundationWallet;   // 基金会钱包 (10%)
    address private liquidityPool;      // 流动性池 (Alpha底池 10%)
    
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
        if (!FEES_ENABLED || 
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
        require(msg.value == NFT_PRICE, "Incorrect BNB amount");
        require(nftsSold < SBT_NFT_COUNT, "All NFTs sold");
        
        // 检查是否已在白名单中（即已购买过）
        (bool checkSuccess, bytes memory checkData) = address(nftContract).call(
            abi.encodeWithSignature("isWhitelisted(address)", msg.sender)
        );
        require(checkSuccess, "Whitelist check failed");
        bool isWhitelisted = abi.decode(checkData, (bool));
        require(!isWhitelisted, "Already purchased");
        
        // 添加到白名单
        (bool success,) = address(nftContract).call(
            abi.encodeWithSignature("addToWhitelist(address)", msg.sender)
        );
        require(success, "Whitelist add failed");
        
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
    
    function claimAirdrop(uint256[] calldata tokenIds) external nonReentrant {
        // 第一次领取时自动开始空投
        if (airdropStartTime == 0) {
            airdropStartTime = block.timestamp;
        }
        
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
        if (airdropStartTime == 0) {
            // 空投还未开始（没人领取过），所有NFT都可领取第一天
            uint256 firstDayClaimable = 0;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (nftContract.balanceOf(user, tokenIds[i]) > 0) {
                    firstDayClaimable += AIRDROP_PER_NFT_PER_DAY;
                }
            }
            return firstDayClaimable;
        }
        
        if (block.timestamp >= airdropStartTime + AIRDROP_DURATION) {
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
        // 只有流通 NFT (1-500) 可以质押，SBT不能转账也不需要质押
        require(tokenId > 0 && tokenId <= nftContract.AIRDROP_SUPPLY(), "Only circulating NFTs can be staked");
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
        
        uint256 periods = totalStakingTime / WEIGHT_PERIOD;
        uint256 weight = 100;
        
        for (uint256 i = 0; i < periods; i++) {
            weight = (weight * WEIGHT_MULTIPLIER) / 100;
        }
        
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
     * @dev 获取所有提案列表
     */
    function getProposals() 
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
        if (total == 0) {
            return (new uint256[](0), new address[](0), new uint256[](0), new uint256[](0), new uint256[](0), new bool[](0));
        }
        
        ids = new uint256[](total);
        proposers = new address[](total);
        yesVotes_ = new uint256[](total);
        noVotes_ = new uint256[](total);
        endTimes = new uint256[](total);
        closed_ = new bool[](total);
        
        for (uint256 i = 0; i < total; i++) {
            uint256 proposalId = i + 1;
            Proposal storage p = proposals[proposalId];
            ids[i] = p.id;
            proposers[i] = p.proposer;
            yesVotes_[i] = p.yesVotes;
            noVotes_[i] = p.noVotes;
            endTimes[i] = p.endTime;
            closed_[i] = p.closed;
        }
    }

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
    
    function withdrawMFAC(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        _transfer(address(this), to, amount);
    }

    function withdrawBNB(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(amount <= address(this).balance, "Insufficient balance");
        payable(to).transfer(amount);
    }

    function proxyCallNFT(bytes calldata data) external onlyOwner returns (bool success, bytes memory returnData) {
        (success, returnData) = address(nftContract).call(data);
        require(success, "NFT proxy call failed");
    }
    
    function hasPurchasedNFT(address user) external view returns (bool) {
        // 通过检查白名单状态来判断是否已购买
        (bool success, bytes memory data) = address(nftContract).staticcall(
            abi.encodeWithSignature("isWhitelisted(address)", user)
        );
        if (!success) return false;
        return abi.decode(data, (bool));
    }
    
    function getNFTPrice() external pure returns (uint256) {
        return NFT_PRICE;
    }
    
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
    
    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

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
        
        uint256 totalCirculatingNFT = CIRCULATING_NFT_COUNT;
        uint256 perNFT = nftRoyaltyPool / totalCirculatingNFT;
        uint256 claimAmount = perNFT * validCount;
        
        require(claimAmount > 0, "Nothing to claim");
        require(claimAmount <= nftRoyaltyPool, "Insufficient pool");

        nftRoyaltyPool -= claimAmount;

        payable(msg.sender).transfer(claimAmount);
        
        emit NFTRoyaltyClaimed(msg.sender, claimAmount);
    }

    function getPendingNFTRoyalty(
        address user,
        uint256[] calldata circulatingTokenIds
    ) external view returns (uint256) {
        if (nftRoyaltyPool == 0) return 0;
        if (circulatingTokenIds.length == 0) return 0;
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

