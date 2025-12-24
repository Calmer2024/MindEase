# main.py
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from datetime import datetime
from typing import Optional, List
import os
import json
from dotenv import load_dotenv
from openai import OpenAI

# =======================
# 1. 数据库配置
# =======================
# 1. 加载 .env 文件
load_dotenv()

# 2. 从环境变量获取配置
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

# 3. 拼接数据库连接串
SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# =======================
# 2. 数据库模型 (对应 MySQL 表)
# =======================
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
    ai_comment = Column(Text, nullable=True)  # AI回复
    ai_mood = Column(String(20), nullable=True)  # AI情绪标签
    created_at = Column(DateTime, default=datetime.now)


# 自动建表
Base.metadata.create_all(bind=engine)

# 初始化 DeepSeek 客户端
client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url=os.getenv("DEEPSEEK_BASE_URL")
)


# =======================
# 3. Pydantic 数据校验模型 (用于前后端交互)
# =======================
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
        from_attributes = True  # <--- 【修复2】消除黄色警告


# =======================
# 4. FastAPI 核心逻辑
# =======================
app = FastAPI()


# 依赖项：获取数据库会话
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/")
def read_root():
    return {"message": "MindEase Backend is Running!"}


# --- 核心接口：写日记 ---
@app.post("/diaries/", response_model=DiaryResponse)
def create_diary(diary: DiaryCreate, db: Session = Depends(get_db)):
    # --- 1. 调用 DeepSeek 进行分析 ---
    print("正在呼叫 DeepSeek...")

    # 构造提示词 (Prompt)
    system_prompt = """
    你是一个温暖的心理咨询师。
    请分析用户的日记，并严格按照以下 JSON 格式返回结果，不要包含 markdown 标记或其他废话：
    {
        "mood": "情绪标签(如：开心/焦虑/难过/平静)",
        "comment": "一句简短温暖的心理咨询师风格的回复(50字以内)"
    }
    """

    user_prompt = f"日记内容：{diary.content}"

    ai_mood_result = "未知"
    ai_comment_result = "AI 正在连接宇宙信号..."

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",  # DeepSeek V3 模型
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.7,
            stream=False
        )

        # 解析结果
        ai_text = response.choices[0].message.content
        # 清理 markdown 标记
        ai_text = ai_text.replace("```json", "").replace("```", "").strip()

        # 转为字典
        ai_data = json.loads(ai_text)
        ai_mood_result = ai_data.get("mood", "平静")
        ai_comment_result = ai_data.get("comment", "抱歉，我没读懂你的心事。")

        print(f"DeepSeek 分析成功: {ai_mood_result} - {ai_comment_result}")

    except Exception as e:
        print(f"DeepSeek 调用失败: {e}")

    # --- 2. 存入数据库 ---
    db_diary = DiaryDB(
        user_id=diary.user_id,
        content=diary.content,
        weather=diary.weather,
        mood_score=diary.mood_score,
        ai_comment=ai_comment_result,
        ai_mood=ai_mood_result
    )
    db.add(db_diary)
    db.commit()
    db.refresh(db_diary)
    return db_diary


# --- 核心接口：查日记列表 ---
@app.get("/diaries/{user_id}", response_model=List[DiaryResponse])
def get_diaries(user_id: int, db: Session = Depends(get_db)):
    diaries = db.query(DiaryDB).filter(DiaryDB.user_id == user_id).order_by(DiaryDB.created_at.desc()).all()
    return diaries


# =======================
# 5. 用户认证模块 (新增)
# =======================

# 定义登录/注册的数据模型
class UserAuth(BaseModel):
    username: str
    password: str
    nickname: Optional[str] = "新用户"


# --- 注册接口 ---
@app.post("/register")
def register(user: UserAuth, db: Session = Depends(get_db)):
    # 1. 检查用户名是否已存在
    db_user = db.query(UserDB).filter(UserDB.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="用户名已存在")

    # 2. 创建新用户
    new_user = UserDB(
        username=user.username,
        password=user.password,  # 大作业为了简单，我们先存明文。生产环境请用 Hash 加密！
        nickname=user.nickname
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "注册成功", "user_id": new_user.id}


# --- 登录接口 ---
@app.post("/login")
def login(user: UserAuth, db: Session = Depends(get_db)):
    # 1. 查找用户
    db_user = db.query(UserDB).filter(UserDB.username == user.username).first()

    # 2. 验证密码
    if not db_user or db_user.password != user.password:
        raise HTTPException(status_code=400, detail="账号或密码错误")

    # 3. 登录成功，返回用户ID和昵称
    return {
        "message": "登录成功",
        "user_id": db_user.id,
        "nickname": db_user.nickname
    }