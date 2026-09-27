import axios from 'axios';

// ============================================================
// DATA ACCESS LAYER - Axios Base Client kết nối .NET Web API
// ============================================================

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7001/api';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Tự động gắn Token xác thực JWT (nếu có) vào Header mỗi Request
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('blush_jwt_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => Promise.reject(error));
