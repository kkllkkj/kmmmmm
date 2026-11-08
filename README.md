# 小虎陪伴

macOS 13+ 原生桌面宠物，SwiftUI + AppKit，无第三方运行依赖。

## 构建

```sh
./scripts/build-app.sh
```

双击 `dist/小虎陪伴.app`。菜单栏 🐯 打开任务与每日复盘，或隐藏、退出小虎。

## 使用

- 形象：金黄毛绒、黑圆耳、白脸颊、蓝色无袖上衣。点击随机打招呼、摸头或 wink；拖动小虎改变位置。
- 自主生活：间隔触发跑跳、伸展、睡觉及才艺。右键也可选择动作；小虎睡觉时点击可唤醒。
- 任务：添加后点击“开始”，按关键词选择学习、锻炼或普通陪伴，也可手动指定。学习时在书桌前看书/电脑，锻炼时举哑铃。
- 专注：支持暂停、继续、结束。结束显示共同陪伴时长，写入“陪伴记录”。结束计时不会自动完成任务；勾选完成才领奖，每项只领一次。直接完成正在计时的任务，会先结束并记录时长。
- 中断：系统休眠时暂停，重启后恢复为暂停状态；运行时每 10 秒检查点保存，意外退出可能丢失最近 10 秒。睡眠后需手动继续。
- 食堂：16 种食物单独购买、库存与投喂。奶茶、拉面、烤红薯有热气效果。免费饭团保留，旧饭团库存仍可使用。投喂增加亲密度。
- 日常话语：收录用户提供的 18 句话，避免连续重复。自动间隔可以调整或关闭，也可点击“听小虎说”。
- 才艺：持话筒唱歌、桌前写歌、跳舞的姿态及互动台词，无音频输出。
- 安静陪伴：降低动画刷新、停止自主活动和随机话语。设置在“照顾小虎”。
- 全屏：通过窗口大小识别前台全屏应用并减少活动；默认不进入其他应用的全屏空间。不同应用的全屏实现可能影响识别。
- 复盘：按日期记录心情、值得学习的东西、给自己的话，点击保存后可回看。

## 数据与验证

数据保存在 `~/Library/Application Support/TigerPet/data.json`，不联网。兼容最初版本的积分、任务、背包、复盘存档。应用退出时保存并暂停计时；不要同时运行多个副本。

```sh
swift build --scratch-path /tmp/tigerpet-build
/tmp/tigerpet-build/debug/TigerPet --self-test
/tmp/tigerpet-build/debug/TigerPet --preview preview-plush.png
```

自检覆盖重复领奖、余额、库存、投喂、读写、旧存档兼容、任务识别、暂停继续与计时总结。自动化图像预览用于检查素材裁切。

当前动画为生成姿态图切换、位移及轻微旋转，非完整连续逐帧动画。食物使用系统 Emoji 表示，部分图标是近似（例如鸡胸肉）。内存和耗电尚未实测。不含开机启动、云同步、重复任务、正式签名公证。

## Windows 与 GitHub

Windows 使用 `windows/` 中的 Electron 实现，复用同一套毛绒素材。需要 Node.js 22+。

```sh
cd windows
npm ci
npm test
npm run package:win
```

生成 `dist/windows/TigerPet-win32-x64/`。请发送整个压缩包，朋友解压后双击 `TigerPet.exe`，不能只发送 EXE。首次跨平台打包需要联网下载 Electron。Windows 界面尚未在真实 Windows 电脑验收；动画是关键姿态切换。Windows 暂不检测其他应用全屏，使用手动安静模式。

GitHub 提交到 main 后会触发 `.github/workflows/build.yml`，在 Windows/macOS runner 上分别构建和自检。到仓库 Actions → Build desktop pets → 成功的运行 → Artifacts 下载 Windows 或 macOS 包。也可在 Actions 手动 Run workflow。GitHub 不会将桌面应用变成网页，Code 页面用于查看源码。

在本机 VS Code 中用“文件 → 打开文件夹”，选择本项目；主程序是 `Sources/TigerPet/main.swift`，Windows 主程序是 `windows/app/main.cjs`。后续修改提交并推送 main，会再次自动打包。
