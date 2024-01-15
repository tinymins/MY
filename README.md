# 茗伊插件集

> 这是在国产大型3D网游《剑网3》中使用的辅助插件，遵循简单实用原则，侧重于 PVE 并且全部开源免费。
[![Build Status](https://travis-ci.com/tinymins/JX3MY.svg?token=yQdYwdSeW1cRn46LTYo4&branch=master)](https://travis-ci.com/tinymins/JX3MY)

## 捐助

<https://jx3.derzh.com/donate/>

<a href="https://jx3.derzh.com/donate/">![Donate](https://cdn.jsdelivr.net/gh/tinymins/donate@master/combine.jpg)</a>

## 链接

* [科举助手 - 做最全最准确的剑三科举查询利器](https://jx3.derzh.com/exam/)
* [奇遇查询 - 关注您身边正在发生的一切奇遇事件](https://jx3.derzh.com/serendipity/)
* [开服记录 - 查询各服务器维护完成开服时间](https://jx3.derzh.com/onlinetime/)
* [角色字库 - 完整可用的角色名字库](https://jx3.derzh.com/char.txt)

## 下载

* 最新版本：[下载地址](https://jx3.derzh.com/down/)
* 安装方法：在角色登陆页，依次点击`插件管理`,`插件下载`，然后点击`下载`按钮下载各组件。
* 官方网站：<https://jx3.derzh.com/>
* 更新日志：<https://github.com/tinymins/jx3my/commits/master>
* 建议&BUG报告：[问题反馈](https://zhaiyiming.com/feedback) [【一名宅。】](https://zhaiyiming.com/archives/jx3-my.html) [【微博留言】](https://weibo.com/zymah)

## 主要功能

* 聊天辅助：快速切换频道和扩展显示组队聊天泡泡。
* 喊话辅助：同时在多个频道喊话，调侃队友。
* 聊天监控：监控指定规则指定频道的聊天结果。
* 职业染色：聊天栏玩家职业染色和基本信息显示。
* 点数监控：多种方式统计玩家ROLL点数据。
* 截图助手：提供多种格式和压缩率的截图工具。
* 扁平血条：简洁明了的头顶血条，支持读条显示。
* 常用工具：系统信息条，技能可视化，共战检查，仓库背包搜索等功能。
* 快速登出：快速返回登陆页，脱战后秒退等功能。

## wiki & 文档

* [如何删除不必要的功能模块](https://github.com/tinymins/JX3MY/wiki/%E5%88%A0%E9%99%A4%E6%8C%87%E5%AE%9A%E7%9A%84%E5%8A%9F%E8%83%BD%E6%A8%A1%E5%9D%97)
* [更多](https://github.com/tinymins/JX3MY/wiki/_pages)

## 安装&使用

* 解压下载的 `zip` 到 _JX3游戏目录_ 下的 `bin/zhcn/interface` 目录
* 小退可在插件管理界面看到默认打勾的“茗伊插件集”，保持打勾进入游戏
* 进入游戏后在玩家头像菜单或工具箱菜单可以看到茗伊插件集的选项，点击可以做插件设置
* ESC 进入快捷键设置，有一个分组“茗伊插件集”，可详细设置相关快捷键

## 其它

* 本插件开源免费，本人出于兴趣和朋友需求制作，作者微博 [@茗伊](http://weibo.com/zymah)、[问题反馈](https://zhaiyiming.com/feedback)。
* 本插件遵循简单实用原则，完全遵守白名单API，收集部分玩家角色公开信息如玩家ID，角色体型，帮会名称，装备分数等公开非敏感信息做玩家偏好数据统计。
* 安装使用视为 _同意以上内容_ 。

## 维护

### 新门派

* 团队面板心法简化文字 `MY_!Base\lang\lib\zhcn.jx3dat` `KUNGFU_TYPE_LABEL_ABBR`
* 全局门派配色 `MY_!Base\src\lib\Constant.lua` `FORCE_COLOR_BG_DEFAULT` `FORCE_COLOR_FG_DEFAULT`
* 全局门派心法枚举 `MY_!Base\src\lib\Constant.lua` `FORCE_TYPE` `KUNGFU_TYPE` `KUNGFU_TYPE`
