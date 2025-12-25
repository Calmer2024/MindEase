import router from '@ohos.router';
import { apiService } from '../services/ApiService';
import { Diary } from '../model/DiaryModel';

// 定义分组结构
interface DiaryGroup {
  category: string;
  items: Diary[];
  isExpanded: boolean;
}

@Component
export struct HistoryView {
  @Prop @Watch('onTriggerChange') refreshTrigger: number = 0;
  @State diaryGroups: DiaryGroup[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear() {
    this.fetchData();
  }

  onTriggerChange() {
    this.fetchData();
  }

  // 模拟根据分类获取图标的逻辑
  // 实际开发中请确保你在 resources/base/media 下有对应的 png 图片
  getCategoryIcon(category: string): Resource {
    switch (category) {
      case '生活': return $r('app.media.ic_life');
      case '学习': return $r('app.media.ic_study');
      case '情感': return $r('app.media.ic_emotion');
      case '工作': return $r('app.media.ic_work');
      case '灵感': return $r('app.media.ic_think');
      default: return $r('app.media.ic_default');
    }
  }

  async fetchData() {
    this.isLoading = true;
    const list = await apiService.getDiaries();
    const groups: DiaryGroup[] = [];
    const map = new Map<string, Diary[]>();

    list.forEach(diary => {
      const cat = diary.category || '未分类';
      if (!map.has(cat)) {
        map.set(cat, []);
      }
      map.get(cat)?.push(diary);
    });

    map.forEach((value, key) => {
      groups.push({
        category: key,
        items: value,
        isExpanded: false
      });
    });

    animateTo({ duration: 500, curve: Curve.FastOutSlowIn }, () => {
      this.diaryGroups = groups;
      this.isLoading = false;
    })
  }

  build() {
    Column() {
      // ---------------------------------------------------------
      // 1. 标题区域
      // ---------------------------------------------------------
      Row() {
        Column() {
          Text('时光档案')
            .fontSize(30) // 加大字号
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ bottom: 4 })

          // 增加副标题或日期，提升层次感
          Text('记录每一个当下的自己')
            .fontSize(14)
            .fontColor('#999999')
            .letterSpacing(1) // 增加字间距，显得更精致
        }
        .alignItems(HorizontalAlign.Start)

        Blank() // 占位符，把左右撑开

        // 右侧加一个装饰性的大图标或当前日期的日历图标
        Image($r('app.media.bg_history'))
          .width(40)
          .height(40)
          .borderRadius(12)
      }
      .width('100%')
      .padding({ top: 40, bottom: 20, left: 24, right: 24 }) // 增加左右边距
      .backgroundColor(Color.Transparent) // 保持通透

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 100 })
      } else {
        List({ space: 15 }) { // 减小一点间距，显得更紧凑
          ForEach(this.diaryGroups, (group: DiaryGroup, index: number) => {
            ListItemGroup({ header: this.GroupHeader(group, index) }) {
              ForEach(group.isExpanded ? group.items : group.items.slice(0, 2), (item: Diary) => {
                ListItem() {
                  this.DiaryCard(item) // 将卡片抽取为 Builder，代码更整洁
                }
                .margin({ bottom: 12 }) // 调整卡片间距
              })
            }
          })

          // 底部增加一点留白，防止最后一个元素紧贴屏幕底部
          ListItem().height(20)
        }
        .width('92%')
        .layoutWeight(1)
        .sticky(StickyStyle.None)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring) // 增加回弹效果，体验更好
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8') // 背景色稍微调灰一点点，提升质感
  }

  // ---------------------------------------------------------
  // 2. 带图标的分组标题
  // ---------------------------------------------------------
  @Builder GroupHeader(group: DiaryGroup, index: number) {
    Row() {
      // 左侧：图标 + 标题
      Row() {
        Image(this.getCategoryIcon(group.category))
          .width(20)
          .height(20)
          .margin({ right: 8 })
          .objectFit(ImageFit.Contain)

        Text(group.category)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text(`(${group.items.length})`)
          .fontSize(14)
          .fontColor('#999')
          .margin({ left: 6 })
          .alignSelf(ItemAlign.End) // 底部对齐，显得更协调
          .padding({ bottom: 2 })
      }

      // 右侧：折叠操作
      Row() {
        Text(group.isExpanded ? '收起' : '更多') // 简化文案
          .fontSize(13)
          .fontColor('#007DFF')
          .margin({ right: 4 })

        Text('▼')
          .fontSize(10)
          .fontColor('#007DFF')
          .rotate({ angle: group.isExpanded ? 180 : 0 })
          .animation({ duration: 200 })
      }
    }
    .width('100%')
    .padding({ top: 15, bottom: 10, left: 4, right: 4 }) // 调整内边距
    .backgroundColor('#F5F6F8') // 与背景色一致，制造悬浮感
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.diaryGroups[index] = {
          category: group.category,
          items: group.items,
          isExpanded: !group.isExpanded
        };
      })
    })
  }

  // 抽取卡片样式，保持主 build 函数干净
  @Builder DiaryCard(item: Diary) {
    Row() {
      // 装饰条
      Column()
        .width(4)
        .height(36)
        .backgroundColor('#007DFF')
        .borderRadius(2)
        .margin({ right: 14 })

      Column() {
        Text(item.content)
          .fontSize(16)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        Row() {
          Text(item.created_at.split('T')[0])
            .fontSize(12).fontColor('#B0B0B0').margin({ right: 10 })

          if (item.ai_comment) {
            Row() {
              Image($r('app.media.app_icon'))
                .width(12)
                .height(12)
                .margin({ right: 4 })
                .borderRadius(6)
              Text('AI已回复')
                .fontSize(10)
                .fontColor('#007DFF')
                .fontWeight(FontWeight.Medium)
            }
            .backgroundColor('#EAF4FF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头改为更轻的颜色
      Image($r('app.media.ic_right'))
        .width(16)
        .height(16)
        .fillColor('#DDD')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16) // 更圆润的圆角
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetY: 4 }) // 更柔和的阴影
    .onClick(() => {
      router.pushUrl({
        url: 'pages/DiaryDetailPage',
        params: { diary: item }
      });
    })
  }
}