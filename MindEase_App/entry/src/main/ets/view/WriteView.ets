import { apiService } from '../services/ApiService';
import { Diary } from '../model/DiaryModel';
import promptAction from '@ohos.promptAction';

// --- 1. 定义心情数据常量 ---
interface MoodOption {
  icon: string;
  score: number;
  label: string;
  color: string; // 选中时的背景色
}

const MOOD_OPTIONS: MoodOption[] = [
  { icon: '😫', score: 1, label: '糟糕', color: '#FFEBEE' }, // 红
  { icon: '😔', score: 2, label: '低落', color: '#F3E5F5' }, // 紫
  { icon: '😐', score: 3, label: '平静', color: '#E3F2FD' }, // 蓝
  { icon: '🙂', score: 4, label: '开心', color: '#E8F5E9' }, // 绿
  { icon: '🤩', score: 5, label: '极好', color: '#FFFDE7' }, // 黄
];

// --- 2. 获取当前格式化时间的工具函数 ---
function getFormattedDate(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  const date = now.getDate();
  const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  const day = weekDays[now.getDay()];
  return `${year}年${month}月${date}日 ${day}`;
}


@Component
export struct WriteView {
  @State inputText: string = '';
  @State aiResult: string = '';
  @State isLoading: boolean = false;
  // 当前选中的心情索引 (默认选中中间的“平静”)
  @State selectedMoodIndex: number = 2;
  // 页面加载时的时间
  @State todayDateStr: string = getFormattedDate();

  build() {
    // 使用 Stack做背景层叠
    Stack({ alignContent: Alignment.Top }) {
      // 背景色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F7F8FA') // 高级灰背景

      // 主体内容区域 (可滚动，防止内容过多顶出去)
      Scroll() {
        Column() {
          // --- 顶部 Header 区域 (时间和心情) ---
          Row() {
            // 左侧：自动时间戳
            Column() {
              Text(this.todayDateStr.split(' ')[0]) // 日期
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
              Text(this.todayDateStr.split(' ')[1]) // 星期
                .fontSize(14)
                .fontColor('#999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            // 右侧：心情选择器 (替代原来的滑块)
            Row({ space: 8 }) {
              ForEach(MOOD_OPTIONS, (item: MoodOption, index: number) => {
                // 心情图标按钮
                Column() {
                  Text(item.icon).fontSize(24)
                }
                .width(44)
                .height(44)
                .justifyContent(FlexAlign.Center)
                .borderRadius(22) // 圆形
                // 选中状态样式切换
                .backgroundColor(this.selectedMoodIndex === index ? item.color : '#FFFFFF')
                .border({
                  width: this.selectedMoodIndex === index ? 2 : 0,
                  color: '#007DFF'
                })
                .shadow(this.selectedMoodIndex === index ? { radius: 8, color: 'rgba(0,125,255,0.2)' } : { radius: 0 })
                .animation({ duration: 200 }) // 添加点击动画
                .onClick(() => {
                  this.selectedMoodIndex = index;
                })
              })
            }
            .backgroundColor('#FFFFFF')
            .padding(6)
            .borderRadius(30)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)' })

          }
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 20, bottom: 20 })

          // --- 核心编辑卡片 ---
          Column() {
            // 模拟标题栏 (虽然不存数据库，但在UI上显示)
            Text('今日随笔')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#999')
              .width('100%')
              .padding({ left: 15, top: 15 })

            Divider().color('#F0F0F0').margin({ top: 10, bottom: 5 })

            // 优化后的文本输入区域
            TextArea({ placeholder: '在这里记录此刻的想法，支持分段排版...' })
              .height(250) // 更高的高度
              .width('100%')
              .backgroundColor(Color.Transparent) // 透明背景，融入卡片
              .fontSize(17) // 更大的字号，便于阅读
              .fontColor('#333')
              .padding(15)
              // 移除默认的输入框边框线，看起来更像一张纸
              .borderWidth(0)
              .onChange((value: string) => {
                this.inputText = value;
              })
          }
          .width('90%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          // 添加柔和的阴影，营造悬浮感
          .shadow({ radius: 15, color: 'rgba(0,0,0,0.08)', offsetY: 5 })
          .margin({ bottom: 30 })


          // --- 提交按钮 ---
          Button(this.isLoading ? '✨ AI 正在用心思考...' : '生成 AI 治愈回信')
            .width('90%')
            .height(56) // 更高大上的按钮高度
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(this.isLoading ? '#E0E0E0' : '#007DFF')
            .enabled(!this.isLoading)
            // 渐变色阴影
            .shadow({ radius: 10, color: this.isLoading ? 'transparent' : 'rgba(0,125,255,0.4)', offsetY: 4 })
            .onClick(async () => {
              await this.submitDiary();
            })
            .animation({ duration: 200 }) // 按钮状态切换动画

          // --- AI 结果展示卡片 (优化版) ---
          if (this.aiResult) {
            Column() {
              Row() {
                Image($r('app.media.app_icon')) // 这里可以用你自己的AI图标，没有就用文字
                  .width(24).height(24).margin({right: 8})
                Text('AI 心理咨询师的回信')
                  .fontWeight(FontWeight.Bold)
                  .fontSize(16)
                  .fontColor('#007DFF')
              }
              .width('100%')
              .margin({ bottom: 15 })
              .alignItems(VerticalAlign.Center)

              // 使用 Text组件显示回复，设置行高和字间距提升阅读体验
              Text(this.aiResult)
                .fontSize(16)
                .lineHeight(28) // 更宽松的行高
                .letterSpacing(0.5)
                .fontColor('#444')
            }
            .width('90%')
            // 使用渐变背景色
            .linearGradient({
              angle: 180,
              colors: [['#F0F8FF', 0.0], ['#E6F2FF', 1.0]]
            })
            .borderRadius(16)
            .padding(20)
            .margin({ top: 30, bottom: 50 }) // 底部留白
            .shadow({ radius: 10, color: 'rgba(0,125,255,0.15)', offsetY: 5 })
            // 结果出现时的动画
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 30 } })
          }

        }
        .width('100%')
      }
      .scrollBar(BarState.Off) // 隐藏滚动条
      .align(Alignment.Top)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  async submitDiary() {
    if (this.inputText.trim() === '') {
      promptAction.showToast({ message: '写点什么吧，空的日记无法分析哦~' });
      return;
    }
    this.isLoading = true;
    this.aiResult = '';
    try {
      // 获取当前选中的心情分数
      const currentScore = MOOD_OPTIONS[this.selectedMoodIndex].score;

      const result = await apiService.createDiary(this.inputText, currentScore);

      if (result && result.ai_comment) {
        // 使用动画让结果平滑显示
        animateTo({ duration: 600, curve: Curve.FastOutSlowIn }, () => {
          this.aiResult = result.ai_comment || '';
        })
        promptAction.showToast({ message: '分析成功！' });
        // 可选：发送成功后清空输入框
        // this.inputText = '';
      } else {
        promptAction.showToast({ message: '请求成功，但 AI 未回复' });
      }
    } catch (err) {
      promptAction.showToast({ message: '网络错误，请检查连接' });
    } finally {
      animateTo({ duration: 300 }, () => {
        this.isLoading = false;
      })
    }
  }
}