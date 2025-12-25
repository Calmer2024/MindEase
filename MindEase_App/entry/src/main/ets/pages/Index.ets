import { WriteView } from '../view/WriteView';
import { HistoryView } from '../view/HistoryView';
import { StatsView } from '../view/StatsView';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  // 信号变量
  @State historyReloader: number = 0;

  @Builder TabBuilder(title: string, targetIndex: number, selectedImg: ResourceStr, normalImg: ResourceStr) {
    Column() {
      Text(targetIndex === 0 ? '📝' : (targetIndex === 1 ? '📂' : '📊'))
        .fontSize(24)
        .margin({ bottom: 4 })
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#007DFF' : '#999999')
        .fontSize(12)
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.controller.changeIndex(targetIndex);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {

      // Tab 1: 写日记
      TabContent() {
        WriteView()
      }
      .tabBar(this.TabBuilder('写日记', 0, '', ''))

      // Tab 2: 历史记录
      TabContent() {
        HistoryView({ refreshTrigger: this.historyReloader })
      }
      .tabBar(this.TabBuilder('历史', 1, '', ''))

      // Tab 3: 统计分析
      TabContent() {
        // 只要 StatsView.ets 编译通过，这里的报错就会消失
        StatsView({ refreshTrigger: this.historyReloader })
      }
      .tabBar(this.TabBuilder('分析', 2, '', ''))

    }
    .onChange((index: number) => {
      this.currentIndex = index;
      // 切到历史或分析页时，都触发刷新
      if (index === 1 || index === 2) {
        this.historyReloader++;
      }
    })
    .scrollable(false)
  }
}