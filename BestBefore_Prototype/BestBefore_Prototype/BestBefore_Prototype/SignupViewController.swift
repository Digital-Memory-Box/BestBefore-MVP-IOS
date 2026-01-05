import UIKit

final class SignupViewController: UIViewController, UITextFieldDelegate {

    var onSignupSuccess: ((String) -> Void)? // returns email to prefill

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Create Account"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name (optional)"
        tf.autocapitalizationType = .words
        tf.textColor = .white
        tf.backgroundColor = .black
        tf.layer.borderColor = UIColor.white.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 10
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.setContentHuggingPriority(.defaultLow, for: .vertical)
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        tf.leftViewMode = .always
        return tf
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.textColor = .white
        tf.backgroundColor = .black
        tf.layer.borderColor = UIColor.white.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 10
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        tf.leftViewMode = .always
        return tf
    }()

    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password (min 6 chars)"
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        tf.textColor = .white
        tf.backgroundColor = .black
        tf.layer.borderColor = UIColor.white.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 10
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        tf.leftViewMode = .always
        return tf
    }()

    private let signupButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create Account", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.cornerRadius = 12
        b.backgroundColor = UIColor.systemBlue
        return b
    }()

    private let loginLink: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Already have an account? Log in", for: .normal)
        b.setTitleColor(.lightGray, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        layout()
        signupButton.addTarget(self, action: #selector(didTapSignup), for: .touchUpInside)
        loginLink.addTarget(self, action: #selector(didTapLoginLink), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
    }

    private func layout() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, nameField, emailField, passwordField, signupButton, loginLink])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nameField.heightAnchor.constraint(equalToConstant: 44),
            emailField.heightAnchor.constraint(equalToConstant: 44),
            passwordField.heightAnchor.constraint(equalToConstant: 44),
            signupButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func didTapSignup() {
        Task { await signup() }
    }

    @objc private func didTapLoginLink() {
        // Simply go back to login
        if let nav = navigationController { nav.popViewController(animated: true) }
        else { dismiss(animated: true) }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField { passwordField.becomeFirstResponder() }
        else if textField == passwordField { Task { await signup() } }
        return true
    }

    private func signup() async {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""

        guard isValidEmail(email) else { showAlert("Please enter a valid email."); return }
        guard password.count >= 6 else { showAlert("Password must be at least 6 characters."); return }

        signupButton.isEnabled = false
        defer { signupButton.isEnabled = true }

        do {
            let (user, token) = try await AuthService.shared.signup(name: (name?.isEmpty == true ? nil : name), email: email, password: password)
            print("Signed up user=\(user.email), token length=\(token.count)")
            await MainActor.run {
                self.onSignupSuccess?(email)
                if let nav = self.navigationController { nav.popViewController(animated: true) }
                else { self.dismiss(animated: true) }
            }
        } catch {
            await MainActor.run {
                self.showAlert(error.localizedDescription)
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Sign Up", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
