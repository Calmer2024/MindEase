import router from '@ohos.router';
import { apiService } from '../services/ApiService';
import { Diary } from '../model/DiaryModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct RecycleBinPage {
  @State trashList: Diary[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    this.trashList = await apiService.getTrashDiaries();
    this.isLoading = false;
  }

  // 计算剩余天数 (倒计时逻辑)
  getDaysLeft(deletedAt: string | undefined): number {
    if (!deletedAt) return 7;
    const delDate = new Date(deletedAt).getTime();
    const now = new Date().getTime();
    const diff = now - delDate;
    const daysPassed = Math.floor(diff / (1000 * 60 * 60 * 24));
    return Math.max(0, 7 - daysPassed);
  }

  build() {
    Column() {
      // 1. 标题栏
      Row() {
        // 返回按钮
        Image($r('app.media.ic_back'))
          .width(24).height(24)
          .onClick(() => router.back())

        Text('回收站')
          .fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
      }
      .width('100%').padding({ top: 50, left: 20, bottom: 20 })

      Text('项目将在 7 天后自动彻底删除')
        .fontSize(12).fontColor('#999').margin({ bottom: 20 })

      // 2. 列表内容
      if (this.isLoading) {
        LoadingProgress().width(30).height(30).margin({top: 100})
      } else if (this.trashList.length === 0) {
        Column() {
          Text('♻️').fontSize(50).margin({ bottom: 10 })
          Text('回收站是空的').fontSize(14).fontColor('#999')
        }.margin({ top: 100 })
      } else {
        List({ space: 12 }) {
          ForEach(this.trashList, (item: Diary) => {
            ListItem() {
              Column() {
                // 内容预览
                Row() {
                  Text(item.content).maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
                    .fontSize(16).fontColor('#333').layoutWeight(1)

                  // 剩余天数警告
                  Text(`${this.getDaysLeft(item.deleted_at)}天后清除`)
                    .fontSize(10).fontColor('#FF4D4F')
                }
                .width('100%').margin({ bottom: 10 })

                // 操作按钮区域
                Row() {
                  // 还原按钮
                  Button('还原')
                    .fontSize(12).height(28).backgroundColor('#E6F7FF').fontColor('#007DFF')
                    .onClick(async () => {
                      await apiService.restoreDiary(item.id);
                      this.loadData(); // 刷新列表
                      promptAction.showToast({ message: '已还原到时光档案' });
                    })

                  Blank().width(10)

                  // 彻底删除按钮
                  Button('彻底删除')
                    .fontSize(12).height(28).backgroundColor('#FFF0F0').fontColor('#FF4D4F')
                    .onClick(async () => {
                      AlertDialog.show({
                        title: '彻底删除',
                        message: '删除后无法找回，确定吗？',
                        primaryButton: { value: '取消', action: () => {} },
                        secondaryButton: {
                          value: '删除', fontColor: 'red',
                          action: async () => {
                            await apiService.hardDeleteDiary(item.id);
                            this.loadData();
                          }
                        }
                      })
                    })
                }
                .width('100%').justifyContent(FlexAlign.End)
              }
              .padding(16).backgroundColor('#FFF').borderRadius(12)
              .shadow({ radius: 5, color: 'rgba(0,0,0,0.05)' })
            }
          })
        }
        .width('90%').layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F7F8FA')
  }
}