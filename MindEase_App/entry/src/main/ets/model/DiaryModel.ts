// 定义日记的数据结构（对应后端的 JSON）
export interface Diary {
  id: number;
  content: string;
  ai_comment?: string; // 可能为空
  created_at: string;
}

// 定义发送给后端的结构
export interface DiaryPost {
  user_id: number;
  content: string;
  weather: string;
  mood_score: number;
}