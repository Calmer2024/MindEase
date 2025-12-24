import { WriteView } from '../view/WriteView';   // 引入写日记页面
import { HistoryView } from '../view/HistoryView'; // 引入历史页面

@Entry
@Component
struct Index {
  @State currentIndex: number = 0; // 当前选中的 Tab 索引
  private controller: TabsController = new TabsController();

  @State historyReloader: number = 0;

  // 自定义 Tab 样式函数
  @Builder TabBuilder(title: string, targetIndex: number, selectedImg: ResourceStr, normalImg: ResourceStr) {
    Column() {
      // 简单的图标+文字 (你可以换成你自己的图片，或者直接用 Emoji 代替)
      Text(targetIndex === 0 ? '📝' : '📂')
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
        WriteView() // 调用我们刚才拆分出来的组件
      }
      .tabBar(this.TabBuilder('写日记', 0, '', ''))

      // Tab 2: 历史记录
      TabContent() {
        HistoryView({ refreshTrigger: this.historyReloader }) // 调用历史列表组件
      }
      .tabBar(this.TabBuilder('历史', 1, '', ''))

    }
    .onChange((index: number) => {
      this.currentIndex = index;
      if (index === 1) {
        this.historyReloader++; // 数字变了，HistoryView 就会收到通知并刷新
      }
    })
    .scrollable(false) // 禁止左右滑动切换 (防止误触)
  }
}