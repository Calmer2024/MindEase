import http from '@ohos.net.http';
import { Diary } from '../model/DiaryModel';

const BASE_URL = 'http://10.138.156.106:8000';

export interface StatsData {
  dates: string[];
  scores: number[];
  weekly_summary: string;
}

class ApiService {
  public currentUserId: number = 0;
  public nickname: string = '';

  // 1. 登录
  async login(username: string, password: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/login`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: { username, password }
      });
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        this.currentUserId = result.user_id;
        this.nickname = result.nickname;
        return true;
      }
    } catch (err) { console.error('Login Error:', err); }
    return false;
  }

  // 2. 注册
  async register(username: string, password: string, nickname: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/register`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: { username, password, nickname }
      });
      return response.responseCode === 200;
    } catch (err) { return false; }
  }

  // 3. 写日记
  async createDiary(content: string, moodScore: number, category: string): Promise<Diary | null> {
    if (this.currentUserId === 0) return null;
    const httpRequest = http.createHttp();
    const postData = {
      user_id: this.currentUserId,
      content: content,
      weather: "Sunny",
      mood_score: moodScore,
      category: category
    };
    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: postData,
        readTimeout: 30000
      });
      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Diary;
      }
    } catch (err) {}
    return null;
  }

  // 4. 获取日记列表
  async getDiaries(): Promise<Diary[]> {
    if (this.currentUserId === 0) return [];
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/${this.currentUserId}`, {
        method: http.RequestMethod.GET
      });
      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Diary[];
      }
    } catch (err) {}
    return [];
  }

  // 5. 获取统计
  async getStats(): Promise<StatsData | null> {
    if (this.currentUserId === 0) return null;
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/stats/${this.currentUserId}`, {
        method: http.RequestMethod.GET,
        readTimeout: 30000
      });
      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as StatsData;
      }
    } catch (err) {}
    return null;
  }

  // 6. 软删除 (移入回收站)
  async deleteDiary(diaryId: number): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/soft/${diaryId}`, {
        method: http.RequestMethod.DELETE
      });
      return response.responseCode === 200;
    } catch (err) { return false; }
  }

  // 7. 获取回收站列表
  async getTrashDiaries(): Promise<Diary[]> {
    if (this.currentUserId === 0) return [];
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/trash/${this.currentUserId}`, {
        method: http.RequestMethod.GET
      });
      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Diary[];
      }
    } catch (err) {}
    return [];
  }

  // 8. 还原日记
  async restoreDiary(diaryId: number): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/restore/${diaryId}`, {
        method: http.RequestMethod.POST
      });
      return response.responseCode === 200;
    } catch (err) { return false; }
  }

  // 9. 彻底删除
  async hardDeleteDiary(diaryId: number): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/diaries/hard/${diaryId}`, {
        method: http.RequestMethod.DELETE
      });
      return response.responseCode === 200;
    } catch (err) { return false; }
  }
}

export const apiService = new ApiService();