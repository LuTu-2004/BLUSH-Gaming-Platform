import { apiClient } from '../api/apiClient';

// ============================================================
// BUSINESS SERVICE LAYER - Quest & Gamification Service
// Nhiệm vụ: Gọi API Backend .NET để điểm danh & tích điểm EXP
// ============================================================

export const questService = {
  // Nối API POST /api/quest/claim-daily từ .NET Backend
  async claimDailyReward(userId) {
    try {
      const response = await apiClient.post('/quest/claim-daily', { userId });
      return response.data;
    } catch (error) {
      console.warn('[Fallback Offline] Không thấy API Backend .NET, sử dụng dữ liệu giả lập!');
      return {
        success: true,
        message: 'Điểm danh thành công! (+15 Coins, +50 EXP)',
        addedCoins: 15,
        addedExp: 50
      };
    }
  }
};
