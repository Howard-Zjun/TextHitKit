import UIKit

public class TextHitLabel: UILabel {
    
    public var needRecognize: Bool = false {
        didSet {
            isUserInteractionEnabled = needRecognize
        }
    }
    
    public var detectionBlock: ((String, NSRange) -> Void)?
    
    public let manager: TextHitResolver = .init()

    // 正式命中计算与调试视图共用的文字顶部偏移。
    private var textTopInset: CGFloat = 0
    
    #if DEBUG
    /// 测试view，用来展示设定后的文本是否和Label匹配
    private lazy var textView: UITextView = {
        let textView = UITextView(frame: .init(x: 0, y: 0, width: bounds.width, height: 0), textContainer: manager.textContainer)
        textView.backgroundColor = .clear
        textView.textColor = .clear
        // 容器尺寸统一由解析器管理，避免调试视图改变正式排版配置。
        textView.textContainer.widthTracksTextView = false
        textView.textContainer.heightTracksTextView = false
        // 文本容器相对 TextView 内容区域的四边内边距；先清零，布局时再计算顶部居中留白。
        textView.textContainerInset = .zero
        // 取消继承自 UIScrollView 的内容区域四边内边距。
        textView.contentInset = .zero
        // 禁止系统根据安全区域等因素自动调整滚动内容的内边距。
        textView.contentInsetAdjustmentBehavior = .never
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        return textView
    }()
    #endif
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        #if DEBUG
        addSubview(textView)
        #endif
        manager.update(width: bounds.width)
        updateTextAttributes()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        #if DEBUG
        addSubview(textView)
        #endif
        manager.update(width: bounds.width)
        updateTextAttributes()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        #if DEBUG
        textView.frame = bounds
        #endif
        manager.update(width: bounds.width)
        updateTextVerticalAlignment()
    }

    /// 计算文字垂直居中的偏移，命中计算不依赖调试用 TextView。
    private func updateTextVerticalAlignment() {
        manager.layoutManager.ensureLayout(for: manager.textContainer)
        let textHeight = manager.layoutManager.usedRect(for: manager.textContainer).height
        textTopInset = max(0, (bounds.height - textHeight) / 2)
        #if DEBUG
        let inset = UIEdgeInsets(top: textTopInset, left: 0, bottom: 0, right: 0)
        if textView.textContainerInset != inset {
            textView.textContainerInset = inset
        }
        if textView.contentOffset != .zero {
            textView.contentOffset = .zero
        }
        #endif
    }
    
    public override var text: String? {
        didSet {
            guard let text else {
                updateTextAttributes()
                return
            }
            
            let mText = text.replacingOccurrences(of: "\r", with: "")
            
            super.text = mText
            updateTextAttributes()
        }
    }
    
    public override var attributedText: NSAttributedString? {
        didSet {
            guard let attributedText else {
                updateTextAttributes()
                return
            }
            
            let mAttr = NSMutableAttributedString(attributedString: attributedText)
            
            let regex = try! NSRegularExpression(pattern: "\r")
            var location = 0
            for resultItem in regex.matches(in: mAttr.string, range: .init(location: 0, length: mAttr.length)) {
                let range = resultItem.range
                mAttr.replaceCharacters(in: .init(location: location + range.location, length: range.length), with: "")
                location -= range.length
            }
            
            super.attributedText = mAttr
            updateTextAttributes()
        }
    }
    
    public override var font: UIFont! {
        didSet {
            updateTextAttributes()
        }
    }

    public override var textAlignment: NSTextAlignment {
        didSet {
            updateTextAttributes()
        }
    }

    public override var lineBreakMode: NSLineBreakMode {
        didSet {
            updateTextAttributes()
        }
    }
    
    public override var numberOfLines: Int {
        didSet {
            updateTextAttributes()
        }
    }
    
    private func updateTextAttributes() {
        let attr: NSMutableAttributedString
        if let attributedText {
            attr = NSMutableAttributedString(attributedString: attributedText)
        } else {
            attr = NSMutableAttributedString(string: text ?? "")
        }

        let fullRange = NSRange(location: 0, length: attr.length)
        let defaultFont = font ?? UIFont.systemFont(ofSize: UIFont.labelFontSize)
        attr.enumerateAttributes(in: fullRange) { attributes, range, _ in
            
            if attributes[.font] == nil {
                attr.addAttribute(.font, value: defaultFont, range: range)
            }

            let paragraph = (attributes[.paragraphStyle] as? NSParagraphStyle)?
                .mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraph.alignment = textAlignment
            // 段落负责逐行换行，不能在第一行就截断；最后一行的截断交给文本容器。
            paragraph.lineBreakMode = lineBreakMode == .byCharWrapping ? .byCharWrapping : .byWordWrapping
            attr.addAttribute(.paragraphStyle, value: paragraph, range: range)
        }

        // 内容交给 NSTextStorage，容器只负责排版区域及换行配置。
        manager.set(attr: attr)
        manager.textContainer.maximumNumberOfLines = numberOfLines
        // 与段落换行区分：这里指定达到容器行数限制时，最后一行如何处理。
        manager.textContainer.lineBreakMode = lineBreakMode
        setNeedsLayout()
    }

}
extension TextHitLabel {
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 确保属性或尺寸变更后的居中偏移已更新。
        layoutIfNeeded()
        guard let location = touches.first?.location(in: self) else {
            super.touchesEnded(touches, with: event)
            return
        }
        
        if !bounds.contains(location) {
           return
        }
        let containerPoint = CGPoint(
            x: location.x - bounds.minX,
            y: location.y - bounds.minY - textTopInset
        )
        guard containerPoint.x >= 0, containerPoint.y >= 0,
              manager.textStorage.length > 0 else { return }
        if let item = manager.getWord(locationPoint: containerPoint) {
            detectionBlock?(item.0, item.1)
        }
        super.touchesEnded(touches, with: event)
    }
}
