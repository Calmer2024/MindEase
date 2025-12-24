import { apiService } from '../services/ApiService';
import { Diary } from '../model/DiaryModel';

@Component
export struct HistoryView {
  @Prop @Watch('onTriggerChange') refreshTrigger: number = 0;
  @State diaryList: Diary[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear() {
    this.fetchData();
  }

  onTriggerChange() {
    this.fetchData();
  }

  async fetchData() {
    // ⚠️ 注意：这里不要先清空 list，否则页面还是会白一下
    // this.diaryList = []; <--- 删掉这行

    this.isLoading = true;

    // 模拟一个小延迟，不然本地数据太快了看不出加载圈效果(可选)
    // await new Promise(resolve => setTimeout(resolve, 300));

    const result = await apiService.getDiaries();

    // ✨ 核心魔法：使用 animateTo 让数据变化带动画 ✨
    animateTo({ duration: 500, curve: Curve.FastOutSlowIn }, () => {
      this.diaryList = result;
      this.isLoading = false;
    })
  }

  build() {
    Column() {
      // 顶部标题
      Text('时光档案')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })
        .width('90%')

      // ✨ 使用 Stack 堆叠布局 ✨
      // 列表在下，加载圈在上。列表永远存在，不会消失，所以不会卡顿。
      Stack({ alignContent: Alignment.Top }) {

        // --- 层级 1: 列表内容 ---
        List({ space: 15 }) {
          ForEach(this.diaryList, (item: Diary) => {
            ListItem() {
              Column() {
                // 第一行：时间和ID
                Row() {
                  Text(item.created_at.split('T')[0])
                    .fontSize(12).fontColor('#999')
                  Text(`#${item.id}`)
                    .fontSize(12).fontColor('#ddd')
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .margin({ bottom: 8 })

                // 第二行：日记内容
                Text(item.content)
                  .fontSize(16)
                  .fontColor('#333')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .lineHeight(24)
                  .margin({ bottom: 10 })

                // 第三行：AI 回复 (如果有)
                if (item.ai_comment) {
                  Row() {
                    // 加一个小图标
                    Text('🤖')
                      .margin({ right: 5 })
                    Text(item.ai_comment)
                      .fontSize(13)
                      .fontColor('#007DFF')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1) // 占满剩余空间
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#F5F9FF') // 更清新的蓝色背景
                  .borderRadius(8)
                }
              }
              .width('100%')
              .padding(18)
              .backgroundColor('#FFFFFF')
              .borderRadius(16) // 更圆润的圆角
              // 添加一点阴影，更有质感
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
            }
            // ✨ 为每个列表项添加插入动画 ✨
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
          }, (item: Diary) => item.id.toString()) // ⚠️ 加上 Key 生成函数，提升性能
        }
        .width('90%')
        .height('100%')
        .scrollBar(BarState.Off) // 隐藏滚动条更美观

        // --- 层级 2: 加载指示器 (LoadingProgress) ---
        // 只有 isLoading 为 true 时才显示，且覆盖在列表上面
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .color('#007DFF')
              .width(40)
              .height(40)
          }
          .width('100%')
          .height(100) // 只遮挡顶部一点点区域，不影响整体
          .justifyContent(FlexAlign.Center)
          // 给加载圈本身也加一个淡入淡出动画
          .transition({ type: TransitionType.All, opacity: 0 })
          .hitTestBehavior(HitTestMode.None) // 让加载圈不阻挡下方列表的触摸（可选）
        }

      }
      .layoutWeight(1) // 占满剩余的所有垂直空间
      .width('100%')

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA') // 更加高级的灰白色背景
  }
}