# 自动编译&发布

编译常用的路由器固件自动回传到下载站，方便用户直接下载想要的成品。

你也可以直接在[Github Actions](https://github.com/1orz/My-action/actions)里直接下载。(需要登录Github账号才能下载)

列表的所有编译成品均自动上传到下载站。

**issue不提供任何技术问题咨询服务，比如xxx怎么用？怎么配置;为什么xxx不好用？等等。不要在这里问。问了我也不会回复，一律关闭。因为这本来就是公益性项目。无任何技术支持**

国内下载站 https://down.cloudorz.com/

**觉得好用请给个Star吧！(点一下右上角的Star)**

# 特别提醒

**如果你是小白/萌新，则不建议fork本项目，直接fork不进行任何修改必将会编译失败。这里并非歧视小白，而是随意fork多份仓库，不恰当的使用actions都会给github服务器造成负担，浪费github无偿提供给我们开发者的宝贵资源~ 小白/萌新建议直接到下载站下载你要的固件即可。大佬可忽视**

# 项目自动编译状态
**提示：passing绿色标志为状态正常**
**如果全为falling也并不代表所有项目全部编译失败，请到Actions进一步查看**

| 项目名称 | 平台架构 | 编译状态 | 项目地址 | 下载链接
| :------: | :------: | :------: | :------: | :------: |
| LEDE | x86_64 | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Lean-lede?label=) |[Github](https://github.com/coolsnowwolf/lede) | [前往下载站](https://down.cloudorz.com/Router/LEDE/x86_64/)|
| LEDE | Xiaomi/Redmi AC2100 | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Lean-lede?label=) |[Github](https://github.com/coolsnowwolf/lede) | [前往下载站](https://down.cloudorz.com/Router/LEDE/XiaoMi/XiaoMi-AC2100/)|
| LEDE | 树莓派2B/3B/3B+/4B(32bit) | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Lean-lede?label=) |[Github](https://github.com/coolsnowwolf/lede) | [前往下载站](https://down.cloudorz.com/Router/LEDE/RaspberryPi/)|
| Gitea① | * | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Golang-Project?label=) |[Github](https://github.com/go-gitea/gitea) | [前往下载站](https://down.cloudorz.com/Software/ALL_Plantform/Gitea/)|
| Gogs① | * | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Golang-Project?label=) |[Github](https://github.com/gogs/gogs) | [前往下载站](https://down.cloudorz.com/Software/ALL_Plantform/Gogs/)|
| Nps① | * | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Golang-Project?label=) |[Github](https://github.com/ehang-io/nps) | [前往下载站](https://down.cloudorz.com/Software/ALL_Plantform/Nps/)|
| Frp① | * | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Golang-Project?label=) |[Github](https://github.com/fatedier/frp) | [前往下载站](https://down.cloudorz.com/Software/ALL_Plantform/Frp/)|
| v2ray-core① | * | ![](https://img.shields.io/github/workflow/status/1orz/My-action/Build-Golang-Project?label=) |[Github](https://github.com/fatedier/frp) | [前往下载站](https://down.cloudorz.com/Software/ALL_Plantform/V2Ray/)|


# 捐助

**从2019.12月开始到现在，本站一直在无偿给广大喜欢openwrt的玩家免费提供国内高速服务器固件编译/下载服务，为了给各位热爱软路由的折腾党们良好的下载体验，现在下载站已经迁移到国内，并采用100M大宽带服务器，以便提升用户的下载速度。**

**但由于高宽带服务器租用费用高昂...花掉了我大部分生活费。同时也占用了我大量的业余时间。**

**So.若您觉得好用并愿意支持本项目长期发展下去。获得最佳的下载体验，可以考虑捐助本站··请作者喝杯咖啡~~~**

**你们的支持就是我的动力!**

### 捐助方式

#### 支付宝

![支付宝捐助](img/alipay.png)

#### 微信

![微信捐助](img/wepay.png)
