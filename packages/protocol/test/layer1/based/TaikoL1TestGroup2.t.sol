// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./TaikoL1TestGroupBase.sol";

contract TaikoL1TestGroup2 is TaikoL1TestGroupBase {
    // Test summary:
    // 1. Alice proposes a block, Alice as the prover.
    // 2. Alice proves the block within the proving window, with correct parent hash.
    // 3. Taylor contests Alice's proof.
    // 4. William proves Alice is correct and Taylor is wrong.
    // 5. William's proof is used to verify the block.
    function test_taikoL1_group_2_case_1() external {
        vm.warp(1_000_000);

        giveEthAndTko(Alice, 10_000 ether, 1000 ether);

        giveEthAndTko(Taylor, 10_000 ether, 1000 ether);
        giveEthAndTko(William, 10_000 ether, 1000 ether);
        ITierProvider.Tier memory tierOp = ITierProvider(tr).getTier(LibTiers.TIER_OPTIMISTIC);
        ITierProvider.Tier memory tierSgx = ITierProvider(tr).getTier(LibTiers.TIER_SGX);

        console2.log("====== Alice propose a block");
        TaikoData.BlockMetadataV2 memory meta = proposeBlock(Alice, "");

        console2.log("====== Alice proves the block as the assigned prover");
        bytes32 parentHash = GENESIS_BLOCK_HASH;
        bytes32 blockHash = bytes32(uint256(10));
        bytes32 stateRoot = bytes32(uint256(11));

        mineAndWrap(10 seconds);
        proveBlock(Alice, meta, parentHash, blockHash, stateRoot, meta.minTier, "");

        console2.log("====== Taylor contests Alice");
        bytes32 blockHash2 = bytes32(uint256(20));
        bytes32 stateRoot2 = bytes32(uint256(21));
        mineAndWrap(10 seconds);
        proveBlock(Taylor, meta, parentHash, blockHash2, stateRoot2, meta.minTier, "");

        {
            printBlockAndTrans(meta.id);

            TaikoData.BlockV2 memory blk = L1.getBlockV2(meta.id);
            assertEq(blk.nextTransitionId, 2);
            assertEq(blk.verifiedTransitionId, 0);

            TaikoData.TransitionState memory ts = L1.getTransition(meta.id, 1);
            assertEq(ts.blockHash, blockHash);
            assertEq(ts.stateRoot, stateRoot);
            assertEq(ts.tier, LibTiers.TIER_OPTIMISTIC);
            assertEq(ts.contester, Taylor);
            assertEq(ts.contestBond, tierOp.contestBond);
            assertEq(ts.validityBond, tierOp.validityBond);
            assertEq(ts.prover, Alice);
            assertEq(ts.timestamp, block.timestamp);

            assertEq(totalTkoBalance(tko, L1, Alice), 10_000 ether - tierOp.validityBond);
            assertEq(totalTkoBalance(tko, L1, Taylor), 10_000 ether - tierOp.contestBond);
        }

        console2.log("====== William proves Alice is right");
        mineAndWrap(10 seconds);
        proveBlock(William, meta, parentHash, blockHash, stateRoot, LibTiers.TIER_SGX, "");

        {
            printBlockAndTrans(meta.id);

            TaikoData.BlockV2 memory blk = L1.getBlockV2(meta.id);
            assertEq(blk.nextTransitionId, 2);
            assertEq(blk.verifiedTransitionId, 0);

            TaikoData.TransitionState memory ts = L1.getTransition(meta.id, 1);
            assertEq(ts.blockHash, blockHash);
            assertEq(ts.stateRoot, stateRoot);
            assertEq(ts.tier, LibTiers.TIER_SGX);
            assertEq(ts.contester, address(0));
            assertEq(ts.validityBond, tierSgx.validityBond);
            assertEq(ts.prover, William);
            assertEq(ts.timestamp, block.timestamp); // not zero

            assertEq(totalTkoBalance(tko, L1, Alice), 10_000 ether);
            assertEq(totalTkoBalance(tko, L1, Taylor), 10_000 ether - tierOp.contestBond);
            assertEq(
                totalTkoBalance(tko, L1, William),
                10_000 ether - tierSgx.validityBond + tierOp.contestBond * 7 / 8
            );
        }

        console2.log("====== Verify the block");
        mineAndWrap(7 days);
        verifyBlock(1);
        {
            printBlockAndTrans(meta.id);

            TaikoData.BlockV2 memory blk = L1.getBlockV2(meta.id);

            assertEq(blk.nextTransitionId, 2);
            assertEq(blk.verifiedTransitionId, 1);
            // assertEq(blk.livenessBond, livenessBond);

            TaikoData.TransitionState memory ts = L1.getTransition(meta.id, 1);
            assertEq(ts.blockHash, blockHash);
            assertEq(ts.stateRoot, stateRoot);
            assertEq(ts.tier, LibTiers.TIER_SGX);
            assertEq(ts.prover, William);

            assertEq(totalTkoBalance(tko, L1, William), 10_000 ether + tierOp.contestBond * 7 / 8);
        }
    }

    // Test summary:
    // 1. Alice proposes a block, Alice as the prover.
    // 2. Alice proves the block within the proving window, with correct parent hash.
    // 3. Taylor contests Alice's proof.
    // 4. William proves Taylor is correct and Alice is wrong.
    // 5. William's proof is used to verify the block.
    function test_taikoL1_group_2_case_2() external {
        vm.warp(1_000_000);

        giveEthAndTko(Alice, 10_000 ether, 1000 ether);

        giveEthAndTko(Taylor, 10_000 ether, 1000 ether);
        giveEthAndTko(William, 10_000 ether, 1000 ether);
        ITierProvider.Tier memory tierOp = ITierProvider(tr).getTier(LibTiers.TIER_OPTIMISTIC);
        ITierProvider.Tier memory tierSgx = ITierProvider(tr).getTier(LibTiers.TIER_SGX);

        console2.log("====== Alice propose a block");
        TaikoData.BlockMetadataV2 memory meta = proposeBlock(Alice, "");

        console2.log("====== Alice proves the block as the assigned prover");
        bytes32 parentHash = GENESIS_BLOCK_HASH;
        bytes32 blockHash = bytes32(uint256(10));
        bytes32 stateRoot = bytes32(uint256(11));

        mineAndWrap(10 seconds);
        proveBlock(Alice, meta, parentHash, blockHash, stateRoot, meta.minTier, "");

        console2.log("====== Taylor contests Alice");
        bytes32 blockHash2 = bytes32(uint256(20));
        bytes32 stateRoot2 = bytes32(uint256(21));
        mineAndWrap(10 seconds);
        proveBlock(Taylor, meta, parentHash, blockHash2, stateRoot2, meta.minTier, "");

        {
            printBlockAndTrans(meta.id);

            TaikoData.BlockV2 memory blk = L1.getBlockV2(meta.id);
            assertEq(blk.nextTransitionId, 2);
            assertEq(blk.verifiedTransitionId, 0);

            TaikoData.TransitionState memory ts = L1.getTransition(meta.id, 1);
            assertEq(ts.blockHash, blockHash);
            assertEq(ts.stateRoot, stateRoot);
            assertEq(ts.tier, LibTiers.TIER_OPTIMISTIC);
            assertEq(ts.contester, Taylor);
            assertEq(ts.contestBond, tierOp.contestBond);
            assertEq(ts.validityBond, tierOp.validityBond);
            assertEq(ts.prover, Alice);
            assertEq(ts.timestamp, block.timestamp);

            assertEq(totalTkoBalance(tko, L1, Alice), 10_000 ether - tierOp.validityBond);
            assertEq(totalTkoBalance(tko, L1, Taylor), 10_000 ether - tierOp.contestBond);
        }

        console2.log("====== William proves Tayler is right");
        mineAndWrap(10 seconds);
        proveBlock(William, meta, parentHash, blockHash2, stateRoot2, LibTiers.TIER_SGX, "");

        {
            printBlockAndTrans(meta.id);

            TaikoData.BlockV2 memory blk = L1.getBlockV2(meta.id);
            assertEq(blk.nextTransitionId, 2);
            assertEq(blk.verifiedTransitionId, 0);

            TaikoData.TransitionState memory ts = L1.getTransition(meta.id, 1);
            assertEq(ts.blockHash, blockHash2);
            assertEq(ts.stateRoot, stateRoot2);
            assertEq(ts.tier, LibTiers.TIER_SGX);
            assertEq(ts.contester, address(0));
            assertEq(ts.validityBond, tierSgx.validityBond);
            assertEq(ts.prover, William);
            assertEq(ts.timestamp, block.timestamp);

            assertEq(totalTkoBalance(tko, L1, Alice), 10_000 ether - tierOp.validityBond);

            uint256 quarterReward = tierOp.validityBond * 7 / 8 / 4;
            assertEq(totalTkoBalance(tko, L1, Taylor), 10_000 ether + quarterReward * 3);
            assertEq(
                totalTkoBalance(tko, L1, William),
                10_000 ether - tierSgx.validityBond + quarterReward
            );
        }

        console2.log("====== Verify the block");
        mineAndWrap(7 days);
        verifyBlock(1);
        {
            printBlockAndTrans(meta.id);

            TaikoData.BlockV2 memory blk = L1.getBlockV2(meta.id);

            assertEq(blk.nextTransitionId, 2);
            assertEq(blk.verifiedTransitionId, 1);

            TaikoData.TransitionState memory ts = L1.getTransition(meta.id, 1);
            assertEq(ts.blockHash, blockHash2);
            assertEq(ts.stateRoot, stateRoot2);
            assertEq(ts.tier, LibTiers.TIER_SGX);
            assertEq(ts.contester, address(0));
            assertEq(ts.validityBond, tierSgx.validityBond);
            assertEq(ts.prover, William);

            assertEq(totalTkoBalance(tko, L1, Alice), 10_000 ether - tierOp.validityBond);

            uint256 quarterReward = tierOp.validityBond * 7 / 8 / 4;
            assertEq(totalTkoBalance(tko, L1, Taylor), 10_000 ether + quarterReward * 3);
            assertEq(totalTkoBalance(tko, L1, William), 10_000 ether + quarterReward);
        }
    }
}
