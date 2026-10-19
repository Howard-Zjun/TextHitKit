# TextHitKit

基于 UIKit 和 TextKit 的文本点击匹配组件。

## 核心特性

- 点击文本返回匹配内容。
- 内置英文单词、字母数字单词和邮箱规则，允许模块外自定义规则。
- Debug 使用红色 TextView 叠加对照。

## 重要组成

| 组成 | 职责 |
| --- | --- |
| `TextHitLabel` | 显示文本、同步排版属性、处理点击回调。 |
| `TextHitResolver` | 管理 TextKit 排版、匹配范围及坐标查询。 |
| `TextMatchRule` | 定义正则规则，支持外部遵循协议。 |

## 测试入口

[TextHitKitDemo](https://github.com/Howard-Zjun/TextHitKitDemo)
