import { apiService, StatsData } from '../services/ApiService';

@Component
export struct StatsView {
  @State statsData: StatsData | null = null;
  @State isLoading: boolean = false;
  // 获取当前年月，用于日历显示
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth() + 1;
  @State daysInMonth: number[] = [];

  @Prop @Watch('onTriggerChange') refreshTrigger: number = 0;

  async aboutToAppear() {
    this.generateCalendar();
    this.fetchData();
  }

  onTriggerChange() {
    this.fetchData();
  }

  generateCalendar() {
    // 简单的日历逻辑：获取当月有多少天
    const days = new Date(this.currentYear, this.currentMonth, 0).getDate();
    const tempDays: number[] = [];
    for (let i = 1; i <= days; i++) {
      tempDays.push(i);
    }
    this.daysInMonth = tempDays;
  }

  async fetchData() {
    this.isLoading = true;
    this.statsData = await apiService.getStats();
    this.isLoading = false;
  }

  // 辅助函数：判断某一天是否有日记数据
  hasDiaryOnDay(day: number): boolean {
    if (!this.statsData || !this.statsData.dates) return false;
    // 假设后端返回格式包含 "MM-DD" 或 "YYYY-MM-DD"
    // 这里做一个简单的匹配逻辑，实际情况请根据后端格式调整
    const dayStr = day < 10 ? `0${day}` : `${day}`;
    // 检查返回的日期数组中是否包含这一天
    return this.statsData.dates.some(date => date.endsWith(`-${dayStr}`) || date.endsWith(`/${dayStr}`));
  }

  build() {
    // 使用 Scroll，防止内容过多超出屏幕
    Scroll() {
      Column() {
        // ---------------------------------------------------------
        // 1. 顶部标题区域 (高级感优化)
        // ---------------------------------------------------------
        Row() {
          Column() {
            Text('情绪周报')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .margin({ bottom: 4 })

            Text('看见情绪的每一次起伏') // 副标题
              .fontSize(14)
              .fontColor('#999999')
              .letterSpacing(1)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 顶部装饰图标
          Image($r('app.media.app_icon')) // 请准备对应的 png
            .width(48)
            .height(48)
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .padding({ top: 40, bottom: 20, left: 24, right: 24 })

        if (this.isLoading) {
          LoadingProgress().width(50).height(50).margin({ top: 100 })
        } else if (this.statsData && this.statsData.scores.length > 0) {

          // ---------------------------------------------------------
          // 2. 日历视图 (日记打卡情况)
          // ---------------------------------------------------------
          Column() {
            // 卡片标题
            Row() {
              Image($r('app.media.ic_calendar')) // 图标
                .width(20).height(20).margin({ right: 8 })
              Text(`${this.currentMonth}月 · 记录足迹`)
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            }
            .width('100%').margin({ bottom: 15 })

            // 日历网格
            Grid() {
              ForEach(this.daysInMonth, (day: number) => {
                GridItem() {
                  Column() {
                    Text(day.toString())
                      .fontSize(12)
                      .fontColor(this.hasDiaryOnDay(day) ? '#FFFFFF' : '#999') // 有日记显示白色，没有灰色
                      .fontWeight(this.hasDiaryOnDay(day) ? FontWeight.Bold : FontWeight.Normal)
                  }
                  .width(30)
                  .height(30)
                  .borderRadius(15) // 圆形
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.hasDiaryOnDay(day) ? '#007DFF' : 'transparent') // 有日记显示蓝色背景
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr') // 7列
            .rowsGap(10)
            .width('100%')
            .height(240) // 固定高度或自适应
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(20)
          .margin({ bottom: 15 })
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetY: 4 })

          // ---------------------------------------------------------
          // 3. AI 深度分析卡片
          // ---------------------------------------------------------
          Column() {
            Row() {
              Image($r('app.media.ic_ai_brain')) // AI 图标
                .width(20).height(20).margin({ right: 8 })
              Text('AI 深度分析')
                .fontWeight(FontWeight.Bold).fontSize(16).fontColor('#333')
            }
            .width('100%').margin({ bottom: 12 })

            Text(this.statsData.weekly_summary)
              .fontSize(15)
              .lineHeight(26) // 增加行高，阅读更舒适
              .fontColor('#444')
              .textAlign(TextAlign.Start)
          }
          .width('92%')
          .backgroundColor('#FFFFFF') // 或者使用微淡的蓝色 #F0F8FF 突出 AI 感
          .padding(20)
          .borderRadius(16)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetY: 4 })
          .margin({ bottom: 15 })

          // ---------------------------------------------------------
          // 4. 心情走势折线图
          // ---------------------------------------------------------
          Column() {
            Row() {
              Image($r('app.media.ic_trend_chart')) // 趋势图标
                .width(20).height(20).margin({ right: 8 })
              // ✅ 修改文案：不再强调“7天”，而是“近期”
              Text('近期心情走势')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            }
            .width('100%').margin({ bottom: 20 })

            // 图表容器
            Stack({ alignContent: Alignment.BottomStart }) {
              // 背景横线 (1分到5分)
              Column() {
                ForEach([5, 4, 3, 2, 1], (score: number) => {
                  Row() {
                    Text(score.toString()).fontSize(12).fontColor('#DDD').width(20)
                    // 虚线效果模拟：用灰色实线代替，或者自定义 Shape
                    Divider().vertical(false).strokeWidth(1).color('#F5F5F5').layoutWeight(1)
                  }
                  .width('100%')
                  .height(40) // 每一格的高度
                })
              }

              // 折线 Polyline
              Polyline()
                .width('100%')
                .height(200)
                .fillOpacity(0) // 不填充下方区域
                .stroke('#007DFF') // 蓝色线条
                .strokeWidth(3) // 加粗线条
                .strokeLineJoin(LineJoinStyle.Round) // 圆角连接，更平滑
                .strokeLineCap(LineCapStyle.Round)
                .points(this.convertScoresToPoints(this.statsData.scores))
                .margin({ left: 20 }) // 让开左侧数字的位置
            }
            .width('100%')
            .height(220)

            // 底部日期轴
            Row() {
              // 占位左侧数字宽度
              Blank().width(20)

              Row() {
                ForEach(this.statsData.dates, (date: string) => {
                  Text(date)
                    .fontSize(10)
                    .fontColor('#999')
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 10 })

          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .padding(20)
          .borderRadius(16)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetY: 4 })
          .margin({ bottom: 40 }) // 底部多留点白

        } else {
          // 空状态
          Column() {
            Image($r('app.media.ic_empty_state')) // 空状态图片
              .width(120).height(120).opacity(0.5)
            Text('暂无数据')
              .fontSize(16).fontColor('#999').margin({ top: 10 })
            Text('多写几篇日记，AI 才能分析哦~')
              .fontSize(12).fontColor('#CCC').margin({ top: 5 })
          }
          .margin({ top: 100 })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8') // 整体背景灰
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // --- 辅助函数 ---
  convertScoresToPoints(scores: number[]): Array<[number, number]> {
    const points: Array<[number, number]> = [];
    const chartHeight = 200;
    // 动态计算宽度，减去左侧文字边距
    // 注意：这里的宽度计算只是近似值，在 Polyline 中相对坐标比较重要
    const chartWidth = 300;

    // 如果只有一个点，放在中间
    if (scores.length <= 1) {
      points.push([chartWidth / 2, 200 - ((scores[0]) * 40) + 20]);
      return points;
    }

    const stepX = chartWidth / (scores.length - 1);

    scores.forEach((score, index) => {
      const x = index * stepX;
      // y轴计算：5分在最上面(y=20), 1分在最下面(y=180)
      // 假设每格高度40，5分对应 offset 0，1分对应 offset 160
      const y = 200 - ((score) * 40) + 20;
      points.push([x, y]);
    });
    return points;
  }
}