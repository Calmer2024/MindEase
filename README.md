# MindEase - 智能心语 (AI Mood Diary)

> 基于 HarmonyOS ArkUI + Python FastAPI + LLM 的智能情绪日记应用。

## 📖 项目简介
MindEase 是一款关注用户心理健康的智能日记应用。不同于传统的记录工具，它集成了大语言模型（LLM）能力。当用户记录日记时，AI 会自动感知文字中的情绪波动，并像心理咨询师一样给出暖心的回应与建议，同时生成情绪趋势图表，帮助用户可视化自己的心理状态。

## ✨ 核心功能
* **情绪记录**：支持文本日记记录，配合手动心情打分与天气记录。
* **AI 深度分析**：
    * 自动识别日记情感倾向（开心/焦虑/平静等）。
    * 智能提取关键事件。
    * 生成治愈系评语（基于文心一言/通义千问 API）。
* **数据可视化**：提供用户近期情绪趋势折线图，直观展示心理变化。
* **历史回顾**：时间轴形式展示过往日记与 AI 的互动记录。

## 🛠 技术栈

### 前端 (移动端)
* **系统**：HarmonyOS (API 9+)
* **语言**：ArkTS
* **框架**：ArkUI (声明式 UI)
* **网络**：@ohos.net.http

### 后端 (服务端)
* **语言**：Python 3.9+
* **框架**：FastAPI
* **数据库**：MySQL / SQLite
* **AI 接口**：Baidu Qianfan SDK / OpenAI Compatible API

## 📂 目录结构
```text
.
├── MindEase_App/        # 鸿蒙前端工程代码
│   ├── entry/src/main/  # ArkTS 源代码
│   └── ...
└── MindEase_Backend/    # Python 后端工程代码
    ├── main.py          # 后端启动入口
    ├── models.py        # 数据库模型
    └── ...
```

## 🚀 快速开始

### 1. 后端启动

```bash
cd MindEase_Backend
pip install -r requirements.txt
# 启动服务
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. 前端运行

1. 使用 **DevEco Studio** 打开 `MindEase_App` 目录。
2. 修改 `Constants.ts` 中的 `BASE_URL` 为你电脑的局域网 IP 地址。
3. 启动模拟器或连接真机进行调试。

## 👨‍💻 开发者

Calmer2024