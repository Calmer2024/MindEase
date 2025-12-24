# schemas.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# --- 日记相关 ---
class DiaryCreate(BaseModel):
    user_id: int
    content: str
    weather: str
    mood_score: int

class DiaryResponse(BaseModel):
    id: int
    content: str
    ai_comment: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# --- 用户相关 ---
class UserAuth(BaseModel):
    username: str
    password: str
    nickname: Optional[str] = "新用户"