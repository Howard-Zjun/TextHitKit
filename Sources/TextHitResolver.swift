import UIKit

public class TextHitResolver: NSObject {

    var ranges: [(word: String, range: NSRange)] = []

    public var rule: TextMatchRule = WordMatchRule() {
        didSet {
            updateRanges()
        }
    }
    
    private(set) lazy var textStorage: NSTextStorage = {
        let textStorage = NSTextStorage()
        return textStorage
    }()
    
    private(set) lazy var layoutManager: NSLayoutManager = {
        let layoutManager = NSLayoutManager()
        return layoutManager
    }()
    
    private(set) lazy var textContainer: NSTextContainer = {
        let textContainer = NSTextContainer(size: .init(width: 0, height: CGFLOAT_MAX))
        // 排版所需的配置在所有构建中生效，不能依赖调试 TextView 初始化。
        textContainer.lineFragmentPadding = 0
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        return textContainer
    }()
    
    func update(width: CGFloat) {
        textContainer.size = .init(width: width, height: CGFLOAT_MAX)
    }
    
    func set(text: String) {
        let attr = NSAttributedString(string: text)
        set(attr: attr)
    }
    
    func set(attr: NSAttributedString) {
        let attr = NSMutableAttributedString(attributedString: attr)
        #if DEBUG
        // 仅调试时设置对照颜色，检查是否与 Label 原文重合。
        attr.addAttribute(.foregroundColor, value: UIColor.red, range: .init(location: 0, length: attr.length))
        #endif
        textStorage.beginEditing()
        textStorage.setAttributedString(attr)
        textStorage.endEditing()
        updateRanges()
    }

    /// 文本或规则变化时重新匹配，不改动现有富文本及排版属性。
    private func updateRanges() {
        let text = textStorage.string
        var ranges: [(String, NSRange)] = []
        let regex = try! NSRegularExpression(pattern: rule.pattern)
        regex.enumerateMatches(in: text, range: .init(location: 0, length: textStorage.length)) { match, _, _ in
            guard let range = match?.range else { return }
            ranges.append(((text as NSString).substring(with: range), range))
        }
        self.ranges = ranges
    }
    
    func charIndex(location: CGPoint) -> Int {
        guard textStorage.length > 0 else { return NSNotFound }
        layoutManager.ensureLayout(for: textContainer)
        let glyphIndex = layoutManager.glyphIndex(for: location, in: textContainer, fractionOfDistanceThroughGlyph: nil)
        // 获取排进这个文本容器的字形范围，点击的字形必须在范围内。
        let containerGlyphRange = layoutManager.glyphRange(for: textContainer)
        guard NSLocationInRange(glyphIndex, containerGlyphRange) else { return NSNotFound }
        // 范围内也可能有被省略号隐藏的文字，这些文字不能算作命中。
        let truncatedRange = layoutManager.truncatedGlyphRange(inLineFragmentForGlyphAt: glyphIndex)
        if truncatedRange.location != NSNotFound, NSLocationInRange(glyphIndex, truncatedRange) {
            return NSNotFound
        }
        // 查询可能返回离点击位置最近的字形，还要确认确实点在它的区域内。
        let boundingRect = layoutManager.boundingRect(forGlyphRange: .init(location: glyphIndex, length: 1), in: textContainer)
        if CGRectContainsPoint(boundingRect, location) {
            return layoutManager.characterIndexForGlyph(at: glyphIndex)
        } else {
            return NSNotFound
        }
    }
    
    func getWord(locationPoint: CGPoint) -> (String, NSRange)? {
        let charIndex = charIndex(location: locationPoint)
        if charIndex != NSNotFound {
            for rangeItem in ranges {
                if charIndex >= rangeItem.range.location && charIndex < rangeItem.range.location + rangeItem.range.length {
                    return rangeItem
                }
            }
        }
        return nil
    }
}
