import router from '@ohos.router';
import { apiService } from '../services/ApiService';
import { Diary } from '../model/DiaryModel';
import promptAction from '@ohos.promptAction';

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

  // 获取分类图标
  getCategoryIcon(category: string): Resource {
    switch (category) {
      case '生活': return $r('app.media.ic_life');
      case '学习': return $r('app.media.ic_study');
      case '情感': return $r('app.media.ic_emotion');
      case '工作': return $r('app.media.ic_work');
      case '灵感': return $r('app.media.ic_think');
      default: return $r('app.media.app_icon');
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

  // 删除确认逻辑
  async confirmDelete(item: Diary) {
    AlertDialog.show({
      title: '移入回收站',
      message: '确定要删除这条日记吗？\n可以在回收站内找回。',
      primaryButton: { value: '再想想', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4D4F',
        action: async () => {
          const success = await apiService.deleteDiary(item.id);
          if (success) {
            promptAction.showToast({ message: '已移入回收站' });
            this.fetchData(); // 刷新列表
          } else {
            promptAction.showToast({ message: '删除失败' });
          }
        }
      }
    })
  }

  build() {
    Column() {
      // ============================================
      // 1. 标题区域
      // ============================================
      Row() {
        // 左侧：标题 + 副标题 + 回收站按钮
        Column() {
          Text('时光档案')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ bottom: 4 })

          Text('记录每一个当下的自己')
            .fontSize(14)
            .fontColor('#999999')
            .letterSpacing(1)
            .margin({ bottom: 12 })

          // 回收站按钮
          Row() {
            Image($r('app.media.ic_recycle_bin'))
              .width(14)
              .height(14)
              .fillColor('#666')
              .margin({ right: 4 })

            Text('回收站')
              .fontSize(12)
              .fontColor('#666')
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .shadow({ radius: 5, color: 'rgba(0,0,0,0.05)' })
          .onClick(() => {
            router.pushUrl({ url: 'pages/RecycleBinPage' });
          })
        }
        .alignItems(HorizontalAlign.Start)

        Blank() // 撑开左右空间

        // 显示 bg_history 装饰图
        Image($r('app.media.bg_history'))
          .width(60)  // 稍微调大一点，更有氛围
          .height(60)
          .objectFit(ImageFit.Contain)
          .opacity(0.8) // 稍微透明一点，不抢视觉重心
      }
      .width('100%')
      .padding({ top: 40, bottom: 10, left: 24, right: 24 })
      .alignItems(VerticalAlign.Top)
      .backgroundColor(Color.Transparent)

      // ============================================
      // 2. 列表内容
      // ============================================
      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 100 })
      } else {
        List({ space: 15 }) {
          ForEach(this.diaryGroups, (group: DiaryGroup, index: number) => {
            ListItemGroup({ header: this.GroupHeader(group, index) }) {
              ForEach(group.isExpanded ? group.items : group.items.slice(0, 2), (item: Diary) => {
                ListItem() {
                  this.DiaryCard(item)
                }
                .margin({ bottom: 12 })
              })
            }
          })
          ListItem().height(20)
        }
        .width('92%')
        .layoutWeight(1)
        .sticky(StickyStyle.None)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  // 分组头部
  @Builder GroupHeader(group: DiaryGroup, index: number) {
    Row() {
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
          .alignSelf(ItemAlign.End)
          .padding({ bottom: 2 })
      }

      Row() {
        Text(group.isExpanded ? '收起' : '更多')
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
    .padding({ top: 15, bottom: 10, left: 4, right: 4 })
    .backgroundColor('#F5F6F8')
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

  // 日记卡片
  @Builder DiaryCard(item: Diary) {
    Row() {
      // 蓝色装饰条
      Column()
        .width(4)
        .height(36)
        .backgroundColor('#007DFF')
        .borderRadius(2)
        .margin({ right: 14 })

      // 中间文字区域
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
      .onClick(() => {
        router.pushUrl({
          url: 'pages/DiaryDetailPage',
          params: { diary: item }
        });
      })

      // 删除按钮区域
      Row() {
        Divider().vertical(true).height(20).color('#EEE').margin({ left: 10, right: 10 })

        Image($r('app.media.ic_delete'))
          .width(18)
          .height(18)
          .fillColor('#FF4D4F')
          .onClick(() => {
            this.confirmDelete(item);
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetY: 4 })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.confirmDelete(item);
        })
    )
  }
}