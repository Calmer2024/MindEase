# main.py
from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from database import engine, get_db
import models
import schemas
# 👇 引入两个 AI 服务函数
from ai_service import analyze_diary_content, generate_weekly_summary

# 自动建表
models.Base.metadata.create_all(bind=engine)

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "MindEase Backend is Running!"}


# --- 注册接口 ---
@app.post("/register")
def register(user: schemas.UserAuth, db: Session = Depends(get_db)):
    db_user = db.query(models.UserDB).filter(models.UserDB.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="用户名已存在")

    new_user = models.UserDB(
        username=user.username,
        password=user.password,
        nickname=user.nickname
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "注册成功", "user_id": new_user.id}


# --- 登录接口 ---
@app.post("/login")
def login(user: schemas.UserAuth, db: Session = Depends(get_db)):
    db_user = db.query(models.UserDB).filter(models.UserDB.username == user.username).first()

    if not db_user or db_user.password != user.password:
        raise HTTPException(status_code=400, detail="账号或密码错误")

    return {
        "message": "登录成功",
        "user_id": db_user.id,
        "nickname": db_user.nickname
    }


# --- 写日记接口 ---
@app.post("/diaries/", response_model=schemas.DiaryResponse)
def create_diary(diary: schemas.DiaryCreate, db: Session = Depends(get_db)):
    # 1. 调用 AI 分析
    ai_result = analyze_diary_content(diary.content)

    # 2. 存入数据库
    db_diary = models.DiaryDB(
        user_id=diary.user_id,
        content=diary.content,
        weather=diary.weather,
        mood_score=diary.mood_score,
        ai_comment=ai_result.get("comment"),
        ai_mood=ai_result.get("mood")
    )
    db.add(db_diary)
    db.commit()
    db.refresh(db_diary)
    return db_diary


# --- 查日记列表接口 ---
@app.get("/diaries/{user_id}", response_model=List[schemas.DiaryResponse])
def get_diaries(user_id: int, db: Session = Depends(get_db)):
    diaries = db.query(models.DiaryDB).filter(models.DiaryDB.user_id == user_id).order_by(
        models.DiaryDB.created_at.desc()).all()
    return diaries


# --- 获取统计分析接口 (Clean Version) ---
@app.get("/stats/{user_id}", response_model=schemas.StatsResponse)  # 使用 schemas 里的定义
def get_stats(user_id: int, db: Session = Depends(get_db)):
    # 1. 查询数据库 (最近7条)
    diaries = db.query(models.DiaryDB) \
        .filter(models.DiaryDB.user_id == user_id) \
        .order_by(models.DiaryDB.created_at.desc()) \
        .limit(7) \
        .all()

    # 反转顺序，变成时间正序
    diaries = diaries[::-1]

    if not diaries:
        return {
            "dates": [],
            "scores": [],
            "weekly_summary": "还没有足够的日记数据来生成周报哦~"
        }

    # 2. 格式化数据
    dates = [d.created_at.strftime("%m-%d") for d in diaries]
    scores = [d.mood_score for d in diaries]
    contents = [d.content for d in diaries]

    # 3. 调用 AI 服务生成周报 (逻辑已经移到 ai_service.py 了)
    weekly_summary = generate_weekly_summary(contents)

    return {
        "dates": dates,
        "scores": scores,
        "weekly_summary": weekly_summary
    }