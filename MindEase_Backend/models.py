# models.py
from sqlalchemy import Column, Integer, String, Text, DateTime,Boolean
from datetime import datetime
from database import Base

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
    category = Column(String(50), default="生活")
    title = Column(String(50), nullable=True)
    ai_comment = Column(Text, nullable=True)
    ai_mood = Column(String(20), nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    is_deleted = Column(Boolean, default=False)  # 标记是否在回收站
    deleted_at = Column(DateTime, nullable=True)  # 什么时候删的