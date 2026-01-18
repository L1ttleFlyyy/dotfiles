# Claude on HP Elitebook X G1a 14

这是安装在 HP Elitebook X G1a 14 笔记本上的 Claude Code 环境说明文档。

# 协作规范 
- 内部用英文思考，对话主要用中文，但是专业术语不要强行翻译（例如CPU，cache，kernel不用翻译成中央处理器，缓存， 内核）
- 保持客观，只针对技术，不针对个人。不要因为“友善的态度”而模糊自己的判断

# 方法论 
- 先设计好框架，再分模块/步骤谈具体实现，不要一上来就开始big bang式写代码
- 对于不了解的领域，必须先查资料，以官方文档为依据 ，同时也可以从社区经验(例如但不局限于github issues，reddit论坛等)中获取灵感
- 执行方案时，不要想当然，必须分模块/步骤确认验证
- 先用最简单的方案解决 (minimum viable product)，如果之后出现意外情况再针对性解决
- 写代码时不做过度的防御性编程，Premature Optimization is the Root of All Evil

# 注意事项：
- 少说车轱辘话，保持逻辑清晰
- 保持context的精炼，抓住重点，不要反复输出已经提到过的完整方案内容
- 不要盲目读取大文件，可以用wc/dh等工具检查文件大小，善用grep/Search等工具提取有用信息

## 硬件信息

- **型号**: HP Elitebook X G1a 14
- **CPU**: AMD Ryzen AI 9 HX PRO 375 (24-core) with Radeon 890M
- **GPU**: AMD Radeon 890M (8GB VRAM)

## 操作系统信息

- **系统**: Bazzite-deck (基于 Fedora 43)
- **内核**: 6.17.7-ba20.fc43.x86_64
- **显示协议**: Wayland
- **桌面环境**: KDE Plasma

### Bazzite 核心理念

Bazzite 是一个**不可变操作系统 (Immutable OS)**，所有系统相关的文件都是只读的。这带来了更高的稳定性和安全性，但也改变了软件安装方式。
在 Bazzite 上安装软件时，应按以下顺序选择方案：
1. **ujust** - Bazzite 自带的便捷命令（类似于官方打包好的脚本，应当考虑优先使用）
2. **flatpak** - 容器化应用，隔离性好
3. **homebrew** - 用户空间包管理器
4. **distrobox** - 容器化的传统 Linux 环境
5. **ostree layer** - 系统层安装（最后手段，需要重启，有可能搞崩依赖）

不过如果系统崩了也不慌 rpm-ostree可以保证总能rollback到上一个版本。

## 配置和脚本

系统配置和折腾笔记记录在：
```
~/MyDoc/my_scripts/linux/mobile/bazzite-setup.sh
```
包含以下主要设置：

- ✅ Secure Boot 密钥注册
- ✅ TPM 自动解锁 LUKS 磁盘
- ✅ Homebrew 工具链（zsh, nvim, chezmoi, fd, ripgrep, gh）
- ✅ Flatpak 应用安装（Brave, Konsole, Moonlight, QQ, Syncthing, Trayscale, LocalSend）
- ✅ keyd 键盘映射（macOS 风格键位）
- ✅ 系统微调（input group, password feedback, GRUB 隐藏）

---

*最后更新: 2026-01-18*
