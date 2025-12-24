import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;

  build() {
    Column() {
      // Logo 或 标题
      Text('MindEase')
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor('#007DFF')
        .margin({ top: 100, bottom: 10 })

      Text('懂你的 AI 情绪日记')
        .fontSize(16)
        .fontColor('#999')
        .margin({ bottom: 50 })

      // 账号输入框
      TextInput({ placeholder: '请输入账号' })
        .width('85%')
        .height(50)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 20 })
        .onChange((value: string) => { this.username = value; })

      // 密码输入框
      TextInput({ placeholder: '请输入密码' })
        .width('85%')
        .height(50)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .type(InputType.Password) // 密码模式
        .margin({ bottom: 40 })
        .onChange((value: string) => { this.password = value; })

      // 登录按钮
      Button(this.isLoading ? '登录中...' : '登 录')
        .width('85%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#007DFF')
        .enabled(!this.isLoading)
        .onClick(async () => {
          await this.handleLogin();
        })

      // 注册入口
      Row() {
        Text('还没有账号？ ').fontColor('#999').fontSize(14)
        Text('立即注册')
          .fontColor('#007DFF')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .onClick(async () => {
            await this.handleRegister();
          })
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // 处理登录
  async handleLogin() {
    if (this.username === '' || this.password === '') {
      promptAction.showToast({ message: '账号密码不能为空' });
      return;
    }
    this.isLoading = true;
    const success = await apiService.login(this.username, this.password);
    this.isLoading = false;

    if (success) {
      promptAction.showToast({ message: '登录成功！' });
      // ✨ 跳转到主页 (Index)
      router.replaceUrl({ url: 'pages/Index' });
    } else {
      promptAction.showToast({ message: '登录失败，请检查账号密码' });
    }
  }

  // 处理注册 (为了简单，直接点击注册就调用注册接口)
  async handleRegister() {
    if (this.username === '' || this.password === '') {
      promptAction.showToast({ message: '请先输入要注册的账号和密码' });
      return;
    }
    this.isLoading = true;
    const success = await apiService.register(this.username, this.password);
    this.isLoading = false;

    if (success) {
      promptAction.showToast({ message: '注册成功，请点击登录' });
    } else {
      promptAction.showToast({ message: '注册失败，账号可能已存在' });
    }
  }
}