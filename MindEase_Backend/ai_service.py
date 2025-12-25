# ai_service.py
import os
import json
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# 初始化客户端
client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url=os.getenv("DEEPSEEK_BASE_URL")
)


def analyze_diary_content(content: str) -> dict:
    """
    封装好的 AI 分析函数
    输入：日记内容
    输出：包含 mood 和 comment 的字典
    """
    print("🤖 正在呼叫 DeepSeek...")

    system_prompt = """
    你是一个温暖的心理咨询师。
    请分析用户的日记，并严格按照以下 JSON 格式返回结果，不要包含 markdown 标记或其他废话：
    {
        "mood": "情绪标签(如：开心/焦虑/难过/平静)",
        "comment": "一句简短温暖的心理咨询师风格的回复(50字以内)"
    }
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"日记内容：{content}"},
            ],
            temperature=0.7,
            stream=False
        )

        # 解析结果
        ai_text = response.choices[0].message.content
        ai_text = ai_text.replace("```json", "").replace("```", "").strip()
        result = json.loads(ai_text)

        print(f"✅ DeepSeek 分析成功: {result.get('mood')} - {result.get('comment')}")
        return result

    except Exception as e:
        print(f"❌ DeepSeek 调用失败: {e}")
        # 发生错误时的兜底返回
        return {
            "mood": "平静",
            "comment": "AI 暂时去休息了，但他依然在背后支持你。"
        }


# 生成周报的函数
def generate_weekly_summary(contents: list) -> str:
    """
    输入：一堆日记内容的列表
    输出：AI 生成的周报文本
    """
    if not contents:
        return "数据不足，无法生成周报。"

    print("📊 正在呼叫 AI 生成周报...")

    # 简单拼接日记内容 (为了节省 Token，每篇日记只取前 50 字)
    summary_text = "; ".join([c[:50] for c in contents])

    system_prompt = "你是一个专业的心理健康分析师。请根据用户的日记摘要，用第二人称('你')写一段简短温暖的心理健康周报(100字以内)，总结情绪变化并给出建议。"

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"日记摘要：{summary_text}"},
            ],
            temperature=0.7,
            stream=False
        )
        result = response.choices[0].message.content
        print("✅ 周报生成成功")
        return result

    except Exception as e:
        print(f"❌ AI 周报生成失败: {e}")
        return "AI 连接超时，无法生成周报。"