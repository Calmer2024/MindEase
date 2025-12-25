import { apiService, StatsData } from '../services/ApiService';

@Component
export struct StatsView {
  @State statsData: StatsData | null = null;
  @State isLoading: boolean = false;
  // 接收主页传来的刷新信号
  @Prop @Watch('onTriggerChange') refreshTrigger: number = 0;

  async aboutToAppear() {
    this.fetchData();
  }

  onTriggerChange() {
    this.fetchData();
  }

  async fetchData() {
    this.isLoading = true;
    this.statsData = await apiService.getStats();
    this.isLoading = false;
  }

  build() {
    Column() {
      Text('情绪周报')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })
        .width('90%')

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 100 })
      } else if (this.statsData && this.statsData.scores.length > 0) {

        // --- 1. AI 总结卡片 ---
        Column() {
          Row() {
            Text('🧠 AI 深度分析').fontWeight(FontWeight.Bold).fontColor('#007DFF')
          }
          .width('100%').margin({ bottom: 10 })

          Text(this.statsData.weekly_summary)
            .fontSize(15)
            .lineHeight(24)
            .fontColor('#333')
        }
        .width('90%')
        .backgroundColor('#fff')
        .padding(15)
        .borderRadius(12)
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)' })
        .margin({ bottom: 30 })

        // --- 2. 手绘折线图区域 ---
        Column() {
          Text('近7天心情走势').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 20 })

          // 图表容器
          Stack({ alignContent: Alignment.BottomStart }) {
            // 背景横线 (1分到5分)
            Column() {
              ForEach([5, 4, 3, 2, 1], (score: number) => {
                Row() {
                  Text(score.toString()).fontSize(12).fontColor('#ccc').width(20)
                  Divider().vertical(false).strokeWidth(1).color('#f0f0f0').layoutWeight(1)
                }
                .width('100%')
                .height(40) // 每行高度
              })
            }

            // 核心：折线 Polyline
            // ✅【修复点1】这里不能在 {} 里写 points，必须用 .points() 链式调用
            Polyline()
              .width('100%')
              .height(200)
              .fillOpacity(0)
              .stroke(Color.Blue)
              .strokeWidth(3)
              .points(this.convertScoresToPoints(this.statsData.scores)) // points 必须在这里传
          }
          .width('90%')
          .height(220)

          // 底部日期
          Row() {
            ForEach(this.statsData.dates, (date: string) => {
              Text(date).fontSize(10).fontColor('#999').layoutWeight(1).textAlign(TextAlign.Center)
            })
          }
          .width('90%')
          .margin({ top: 5 })

        }
        .width('90%')
        .backgroundColor('#fff')
        .padding(15)
        .borderRadius(12)
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)' })

      } else {
        // 没有数据时的空状态
        Column() {
          Text('📊').fontSize(50)
          Text('多写几篇日记，AI 才能为你生成周报哦~')
            .fontSize(14).fontColor('#999').margin({ top: 10 })
        }
        .margin({ top: 100 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  // --- 辅助函数 ---
  // ✅【修复点2】明确返回值类型为 Array<[number, number]>，消除 TS 报错
  convertScoresToPoints(scores: number[]): Array<[number, number]> {
    const points: Array<[number, number]> = [];
    const chartHeight = 200;
    const chartWidth = 300;
    const stepX = chartWidth / (scores.length - 1 || 1);

    scores.forEach((score, index) => {
      const x = index * stepX;
      // y轴翻转计算
      const y = 200 - ((score) * 40) + 20;
      points.push([x, y]);
    });
    return points;
  }
}