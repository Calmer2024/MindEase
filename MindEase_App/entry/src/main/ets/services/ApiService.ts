// entry/src/main/ets/services/ApiService.ts
import http from '@ohos.net.http';
import { Diary } from '../model/DiaryModel';

const BASE_URL = 'http://10.138.156.106:8000';

export interface StatsData {
  dates: string[];
  scores: number[];
  weekly_summary: string;
}

class ApiService {
  // ✨ 新增：全局变量，存储当前登录的用户ID
  // 默认是 0 (未登录)，登录成功后会变成真实ID
  public currentUserId: number = 0;
  public currentNickname: string = '';

  // --- 1. 登录接口 ---
  async login(username: string, password: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/login`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ username: username, password: password }),
        expectDataType: http.HttpDataType.STRING
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        // ✨ 核心逻辑：登录成功，记住 ID ✨
        this.currentUserId = result.user_id;
        this.currentNickname = result.nickname;
        return true;
      }
    } catch (err) {
      console.error('Login Error:', JSON.stringify(err));
    }
    return false;
  }

  // --- 2. 注册接口 ---
  async register(username: string, password: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/register`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ username: username, password: password, nickname: "鸿蒙用户" }),
        expectDataType: http.HttpDataType.STRING
      });
      return response.responseCode === 200;
    } catch (err) {
      console.error('Register Error:', JSON.stringify(err));
      return false;
    }
  }

  // --- 3. 写日记 (已升级：使用动态 ID) ---
  async createDiary(content: string, moodScore: number,category: string): Promise<Diary | null> {
    if (this.currentUserId === 0) return null; // 未登录拦截

    const httpRequest = http.createHttp();
    const postData = {
      user_id: this.currentUserId, // ✨ 这里不再是 1 了，而是动态的！
      content: content,
      weather: "Sunny",
      mood_score: moodScore,
      category: category
    };

    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(postData),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 30000
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Diary;
      }
    } catch (err) {
      console.error('Create Diary Error:', JSON.stringify(err));
    }
    return null;
  }

  // --- 4. 查日记 (已升级：使用动态 ID) ---
  async getDiaries(): Promise<Diary[]> {
    if (this.currentUserId === 0) return [];

    const httpRequest = http.createHttp();
    try {
      // ✨ URL 里的 ID 也变动态了
      const response = await httpRequest.request(`${BASE_URL}/diaries/${this.currentUserId}`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Diary[];
      }
    } catch (err) {
      console.error('Get Diaries Error:', JSON.stringify(err));
    }
    return [];
  }
  // --- 5. 获取统计数据 ---
  async getStats(): Promise<StatsData | null> {
    if (this.currentUserId === 0) return null;

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/stats/${this.currentUserId}`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 30000 // AI 生成周报可能比较慢，多给点时间
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as StatsData;
      }
    } catch (err) {
      console.error('Get Stats Error:', JSON.stringify(err));
    }
    return null;
  }
}

export const apiService = new ApiService();