import { apiService } from '../services/ApiService';
import promptAction from '@ohos.promptAction';

// --- 1. 定义心情数据常量 ---
interface MoodOption {
  icon: Resource;
  score: number;
  label: string;
  color: string;
}

const MOOD_OPTIONS: MoodOption[] = [
  { icon: $r('app.media.mood_1'), score: 1, label: '糟糕', color: '#FFEBEE' },
  { icon: $r('app.media.mood_2'), score: 2, label: '低落', color: '#F3E5F5' },
  { icon: $r('app.media.mood_3'), score: 3, label: '平静', color: '#E3F2FD' },
  { icon: $r('app.media.mood_4'), score: 4, label: '开心', color: '#E8F5E9' },
  { icon: $r('app.media.mood_5'), score: 5, label: '极好', color: '#FFFDE7' },
];

const CATEGORIES = ['生活', '工作', '学习', '情感', '灵感'];

function getFormattedDate(): string[] {
  const now = new Date();
  const weekDays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
  const monthStr = (now.getMonth() + 1).toString().padStart(2, '0');
  const dateStr = now.getDate().toString().padStart(2, '0');
  const dayStr = weekDays[now.getDay()];
  return [`${monthStr}.${dateStr}`, dayStr];
}

@Component
export struct WriteView {
  @State inputText: string = '';
  @State aiResult: string = '';
  @State aiTitle: string = '';
  @State isLoading: boolean = false;
  @State selectedMoodIndex: number = 2;
  @State selectedCategory: string = '生活';
  @State dateInfo: string[] = getFormattedDate();

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 1. 全局背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F9F9F7')

      Scroll() {
        Column() {
          // ==============================
          // 1. 顶部日期大标题
          // ==============================
          Column() {
            Text(this.dateInfo[0])
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2C2C2C')
              .fontFamily('HarmonyOS Sans SC')

            Text(this.dateInfo[1])
              .fontSize(16)
              .fontColor('#888')
              .margin({ top: 4 ,left:2})
              .letterSpacing(1)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 20, bottom: 10 })
          .padding({ left: 24 })

          // ==============================
          // 2. 心情选择区
          // ==============================
          Column() {
            Row() {
              ForEach(MOOD_OPTIONS, (item: MoodOption, index: number) => {
                Column() {
                  // 图标容器
                  Column() {
                    Image(item.icon)
                      .width(28).height(28)
                      .opacity(this.selectedMoodIndex === index ? 1 : 0.4)
                  }
                  .width(52)
                  .height(52)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.selectedMoodIndex === index ? item.color : '#FFFFFF')
                  .borderRadius(26)
                  .shadow(this.selectedMoodIndex === index ? { radius: 10, color: item.color, offsetY: 4 } : { radius: 0 })
                  .animation({ duration: 300, curve: Curve.EaseOut })

                  Text(item.label)
                    .fontSize(12)
                    .fontColor(this.selectedMoodIndex === index ? '#333' : '#CCC')
                    .margin({ top: 8 })
                }
                .onClick(() => {
                  animateTo({ duration: 300 }, () => {
                    this.selectedMoodIndex = index;
                  })
                })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .padding({ left: 10, right: 10 })
          }
          .margin({ bottom: 20 })

          // ==============================
          // 3. “写信”区域
          // ==============================
          Column() {
            // 3.1 分类标签
            Row() {
              List({ space: 10 }) {
                ForEach(CATEGORIES, (tag: string) => {
                  ListItem() {
                    Text(tag)
                      .fontSize(13)
                      .fontColor(this.selectedCategory === tag ? '#FFF' : '#666')
                      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                      .backgroundColor(this.selectedCategory === tag ? '#2C3E50' : '#EFEFEF')
                      .borderRadius(16)
                      .onClick(() => this.selectedCategory = tag)
                      .animation({ duration: 200 })
                  }
                })
              }
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
              .height(40)
            }
            .padding({ left: 24, right: 24 })
            .margin({ bottom: 12 })

            // 3.2 输入框主体
            Column() {
              Column() {
                Text('Today is not bad')
                  .fontSize(14)
                  .fontColor('#B0B0B0')
                  .fontFamily('serif')
                  .margin({ bottom: 8 })

                Divider()
                  .color('#F0F0F0')
                  .strokeWidth(1)
                  .margin({ bottom: 15 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)

              // 真正的输入框
              TextArea({ placeholder: '你或许想说点什么...' })
                .height(220)
                .width('100%')
                .backgroundColor(Color.Transparent)
                .fontSize(17)
                .fontFamily('serif')
                .fontColor('#2C2C2C')
                .lineHeight(30)
                .padding(0)
                .borderWidth(0)
                .onChange((value: string) => this.inputText = value)
            }
            .padding(24)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 20, right: 20, bottom: 30 })
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
          }

          // ==============================
          // 4. "记录此刻" 按钮
          // ==============================
          Button() {
            Row() {
              if (this.isLoading) {
                LoadingProgress()
                  .color('#FFFFFF')
                  .width(20).height(20)
                  .margin({ right: 10 })
                Text('正在存入森林...')
                  .fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Medium)
              } else {
                Image($r('app.media.save'))
                  .width(20).height(20).margin({ right: 8 })
                  .fillColor('#FFF')
                Text('记录此刻')
                  .fontSize(16).fontColor('#FFF').fontWeight(FontWeight.Medium)
              }
            }
          }
          .width('90%')
          .height(56)
          .backgroundColor(this.isLoading ? '#5DADE2' : '#007DFF')
          .shadow(this.isLoading ? { radius: 0 } : { radius: 15, color: 'rgba(0,125,255,0.25)', offsetY: 5 })
          .onClick(async () => {
            await this.submitDiary();
          })
          .enabled(!this.isLoading)
          .animation({ duration: 300 })
          .margin({ bottom: 40 })

          // ==============================
          // 5. AI 回信
          // ==============================
          if (this.aiResult) {
            Column() {
              // 装饰线条
              Row()
                .width(40)
                .height(2)
                .backgroundColor('#DDD')
                .margin({ bottom: 20 })

              // 标题
              if (this.aiTitle) {
                Text(this.aiTitle)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                  .fontFamily('serif')
                  .margin({ bottom: 16 })
                  .textAlign(TextAlign.Center)
              }

              // 正文
              Text(this.aiResult)
                .fontSize(16)
                .fontColor('#444')
                .lineHeight(32)
                .letterSpacing(1)
                .fontFamily('serif')
                .textAlign(TextAlign.JUSTIFY)
                .width('100%')

              // 落款装饰
              Row() {
                Text('—— 来自森林的回响')
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ top: 20 })
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('90%')
            .padding({ top: 30, bottom: 30, left: 24, right: 24 })
            .backgroundColor('#FFFCF0')
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 5 })
            .borderRadius(2)
            .margin({ bottom: 60 })
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 30 } })
          }

        }
      }
      .scrollBar(BarState.Off)
      .height('100%')
    }
  }

  async submitDiary() {
    if (this.inputText.trim() === '') {
      promptAction.showToast({ message: '写下几个字吧，森林在听...' });
      return;
    }
    this.isLoading = true;
    this.aiResult = '';
    this.aiTitle = '';

    try {
      const currentScore = MOOD_OPTIONS[this.selectedMoodIndex].score;
      const result = await apiService.createDiary(this.inputText, currentScore, this.selectedCategory);

      if (result && result.ai_comment) {
        animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
          this.aiResult = result.ai_comment || '';
          this.aiTitle = result.title || '';
        })
        promptAction.showToast({ message: '已永久保存' });
      }
    } catch (err) {
      promptAction.showToast({ message: '连接中断' });
    } finally {
      this.isLoading = false;
    }
  }
}