import router from '@ohos.router';
import { Diary } from '../model/DiaryModel';

@Entry
@Component
struct DiaryDetailPage {
  // 接收参数
  @State diary: Diary = (router.getParams() as Record<string, Object>)['diary'] as Diary;

  // 页面是否加载完成
  @State isPageLoaded: boolean = false;

  aboutToAppear() {
    setTimeout(() => {
      this.isPageLoaded = true;
    }, 100)
  }

  // --- 资源映射函数 ---

  getMoodImage(score: number): Resource {
    const resources: Resource[] = [
      $r('app.media.mood_1'),
      $r('app.media.mood_2'),
      $r('app.media.mood_3'),
      $r('app.media.mood_3'),
      $r('app.media.mood_5')
    ];
    return resources[score - 1] || $r('app.media.app_icon');
  }

  getTagColor(score: number): string {
    const colors = ['#FFEBEE', '#F3E5F5', '#E3F2FD', '#E8F5E9', '#FFFDE7'];
    return colors[score - 1] || '#F0F0F0';
  }

  getArticleTitle(): string {
    // 1. 如果数据库里存了 AI 生成的标题，直接用
    if (this.diary.title && this.diary.title !== '无题') {
      return this.diary.title || '';
    }

    // 2. 如果是老日记没有标题，回退到自动生成逻辑
    const date = new Date(this.diary.created_at);
    const hour = date.getHours();
    let timePrefix = '今日';
    if (hour < 9) timePrefix = '清晨';
    else if (hour < 13) timePrefix = '上午';
    else if (hour < 18) timePrefix = '午后';
    else timePrefix = '深夜';

    return `${timePrefix}，关于“${this.diary.category}”的记录`;
  }

  getFormattedTime(): string {
    return this.diary.created_at.replace('T', ' ').substring(0, 16);
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 背景层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F7F8FA')

      // 顶部导航栏
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.8)')
        .onClick(() => {
          router.back();
        })

      }
      .width('100%')
      .padding({ top: 30, left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
      .zIndex(10)

      // --- 主内容滚动区 ---
      Scroll() {
        Column() {
          Blank().height(80)

          // 大卡片区域
          Column() {

            // 1. 标题区
            Text(this.getArticleTitle())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .lineHeight(32)
              .width('100%')
              .margin({ bottom: 15 })

            // 2. 信息栏
            Row() {
              Text(this.getFormattedTime())
                .fontSize(14)
                .fontColor('#999')
                .margin({ right: 15 })

              Text(this.diary.category)
                .fontSize(12)
                .fontColor('#555')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(this.getTagColor(this.diary.mood_score))
                .borderRadius(6)
                .margin({ right: 10 })

              Image(this.getMoodImage(this.diary.mood_score))
                .width(20)
                .height(20)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 30 })

            // 3. 正文内容
            Text(this.diary.content)
              .fontSize(18)
              .fontColor('#333')
              .lineHeight(34)
              .letterSpacing(1)
              .width('100%')
              .margin({ bottom: 40 })

            // 4. 分割线
            Divider()
              .color('#F0F0F0')
              .strokeWidth(1)
              .margin({ bottom: 30 })

            // 5. AI 治愈区
            if (this.diary.ai_comment) {
              Column() {
                Row() {
                  Image($r('app.media.app_icon'))
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .margin({ right: 8 })

                  Text('AI 暖心寄语')
                    .fontSize(14)
                    .fontColor('#007DFF')
                    .fontWeight(FontWeight.Medium)
                }
                .width('100%')
                .margin({ bottom: 12 })

                Text(this.diary.ai_comment)
                  .fontSize(16)
                  .fontColor('#666')
                  .lineHeight(28)
              }
              .width('100%')
              .padding(20)
              .backgroundColor('#F9FBFF')
              .borderRadius(12)
              .opacity(this.isPageLoaded ? 1 : 0)
              .animation({ duration: 800, delay: 200, curve: Curve.EaseOut })
            }

          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius({ topLeft: 24, topRight: 24 })
          .padding({ left: 24, right: 24, top: 30, bottom: 50 })
          .shadow({ radius: 30, color: 'rgba(0,0,0,0.05)', offsetY: -10 })
          .translate({ y: this.isPageLoaded ? 0 : 100 })
          .opacity(this.isPageLoaded ? 1 : 0)
          .animation({ duration: 600, curve: Curve.FastOutSlowIn })
          .constraintSize({ minHeight: '100%' })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  pageTransition() {
    PageTransitionEnter({ duration: 400, curve: Curve.Smooth })
      .slide(SlideEffect.Bottom)
    PageTransitionExit({ duration: 400, curve: Curve.Smooth })
      .slide(SlideEffect.Bottom)
  }
}