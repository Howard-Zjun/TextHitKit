# TextHitKit

基于 UIKit 和 TextKit 的文本点击匹配组件。

## 核心特性

- 点击文本返回匹配内容。
- 内置英文单词、字母数字单词和邮箱规则，允许模块外自定义规则。
- Debug 使用红色 TextView 叠加对照。

## 重要组成

- **`TextHitLabel`**：文本显示与交互入口，同步字体、对齐、换行及行数等排版属性，处理点击并回调匹配内容；Debug 下通过红色 TextView 对照文字位置。
- **`TextHitResolver`**：文本解析与命中计算，管理 TextKit 排版对象，根据规则生成匹配范围，将点击坐标转换为字符位置，并排除被截断的内容；规则变化时自动重新匹配。
- **`TextMatchRule`**：匹配规则协议，通过正则表达式描述匹配内容，允许模块外自定义规则；内置 `WordMatchRule`、`AlphanumericWordMatchRule` 和 `EmailMatchRule`。

## 测试入口

[TextHitKitDemo](https://github.com/Howard-Zjun/TextHitKitDemo)
