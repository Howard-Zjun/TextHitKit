import UIKit

public protocol TextMatchRule {
    
    var pattern: String { get }
}

// 单词识别规则
public class WordMatchRule: TextMatchRule {

    public init() {}
    
    public var pattern: String {
        // 只匹配英文字母，允许单词内部带撇号或连字符，例如 don't、well-known。
        // 含数字的内容整体跳过，不截取 i18n、3D、GPT-4 中的部分字母。
        #"(?<!\w)(?<!\w['’-])[A-Za-z]+(?:['’-][A-Za-z]+)*(?!\w|['’-]\w)"#
    }
}

// 支持字母和数字的单词识别规则
public class AlphanumericWordMatchRule: TextMatchRule {

    public init() {}

    public var pattern: String {
        // 在基础规则上允许数字，例如 i18n、3D、GPT-4；纯数字也能匹配。
        #"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)*"#
    }
}

// 邮箱识别规则
public class EmailMatchRule: TextMatchRule {

    public init() {}
    
    public var pattern: String {
        "[\\w0-9]+@[\\w0-9]+\\.[\\w0-9]+"
    }
}
