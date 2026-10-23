import SwiftUI

#if os(iOS)
import UIKit

/// Own the delegate so Return works independently of SwiftUI's view hierarchy
/// and OS-specific introspection allowlists.
struct ExpressionTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = "Enter an expression"
        field.accessibilityIdentifier = "expressionField"
        field.keyboardType = .numbersAndPunctuation
        field.returnKeyType = .go
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.adjustsFontForContentSizeCategory = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        field.font = .preferredFont(forTextStyle: .title2)
        guard field.text != text, field.markedTextRange == nil else { return }

        context.coordinator.isUpdating = true
        defer { context.coordinator.isUpdating = false }
        field.text = text
        // UIKit measures selection in UTF-16; expression helpers use Characters.
        let offset = text.prefix(max(0, cursorPosition)).utf16.count
        if let position = field.position(from: field.beginningOfDocument, offset: offset) {
            field.selectedTextRange = field.textRange(from: position, to: position)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width,
               height: uiView.intrinsicContentSize.height)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ExpressionTextField
        var isUpdating = false

        init(_ parent: ExpressionTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ field: UITextField) {
            guard !isUpdating, field.markedTextRange == nil else { return }
            let value = field.text ?? ""
            if let selection = field.selectedTextRange,
               let prefixRange = field.textRange(from: field.beginningOfDocument, to: selection.start) {
                parent.cursorPosition = (field.text(in: prefixRange) ?? "").count
            } else {
                parent.cursorPosition = value.count
            }
            parent.text = value
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            editingChanged(textField)
            parent.onSubmit()
            // Keep focus for the next calculation, including hardware keyboards.
            return false
        }
    }
}
#endif
