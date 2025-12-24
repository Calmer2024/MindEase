import { apiService } from '../services/ApiService';
import { Diary } from '../model/DiaryModel';
import promptAction from '@ohos.promptAction';

@Component
export struct WriteView {
  @State inputText: string = '';
  @State aiResult: string = '';
  @State isLoading: boolean = false;
  @State moodScore: number = 3;

  build() {
    Column() {
      // 标题
      Text('MindEase 智能心语')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 40, bottom: 20 })

      // 输入框
      TextArea({ placeholder: '在此写下今天发生的故事，DeepSeek 会倾听你的心声...' })
        .height(180)
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .fontSize(16)
        .padding(15)
        .onChange((value: string) => {
          this.inputText = value;
        })
        .margin({ bottom: 20 })

      // 心情滑块
      Row() {
        Text(`今日心情指数: ${this.moodScore}分`).fontSize(14).fontColor('#666')
      }
      .width('90%')
      .justifyContent(FlexAlign.Start)
      .margin({ bottom: 5 })

      Row() {
        Text('☹️').fontSize(20)
        Slider({
          value: this.moodScore,
          min: 1,
          max: 5,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('70%')
          .blockColor('#007DFF')
          .onChange((value: number) => {
            this.moodScore = value;
          })
        Text('😄').fontSize(20)
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 30 })

      // 按钮
      Button(this.isLoading ? '✨ AI 正在思考中...' : '生成 AI 治愈回信')
        .width('90%')
        .height(50)
        .fontSize(18)
        .backgroundColor(this.isLoading ? '#CCCCCC' : '#007DFF')
        .enabled(!this.isLoading)
        .shadow({ radius: 5, color: '#A0000000', offsetY: 5 })
        .onClick(async () => {
          await this.submitDiary();
        })

      // 结果卡片
      if (this.aiResult) {
        Column() {
          Row() {
            Text('🤖 AI 心理咨询师')
              .fontWeight(FontWeight.Bold)
              .fontSize(16)
              .fontColor('#007DFF')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Text(this.aiResult)
            .fontSize(16)
            .lineHeight(26)
            .fontColor('#333333')
        }
        .width('90%')
        .backgroundColor('#E6F2FF')
        .borderRadius(12)
        .padding(20)
        .margin({ top: 30 })
        .shadow({ radius: 10, color: '#20000000', offsetY: 5 })
      }
    }
    .width('100%')
    .height('100%')
  }

  async submitDiary() {
    if (this.inputText.trim() === '') {
      promptAction.showToast({ message: '写点什么吧~' });
      return;
    }
    this.isLoading = true;
    this.aiResult = '';
    try {
      const result = await apiService.createDiary(this.inputText, this.moodScore);
      if (result && result.ai_comment) {
        this.aiResult = result.ai_comment;
        promptAction.showToast({ message: '分析成功！' });
      } else {
        promptAction.showToast({ message: '请求成功，但 AI 未回复' });
      }
    } catch (err) {
      promptAction.showToast({ message: '网络错误' });
    } finally {
      this.isLoading = false;
    }
  }
}