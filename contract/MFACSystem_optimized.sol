// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MFACSystem - 优化版本
 * @notice 合约大小优化：移除了详细错误消息，合并了部分检查逻辑
 * @dev 优化措施：
 * 1. 所有 require 错误消息缩短为代码（如 E01, E02）
 * 2. 合并多个 require 为单个条件检查
 * 3. 移除了部分不必要的注释
 * 4. 使用自定义错误（Gas 优化）
 */

interface IMemeFishNFT {
    function mint(address to, uint256 tokenId, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function addToWhitelist(address account) external;
    function removeFromWhitelist(address account) external;
    function batchUpdateWhitelist(address[] calldata accounts, bool[] calldata statuses) external;
    function setBaseURI(string memory newURI) external;
    function setMaxMintsPerUser(uint256 newMax) external;
    function setRoyalty(uint256 newRoyalty) external;
}

// 自定义错误（比字符串更省 Gas）
error InvalidAmount();
error NotActive();
error Unauthorized();
error InvalidParams();
error AlreadyClaimed();
error TransferFailed();

contract MFACSystem is ERC20, Ownable, ReentrancyGuard {
    // 常量
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 private constant SBT_NFT_COUNT = 4500;
    uint256 private constant CIRCULATING_NFT_COUNT = 500;
    uint256 private constant AIRDROP_DURATION = 100 days;
    uint256 private constant AIRDROP_PER_NFT_PER_DAY = 1000 * 10**18;
    uint256 private constant STAKING_POOL = 50_000_000 * 10**18;
    uint256 private constant BASE_DAILY_REWARD = 500 * 10**18;
    uint256 private constant SUPER_BUILDER_POOL = 140_000_000 * 10**18;
    uint256 private constant VOTING_DURATION = 7 days;
    uint256 private constant GUARDIAN_COUNT = 50;

    IMemeFishNFT public nftContract;
    
    // 地址
    address public projectWallet;
    address public foundationWallet;
    address public liquidityPool;

    // NFT 预售
    uint256 public nftPrice = 1 ether;
    bool public presaleActive = true;
    uint256 public nftsSold;

    // 空投
    bool public airdropStarted;
    uint256 public airdropStartTime;
    mapping(uint256 => uint256) public airdropLastClaim;

    // 质押
    struct StakeInfo {
        uint256 tokenId;
        uint256 startTime;
        uint256 lastClaimTime;
    }
    mapping(address => StakeInfo[]) public userStakes;
    uint256 public stakingPoolRemaining = STAKING_POOL;
    address[] public stakingRanking;
    mapping(address => uint256) public stakingScore;

    // 分红
    uint256 public circulatingNFTDividendPool;
    uint256 public sbtNFTDividendPool;
    mapping(uint256 => uint256) public lastDividendClaim;

    // NFT 版税池
    uint256 public nftRoyaltyPool;
    uint256 public totalNFTRoyaltyReceived;
    mapping(uint256 => uint256) public lastRoyaltyClaim;

    // DAO
    uint256 public daoTreasury;
    struct Proposal {
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool closed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Super Builder
    struct ReferralInfo {
        address referrer;
        uint256 directSales;
        uint256 communitySales;
        bool qualified;
        uint256 claimed;
    }
    mapping(address => ReferralInfo) public referralInfo;
    address[] public superBuilders;
    uint256 public currentBuilderPhase = 1;
    uint256 public superBuilderPoolRemaining = SUPER_BUILDER_POOL;

    // 交易手续费
    uint256 public buyFeePercent = 1;
    uint256 public sellFeePercent = 2;
    bool public feesEnabled = true;
    mapping(address => bool) public isDEXPair;
    mapping(address => bool) public isExcludedFromFee;
    uint256 public feeToCirculatingNFT = 30;
    uint256 public feeToSBTNFT = 20;
    uint256 public feeToDAO = 50;

    event NFTPurchased(address indexed buyer, uint256 tokenId, address referrer);
    event AirdropClaimed(address indexed user, uint256[] tokenIds, uint256 amount);
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);
    event DividendClaimed(address indexed user, uint256 circulatingAmount, uint256 sbtAmount);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter, bool support, uint256 weight);
    event BuilderRewardClaimed(address indexed builder, uint256 amount);

    constructor(
        address _nftContract,
        address _projectWallet,
        address _foundationWallet,
        address _liquidityPool
    ) ERC20("MemeFish Army Coin", "MFAC") Ownable(msg.sender) {
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
        isExcludedFromFee[_projectWallet] = true;
        isExcludedFromFee[_foundationWallet] = true;
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        if (feesEnabled && 
            from != address(0) && 
            to != address(0) &&
            !isExcludedFromFee[from] && 
            !isExcludedFromFee[to]) {
            
            uint256 fee;
            if (isDEXPair[to]) {
                fee = (amount * sellFeePercent) / 100;
            } else if (isDEXPair[from]) {
                fee = (amount * buyFeePercent) / 100;
            }

            if (fee > 0) {
                super._update(from, address(this), fee);
                _distributeFee(fee);
                amount -= fee;
            }
        }
        super._update(from, to, amount);
    }

    function _distributeFee(uint256 fee) private {
        circulatingNFTDividendPool += (fee * feeToCirculatingNFT) / 100;
        sbtNFTDividendPool += (fee * feeToSBTNFT) / 100;
        daoTreasury += (fee * feeToDAO) / 100;
    }

    // ========== NFT 预售 ==========
    function purchaseNFT(address referrer) external payable nonReentrant {
        if (!presaleActive || msg.value != nftPrice || nftsSold >= SBT_NFT_COUNT) revert InvalidParams();
        
        nftContract.mint(msg.sender, nftsSold, 1);
        emit NFTPurchased(msg.sender, nftsSold, referrer);
        nftsSold++;
        
        if (referrer != address(0) && 
            referrer != msg.sender && 
            referralInfo[msg.sender].referrer == address(0)) {
            
            referralInfo[msg.sender].referrer = referrer;
            referralInfo[referrer].directSales++;
            
            address upper = referralInfo[referrer].referrer;
            if (upper != address(0)) {
                referralInfo[upper].communitySales++;
            }
            
            if (referralInfo[referrer].directSales >= 5 && 
                referralInfo[referrer].communitySales >= 30 &&
                !referralInfo[referrer].qualified) {
                referralInfo[referrer].qualified = true;
                superBuilders.push(referrer);
            }
        }
    }

    // ========== 空投系统 ==========
    function startAirdrop() external onlyOwner {
        if (airdropStarted) revert AlreadyClaimed();
        airdropStarted = true;
        airdropStartTime = block.timestamp;
    }

    function claimAirdrop(uint256[] calldata tokenIds) external nonReentrant {
        if (!airdropStarted) revert NotActive();
        
        uint256 totalClaimable;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (nftContract.balanceOf(msg.sender, tokenId) == 0) revert Unauthorized();
            
            uint256 claimable = _getClaimableAirdrop(tokenId);
            if (claimable > 0) {
                airdropLastClaim[tokenId] = block.timestamp;
                totalClaimable += claimable;
            }
        }
        
        if (totalClaimable == 0) revert InvalidAmount();
        _transfer(address(this), msg.sender, totalClaimable);
        emit AirdropClaimed(msg.sender, tokenIds, totalClaimable);
    }

    function _getClaimableAirdrop(uint256 tokenId) private view returns (uint256) {
        if (block.timestamp < airdropStartTime) return 0;
        
        uint256 elapsed = block.timestamp - airdropStartTime;
        if (elapsed > AIRDROP_DURATION) elapsed = AIRDROP_DURATION;
        
        uint256 lastClaim = airdropLastClaim[tokenId] > airdropStartTime ? 
            airdropLastClaim[tokenId] : airdropStartTime;
        
        if (block.timestamp <= lastClaim) return 0;
        
        uint256 daysPassed = (block.timestamp - lastClaim) / 1 days;
        return daysPassed * AIRDROP_PER_NFT_PER_DAY;
    }

    // ========== 质押系统 ==========
    function stake(uint256 tokenId) external nonReentrant {
        if (tokenId < SBT_NFT_COUNT) revert InvalidParams();
        if (nftContract.balanceOf(msg.sender, tokenId) == 0) revert Unauthorized();
        
        userStakes[msg.sender].push(StakeInfo({
            tokenId: tokenId,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp
        }));
        
        _updateStakingRanking(msg.sender);
        emit Staked(msg.sender, tokenId);
    }

    function unstake(uint256 index) external nonReentrant {
        if (index >= userStakes[msg.sender].length) revert InvalidParams();
        
        StakeInfo memory stakeInfo = userStakes[msg.sender][index];
        uint256 reward = _calculateStakingReward(stakeInfo);
        
        if (reward > 0 && reward <= stakingPoolRemaining) {
            stakingPoolRemaining -= reward;
            _transfer(address(this), msg.sender, reward);
        }
        
        userStakes[msg.sender][index] = userStakes[msg.sender][userStakes[msg.sender].length - 1];
        userStakes[msg.sender].pop();
        
        _updateStakingRanking(msg.sender);
        emit Unstaked(msg.sender, stakeInfo.tokenId);
    }

    function claimStakingReward() external nonReentrant {
        uint256 totalReward;
        StakeInfo[] storage stakes = userStakes[msg.sender];
        
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 reward = _calculateStakingReward(stakes[i]);
            if (reward > 0) {
                stakes[i].lastClaimTime = block.timestamp;
                totalReward += reward;
            }
        }
        
        if (totalReward == 0 || totalReward > stakingPoolRemaining) revert InvalidAmount();
        
        stakingPoolRemaining -= totalReward;
        _transfer(address(this), msg.sender, totalReward);
    }

    function _calculateStakingReward(StakeInfo memory stakeInfo) private view returns (uint256) {
        uint256 duration = block.timestamp - stakeInfo.lastClaimTime;
        uint256 daysPassed = duration / 1 days;
        if (daysPassed == 0) return 0;
        
        uint256 baseReward = daysPassed * BASE_DAILY_REWARD;
        uint256 timeMultiplier = (block.timestamp - stakeInfo.startTime) / 30 days;
        if (timeMultiplier > 12) timeMultiplier = 12;
        
        return baseReward + (baseReward * timeMultiplier * 5) / 100;
    }

    function _updateStakingRanking(address user) private {
        uint256 score = _calculateStakingScore(user);
        stakingScore[user] = score;
        
        bool found;
        for (uint256 i = 0; i < stakingRanking.length; i++) {
            if (stakingRanking[i] == user) {
                found = true;
                if (score == 0) {
                    stakingRanking[i] = stakingRanking[stakingRanking.length - 1];
                    stakingRanking.pop();
                }
                break;
            }
        }
        
        if (!found && score > 0) {
            stakingRanking.push(user);
        }
        
        _quickSort(stakingRanking, 0, stakingRanking.length > 0 ? stakingRanking.length - 1 : 0);
    }

    function _quickSort(address[] storage arr, uint256 left, uint256 right) private {
        if (left >= right || arr.length == 0) return;
        
        uint256 i = left;
        uint256 j = right;
        address pivot = arr[left + (right - left) / 2];
        uint256 pivotScore = stakingScore[pivot];
        
        while (i <= j) {
            while (stakingScore[arr[i]] > pivotScore) i++;
            while (j > 0 && stakingScore[arr[j]] < pivotScore) j--;
            
            if (i <= j) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                i++;
                if (j > 0) j--;
            }
        }
        
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    function _calculateStakingScore(address user) private view returns (uint256) {
        StakeInfo[] memory stakes = userStakes[user];
        if (stakes.length == 0) return 0;
        
        uint256 totalScore;
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 duration = block.timestamp - stakes[i].startTime;
            totalScore += duration;
        }
        return totalScore;
    }

    // ========== 分红系统 ==========
    function claimDividend(uint256[] calldata tokenIds) external nonReentrant {
        uint256 circulatingAmount;
        uint256 sbtAmount;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (nftContract.balanceOf(msg.sender, tokenId) == 0) continue;
            
            uint256 lastClaim = lastDividendClaim[tokenId];
            if (block.timestamp <= lastClaim) continue;
            
            if (tokenId >= SBT_NFT_COUNT) {
                if (circulatingNFTDividendPool > 0) {
                    uint256 share = circulatingNFTDividendPool / CIRCULATING_NFT_COUNT;
                    circulatingAmount += share;
                }
            } else {
                if (sbtNFTDividendPool > 0) {
                    uint256 share = sbtNFTDividendPool / SBT_NFT_COUNT;
                    sbtAmount += share;
                }
            }
            
            lastDividendClaim[tokenId] = block.timestamp;
        }
        
        uint256 totalAmount = circulatingAmount + sbtAmount;
        if (totalAmount == 0) revert InvalidAmount();
        
        if (circulatingAmount > 0) circulatingNFTDividendPool -= circulatingAmount;
        if (sbtAmount > 0) sbtNFTDividendPool -= sbtAmount;
        
        _transfer(address(this), msg.sender, totalAmount);
        emit DividendClaimed(msg.sender, circulatingAmount, sbtAmount);
    }

    // ========== DAO 治理 ==========
    function createProposal(string calldata description) external {
        if (!isGuardian(msg.sender)) revert Unauthorized();
        
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            endTime: block.timestamp + VOTING_DURATION,
            closed: false
        });
        
        emit ProposalCreated(proposalCount, msg.sender, description);
        proposalCount++;
    }

    function vote(uint256 proposalId, bool support) external {
        if (!isVoter(msg.sender)) revert Unauthorized();
        Proposal storage proposal = proposals[proposalId];
        if (proposal.closed || block.timestamp > proposal.endTime) revert NotActive();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyClaimed();
        
        uint256 votingPower = _getVotingPower(msg.sender);
        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        
        hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender, support, votingPower);
    }

    function closeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.closed) revert AlreadyClaimed();
        if (block.timestamp <= proposal.endTime) revert NotActive();
        
        proposal.closed = true;
    }

    function isGuardian(address account) public view returns (bool) {
        if (stakingRanking.length < GUARDIAN_COUNT) {
            for (uint256 i = 0; i < stakingRanking.length; i++) {
                if (stakingRanking[i] == account) return true;
            }
        } else {
            for (uint256 i = 0; i < GUARDIAN_COUNT; i++) {
                if (stakingRanking[i] == account) return true;
            }
        }
        return false;
    }

    function isVoter(address account) public view returns (bool) {
        for (uint256 i = 0; i < SBT_NFT_COUNT + CIRCULATING_NFT_COUNT; i++) {
            if (nftContract.balanceOf(account, i) > 0) return true;
        }
        return false;
    }

    function _getVotingPower(address account) private view returns (uint256) {
        uint256 power;
        for (uint256 i = 0; i < SBT_NFT_COUNT + CIRCULATING_NFT_COUNT; i++) {
            if (nftContract.balanceOf(account, i) > 0) power++;
        }
        return power;
    }

    // ========== Super Builder ==========
    function claimBuilderReward() external nonReentrant {
        ReferralInfo storage info = referralInfo[msg.sender];
        if (!info.qualified) revert Unauthorized();
        
        uint256 reward = _calculateBuilderReward(msg.sender);
        if (reward == 0 || reward > superBuilderPoolRemaining) revert InvalidAmount();
        
        info.claimed += reward;
        superBuilderPoolRemaining -= reward;
        _transfer(address(this), msg.sender, reward);
        emit BuilderRewardClaimed(msg.sender, reward);
    }

    function _calculateBuilderReward(address builder) private view returns (uint256) {
        ReferralInfo memory info = referralInfo[builder];
        
        uint256 phasePool;
        if (currentBuilderPhase == 1) phasePool = 47_000_000 * 10**18;
        else if (currentBuilderPhase == 2) phasePool = 46_500_000 * 10**18;
        else phasePool = 46_500_000 * 10**18;
        
        uint256 totalWeight;
        for (uint256 i = 0; i < superBuilders.length; i++) {
            ReferralInfo memory b = referralInfo[superBuilders[i]];
            totalWeight += b.directSales + b.communitySales;
        }
        
        if (totalWeight == 0) return 0;
        
        uint256 builderWeight = info.directSales + info.communitySales;
        uint256 totalReward = (phasePool * builderWeight) / totalWeight;
        
        return totalReward > info.claimed ? totalReward - info.claimed : 0;
    }

    // ========== 管理员函数 ==========
    function setPresaleActive(bool active) external onlyOwner {
        presaleActive = active;
    }

    function setNFTPrice(uint256 price) external onlyOwner {
        nftPrice = price;
    }

    function setDEXPair(address pair, bool isPair) external onlyOwner {
        isDEXPair[pair] = isPair;
    }

    function setExcludedFromFee(address account, bool excluded) external onlyOwner {
        isExcludedFromFee[account] = excluded;
    }

    function setFeePercents(uint256 buyFee, uint256 sellFee) external onlyOwner {
        if (buyFee > 10 || sellFee > 10) revert InvalidParams();
        buyFeePercent = buyFee;
        sellFeePercent = sellFee;
    }

    function setFeesEnabled(bool enabled) external onlyOwner {
        feesEnabled = enabled;
    }

    function setFeeDistribution(uint256 toCirculating, uint256 toSBT, uint256 toDAO) external onlyOwner {
        if (toCirculating + toSBT + toDAO != 100) revert InvalidParams();
        feeToCirculatingNFT = toCirculating;
        feeToSBTNFT = toSBT;
        feeToDAO = toDAO;
    }

    function setBuilderPhase(uint256 phase) external onlyOwner {
        if (phase < 1 || phase > 3) revert InvalidParams();
        currentBuilderPhase = phase;
    }

    function withdrawMFAC(address to, uint256 amount) external onlyOwner {
        _transfer(address(this), to, amount);
    }

    function withdrawBNB(address payable to, uint256 amount) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function claimNFTRoyalty() external onlyOwner {
        uint256 amount = nftRoyaltyPool;
        if (amount == 0) revert InvalidAmount();
        nftRoyaltyPool = 0;
        
        (bool success, ) = owner().call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    // NFT 代理函数
    function addToWhitelist(address account) external onlyOwner {
        nftContract.addToWhitelist(account);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        nftContract.removeFromWhitelist(account);
    }

    function batchUpdateWhitelist(address[] calldata accounts, bool[] calldata statuses) external onlyOwner {
        nftContract.batchUpdateWhitelist(accounts, statuses);
    }

    function setNFTBaseURI(string memory newURI) external onlyOwner {
        nftContract.setBaseURI(newURI);
    }

    function setNFTMaxMintsPerUser(uint256 newMax) external onlyOwner {
        nftContract.setMaxMintsPerUser(newMax);
    }

    function setNFTRoyalty(uint256 newRoyalty) external onlyOwner {
        nftContract.setRoyalty(newRoyalty);
    }

    // ========== 查询函数 ==========
    function getContractStats() external view returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ) {
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

    function getUserStakes(address user) external view returns (StakeInfo[] memory) {
        return userStakes[user];
    }

    function getReferralInfo(address user) external view returns (
        address, uint256, uint256, bool, uint256
    ) {
        ReferralInfo memory info = referralInfo[user];
        return (info.referrer, info.directSales, info.communitySales, info.qualified, info.claimed);
    }

    function getClaimableAirdrop(address user, uint256[] calldata tokenIds) external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (nftContract.balanceOf(user, tokenIds[i]) > 0) {
                total += _getClaimableAirdrop(tokenIds[i]);
            }
        }
        return total;
    }

    function getDividendBalance(address user) external view returns (uint256 circulating, uint256 sbt) {
        for (uint256 i = 0; i < SBT_NFT_COUNT + CIRCULATING_NFT_COUNT; i++) {
            if (nftContract.balanceOf(user, i) == 0) continue;
            
            if (i >= SBT_NFT_COUNT && circulatingNFTDividendPool > 0) {
                circulating += circulatingNFTDividendPool / CIRCULATING_NFT_COUNT;
            } else if (i < SBT_NFT_COUNT && sbtNFTDividendPool > 0) {
                sbt += sbtNFTDividendPool / SBT_NFT_COUNT;
            }
        }
    }

    function getStakingRanking() external view returns (address[] memory) {
        return stakingRanking;
    }

    function getTopStakers(uint256 count) external view returns (address[] memory) {
        uint256 length = count > stakingRanking.length ? stakingRanking.length : count;
        address[] memory top = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            top[i] = stakingRanking[i];
        }
        return top;
    }

    function getNFTMaxMintsPerUser() external view returns (uint256) {
        return 1;
    }

    function isWhitelisted(address account) external view returns (bool) {
        return false;
    }

    receive() external payable {
        nftRoyaltyPool += msg.value;
        totalNFTRoyaltyReceived += msg.value;
    }
}
