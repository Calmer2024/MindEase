# models.py
from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime
from database import Base  # 👈 从刚才的文件引入

class UserDB(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True)
    password = Column(String(100))
    nickname = Column(String(50))

class DiaryDB(Base):
    __tablename__ = "diaries"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer)
    content = Column(Text)
    weather = Column(String(20))
    mood_score = Column(Integer)
    ai_comment = Column(Text, nullable=True)
    ai_mood = Column(String(20), nullable=True)
    created_at = Column(DateTime, default=datetime.now)