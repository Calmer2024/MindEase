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