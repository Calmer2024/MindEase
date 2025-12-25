import router from '@ohos.router';
import { apiService } from '../services/ApiService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct LoginPage {
  @State isLogin: boolean = true; // true=登录模式, false=注册模式
  @State username: string = '';
  @State password: string = '';
  @State nickname: string = '';
  @State isLoading: boolean = false;

  build() {
    Stack() {
      // 背景图或背景色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F7F8FA')

      Column() {
        // 1. Logo / 标题区域
        Column() {
          Image($r('app.media.app_icon'))
            .width(80)
            .height(80)
            .borderRadius(20)
            .margin({ bottom: 20 })
            .shadow({ radius: 20, color: 'rgba(0,125,255,0.2)' })

          Text('MindEase')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Text(this.isLogin ? '欢迎回到心灵森林' : '创建你的专属树洞')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 8 })
        }
        .margin({ top: 80, bottom: 50 })

        // 2. 输入表单卡片
        Column({ space: 15 }) {

          if (!this.isLogin) {
            TextInput({ placeholder: '昵称' })
              .height(50)
              .backgroundColor('#F5F7F9')
              .borderRadius(12)
              .onChange((value: string) => {
                this.nickname = value;
              })
              .animation({ duration: 300 }) // 添加显示动画
          }

          // 账号输入框
          TextInput({ placeholder: '账号 / 用户名' })
            .height(50)
            .backgroundColor('#F5F7F9')
            .borderRadius(12)
            .onChange((value: string) => {
              this.username = value;
            })

          // 密码输入框
          TextInput({ placeholder: '密码' })
            .type(InputType.Password)
            .height(50)
            .backgroundColor('#F5F7F9')
            .borderRadius(12)
            .onChange((value: string) => {
              this.password = value;
            })

          // 3. 登录/注册 按钮
          Button(this.isLoading ? '处理中...' : (this.isLogin ? '登 录' : '立即注册'))
            .width('100%')
            .height(50)
            .backgroundColor('#007DFF')
            .margin({ top: 20 })
            .shadow({ radius: 10, color: 'rgba(0,125,255,0.3)', offsetY: 5 })
            .onClick(async () => {
              await this.handleAction();
            })
            .enabled(!this.isLoading)

          // 4. 切换模式文字
          Row() {
            Text(this.isLogin ? '还没有账号？' : '已有账号？')
              .fontColor('#999')
              .fontSize(14)
            Text(this.isLogin ? '去注册' : '去登录')
              .fontColor('#007DFF')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                animateTo({ duration: 300 }, () => {
                  this.isLogin = !this.isLogin;
                })
              })
          }
          .margin({ top: 20 })
          .justifyContent(FlexAlign.Center)
          .width('100%')

        }
        .width('90%')
        .padding(25)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.05)' })

      }
      .width('100%')
      .height('100%')
    }
  }

  // 处理登录或注册逻辑
  async handleAction() {
    if (this.username === '' || this.password === '') {
      promptAction.showToast({ message: '请输入账号和密码' });
      return;
    }

    // 如果是注册，还要检查昵称
    if (!this.isLogin && this.nickname === '') {
      promptAction.showToast({ message: '请输入昵称' });
      return;
    }

    this.isLoading = true;

    try {
      if (this.isLogin) {
        // --- 登录逻辑 ---
        const success = await apiService.login(this.username, this.password);
        if (success) {
          promptAction.showToast({ message: '欢迎回来！' });
          router.replaceUrl({ url: 'pages/Index' });
        } else {
          promptAction.showToast({ message: '登录失败，请检查账号密码' });
        }
      } else {
        const success = await apiService.register(this.username, this.password, this.nickname);
        if (success) {
          promptAction.showToast({ message: '注册成功，请登录' });
          this.isLogin = true; // 注册成功后切换回登录界面
        } else {
          promptAction.showToast({ message: '注册失败，用户名可能已存在' });
        }
      }
    } catch (err) {
      promptAction.showToast({ message: '网络请求错误' });
    } finally {
      this.isLoading = false;
    }
  }
}