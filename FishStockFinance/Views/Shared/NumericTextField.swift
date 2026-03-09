import SwiftUI
import UIKit

struct NumericTextField: UIViewRepresentable {
    @Binding var text: String
    var keyboardType: UIKeyboardType = .numberPad

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        @objc func doneTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil,
                                            from: nil,
                                            for: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.keyboardType = keyboardType
        textField.delegate = context.coordinator
        textField.textAlignment = .left
        textField.textColor = .black
        textField.font = .systemFont(ofSize: 17, weight: .semibold)

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done",
                                   style: .done,
                                   target: context.coordinator,
                                   action: #selector(Coordinator.doneTapped))
        toolbar.items = [flexibleSpace, done]
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}

