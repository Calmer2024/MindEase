import { WriteView } from '../view/WriteView';
import { HistoryView } from '../view/HistoryView';
import { StatsView } from '../view/StatsView';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  @State historyReloader: number = 0;

  @Builder TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      // 如果当前由选中(currentIndex === targetIndex)，显示选中图，否则显示普通图
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain) // 保持图片比例
        .margin({ bottom: 4 }) // 图标和文字的间距

      // 文字逻辑
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#007DFF' : '#999999')
        .fontSize(10)
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(56) // 标准底部栏高度
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF') // 底部背景纯白
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.controller.changeIndex(targetIndex);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {

      // --- Tab 1: 写日记 ---
      TabContent() {
        WriteView()
      }
      .tabBar(this.TabBuilder(
        '写日记',
        0,
        $r('app.media.tab_write_sel'),
        $r('app.media.tab_write_norm')
      ))

      // --- Tab 2: 时光档案 ---
      TabContent() {
        HistoryView({ refreshTrigger: this.historyReloader })
      }
      .tabBar(this.TabBuilder(
        '时光档案',
        1,
        $r('app.media.tab_history_sel'),
        $r('app.media.tab_history_norm')
      ))

      // --- Tab 3: 情绪周报 ---
      TabContent() {
        StatsView({ refreshTrigger: this.historyReloader })
      }
      .tabBar(this.TabBuilder(
        '情绪周报',
        2,
        $r('app.media.tab_stats_sel'),
        $r('app.media.tab_stats_norm')
      ))

    }
    .onChange((index: number) => {
      this.currentIndex = index;
      if (index === 1 || index === 2) {
        this.historyReloader++;
      }
    })
    .scrollable(false)
    .backgroundColor('#F7F8FA')
  }
}