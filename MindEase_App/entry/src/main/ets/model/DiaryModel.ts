export interface Diary {
  id: number;
  content: string;
  category: string;
  title?: string;
  mood_score: number;
  ai_comment?: string;
  created_at: string;
  is_deleted?: boolean;
  deleted_at?: string;
}

export interface DiaryPost {
  user_id: number;
  content: string;
  weather: string;
  mood_score: number;
  category: string;
}