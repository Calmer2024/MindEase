from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta

from database import engine, get_db
import models
import schemas
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
        category=diary.category,
        ai_comment=ai_result.get("comment"),
        ai_mood=ai_result.get("mood"),
        title=ai_result.get("title", "无题"),
        is_deleted=False  # 默认为未删除
    )
    db.add(db_diary)
    db.commit()
    db.refresh(db_diary)
    return db_diary


# --- 查日记列表接口 (只查未删除的) ---
@app.get("/diaries/{user_id}", response_model=List[schemas.DiaryResponse])
def get_diaries(user_id: int, db: Session = Depends(get_db)):
    # 增加过滤条件：is_deleted == False
    diaries = db.query(models.DiaryDB) \
        .filter(models.DiaryDB.user_id == user_id, models.DiaryDB.is_deleted == False) \
        .order_by(models.DiaryDB.created_at.desc()).all()
    return diaries


# --- 软删除接口  ---
@app.delete("/diaries/soft/{diary_id}")
def soft_delete_diary(diary_id: int, db: Session = Depends(get_db)):
    diary = db.query(models.DiaryDB).filter(models.DiaryDB.id == diary_id).first()
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")

    diary.is_deleted = True
    diary.deleted_at = datetime.now()  # 记录删除时间
    db.commit()
    return {"message": "已移入回收站"}


# --- 获取回收站列表  ---
@app.get("/diaries/trash/{user_id}", response_model=List[schemas.DiaryResponse])
def get_trash_diaries(user_id: int, db: Session = Depends(get_db)):
    # 1. 自动清理：检查有没有超过7天的，直接物理删除
    seven_days_ago = datetime.now() - timedelta(days=7)

    # 查出过期的
    expired = db.query(models.DiaryDB).filter(
        models.DiaryDB.user_id == user_id,
        models.DiaryDB.is_deleted == True,
        models.DiaryDB.deleted_at < seven_days_ago
    ).all()

    # 物理删除过期的
    for item in expired:
        db.delete(item)
    if expired:
        db.commit()

    # 2. 返回剩下的回收站内容
    trash_list = db.query(models.DiaryDB) \
        .filter(models.DiaryDB.user_id == user_id, models.DiaryDB.is_deleted == True) \
        .order_by(models.DiaryDB.deleted_at.desc()).all()
    return trash_list


# --- 还原日记 ---
@app.post("/diaries/restore/{diary_id}")
def restore_diary(diary_id: int, db: Session = Depends(get_db)):
    diary = db.query(models.DiaryDB).filter(models.DiaryDB.id == diary_id).first()
    if diary:
        diary.is_deleted = False
        diary.deleted_at = None
        db.commit()
    return {"message": "已还原"}


# --- 彻底删除 ---
@app.delete("/diaries/hard/{diary_id}")
def hard_delete_diary(diary_id: int, db: Session = Depends(get_db)):
    diary = db.query(models.DiaryDB).filter(models.DiaryDB.id == diary_id).first()
    if diary:
        db.delete(diary)  # 物理删除
        db.commit()
    return {"message": "彻底删除成功"}


# --- 获取统计分析接口 ---
@app.get("/stats/{user_id}", response_model=schemas.StatsResponse)
def get_stats(user_id: int, db: Session = Depends(get_db)):
    # 统计时也要过滤掉已删除的
    diaries = db.query(models.DiaryDB) \
        .filter(models.DiaryDB.user_id == user_id, models.DiaryDB.is_deleted == False) \
        .order_by(models.DiaryDB.created_at.desc()) \
        .limit(7) \
        .all()

    diaries = diaries[::-1]

    if not diaries:
        return {
            "dates": [],
            "scores": [],
            "weekly_summary": "还没有足够的日记数据来生成周报哦~"
        }

    dates = [d.created_at.strftime("%m-%d") for d in diaries]
    scores = [d.mood_score for d in diaries]
    contents = [d.content for d in diaries]

    weekly_summary = generate_weekly_summary(contents)

    return {
        "dates": dates,
        "scores": scores,
        "weekly_summary": weekly_summary
    }