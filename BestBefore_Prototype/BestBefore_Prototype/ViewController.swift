////
////  ViewController.swift
////  BestBefore_Prototype
////
////  Created by Arya Zaeri on 3.11.2025.
////


import UIKit

// Custom UITextField subclass to add internal padding
class PaddedTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

class ViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Login State
    enum LoginState {
        case initial
        case emailInput
        case passwordInput
    }
    private var currentLoginState: LoginState = .initial
    private var lastLoggedInEmail: String?

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BestBefore"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0 // Initial state for animation
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = "touch to explore your memory\nswipe for Artists"
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0 // Initial state for animation
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let emailTextField: PaddedTextField = {
        let textField = PaddedTextField()
        textField.placeholder = "email or nickname"
        textField.textColor = .white
        textField.backgroundColor = .black
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.textContentType = .emailAddress
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.attributedPlaceholder = NSAttributedString(string: "email or nickname", attributes: [.foregroundColor: UIColor.lightGray])
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.alpha = 0 // Hidden initially
        textField.accessibilityLabel = "Email or nickname"
        return textField
    }()

    private let passwordTextField: PaddedTextField = {
        let textField = PaddedTextField()
        textField.placeholder = "password"
        textField.textColor = .white
        textField.backgroundColor = .black
        textField.isSecureTextEntry = true
        textField.textContentType = .password
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.attributedPlaceholder = NSAttributedString(string: "password", attributes: [.foregroundColor: UIColor.lightGray])
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.alpha = 0 // Hidden initially
        textField.accessibilityLabel = "Password"
        return textField
    }()

    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("forgot my password", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0 // Hidden initially
        button.accessibilityLabel = "Forgot my password"
        return button
    }()

    private let createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("create an account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0 // Hidden initially
        button.accessibilityLabel = "Create an account"
        return button
    }()

    private let loginContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = true
        view.alpha = 0
        view.accessibilityLabel = "Login button"
        view.accessibilityTraits = .button
        return view
    }()
    
    private let loginLabel: UILabel = {
        let label = UILabel()
        label.text = "Login"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0 // Hidden initially
        return label
    }()
    
    private let loginContainerMaskLayer = CAShapeLayer()
    private var gradientLayer: CAGradientLayer!
    // Background Layers
    private var backgroundGradientLayer: CAGradientLayer!
    private var vignetteLayer: CAGradientLayer!
    // Bubble Background
    private var bigBubbleLayer: CAGradientLayer!
    private var smallBubbleLayers: [CAGradientLayer] = []
    private var bigBubbleOffsetX: CGFloat = 0
    // MARK: - Animation Config
    private let maskAnimationKey = "pathAnimation"
    private let defaultAnimDuration: CFTimeInterval = 1.0

    // MARK: - Constraints
    private var emailTextFieldTopConstraint: NSLayoutConstraint!
    private var passwordTextFieldTopConstraint: NSLayoutConstraint!

    // Initial State Constraints
    private var titleLabelInitialCenterXConstraint: NSLayoutConstraint!
    private var titleLabelInitialCenterYConstraint: NSLayoutConstraint!
    private var loginContainerCenterXConstraint: NSLayoutConstraint!

    // Login State Constraints
    private var titleLabelFinalTopConstraint: NSLayoutConstraint!
    private var titleLabelFinalCenterXConstraint: NSLayoutConstraint!
    private var loginContainerTrailingConstraint: NSLayoutConstraint!


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure gradient layer is updated when view's bounds change
        if let gradientLayer = gradientLayer {
            gradientLayer.frame = loginContainerView.bounds
        }
        loginContainerMaskLayer.frame = loginContainerView.bounds
        // Layout background layers
        backgroundGradientLayer?.frame = view.bounds
        vignetteLayer?.frame = view.bounds
        // Layout big bubble (centered) and small bubbles
        if let bigBubbleLayer = bigBubbleLayer {
            bigBubbleLayer.frame = view.bounds
            // Recompute circular mask frame based on current bounds
            let diameter = min(view.bounds.width, view.bounds.height) * 0.7
            let centerX = view.bounds.midX + bigBubbleOffsetX
            let x = centerX - diameter / 2
            let y = (view.bounds.height - diameter) / 2
            if let mask = bigBubbleLayer.mask as? CAShapeLayer {
                mask.frame = view.bounds
                mask.path = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: diameter, height: diameter)).cgPath
            }
        }
        for layer in smallBubbleLayers {
            // Keep their mask path circular and aligned to the layer’s frame
            if let mask = layer.mask as? CAShapeLayer {
                mask.frame = layer.bounds
                mask.path = UIBezierPath(ovalIn: layer.bounds).cgPath
            }
        }
        // If an animation is in progress, don't interfere with the path.
        // The animation will set the final path value. This ensures the mask is correct
        // on initial layout and on events like device rotation.
        if loginContainerMaskLayer.animation(forKey: "pathAnimation") == nil {
            updateLoginContainerMask()
        }
    }
    
    /// Builds a left half-circle path for the login mask.
    /// - Parameters:
    ///   - bounds: The bounds to inscribe the circle.
    ///   - overshoot: Positive values (pts) shift the closing chord slightly to the right
    ///                to create a brief "over-cut" effect for a bouncy feel. Use 0 for exact half.
    private func makeHalfCirclePath(bounds: CGRect, overshoot: CGFloat = 0) -> CGPath {
        let radius = bounds.width / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath()
        path.addArc(withCenter: center,
                    radius: radius,
                    startAngle: .pi / 2,
                    endAngle: -.pi / 2,
                    clockwise: true)
        // Close with a vertical chord slightly shifted by `overshoot` (for bounce keyframe)
        path.addLine(to: CGPoint(x: center.x + overshoot, y: center.y + radius))
        path.close()
        return path.cgPath
    }

    private func updateLoginContainerMask() {
        let bounds = loginContainerView.bounds
        let path: UIBezierPath

        if currentLoginState == .initial {
            path = UIBezierPath(ovalIn: bounds)
        } else {
            path = UIBezierPath(cgPath: makeHalfCirclePath(bounds: bounds, overshoot: 0))
        }
        loginContainerMaskLayer.path = path.cgPath
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        performIntroAnimations()
        // Battery-friendly: pause background animation in Low Power Mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            bigBubbleLayer?.removeAllAnimations()
            smallBubbleLayers.forEach { $0.removeAllAnimations() }
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .black

        // ==== Background as ONE big color‑shifting bubble + extra small bubbles ====
        // Big bubble (radial gradient clipped to a circle)
        bigBubbleLayer = CAGradientLayer()
        bigBubbleLayer.type = .radial
        bigBubbleLayer.frame = view.bounds
        bigBubbleLayer.colors = [
            UIColor(red: 0.05, green: 0.35, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.00, green: 0.85, blue: 0.45, alpha: 1.0).cgColor
        ]
        bigBubbleLayer.locations = [0.0, 1.0]
        bigBubbleLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        bigBubbleLayer.endPoint = CGPoint(x: 1.0, y: 1.0) // radial expands to edges
        // Circular mask sized in viewDidLayoutSubviews
        let bigMask = CAShapeLayer()
        bigMask.fillColor = UIColor.black.cgColor
        bigBubbleLayer.mask = bigMask
        view.layer.insertSublayer(bigBubbleLayer, at: 0)

        // Extra small bubbles around the edges (3–5)
        createSmallBubbles(count: 4)

        // Soft vignette overlay for punch (radial gradient darkening edges)
        vignetteLayer = CAGradientLayer()
        vignetteLayer.type = .radial
        vignetteLayer.frame = view.bounds
        vignetteLayer.colors = [
            UIColor(white: 0, alpha: 0.0).cgColor,
            UIColor(white: 0, alpha: 0.22).cgColor,
            UIColor(white: 0, alpha: 0.48).cgColor
        ]
        vignetteLayer.locations = [0.65, 0.90, 1.0]
        vignetteLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        vignetteLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(vignetteLayer, above: bigBubbleLayer)

        if !UIAccessibility.isReduceMotionEnabled {
            animateBigBubble()
            animateSmallBubbles()
        }

        // Add subviews
        view.addSubview(loginContainerView)
        loginContainerView.addSubview(loginLabel)
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(forgotPasswordButton)
        view.addSubview(createAccountButton)

        // Setup gradient layer for login container
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor, // Blue
            UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0).cgColor  // Green
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        loginContainerView.layer.insertSublayer(gradientLayer, at: 0)
        // Keep button gradient visually above background but below vignette if needed
        // view.layer.insertSublayer(gradientLayer, above: backgroundGradientLayer)
        // view.layer.insertSublayer(loginContainerMaskLayer, above: gradientLayer)
        
        // Set the dedicated mask layer
        loginContainerView.layer.mask = loginContainerMaskLayer
        
        // Configure mask layer frame & drawing behavior
        loginContainerMaskLayer.frame = loginContainerView.bounds
        loginContainerMaskLayer.fillColor = UIColor.black.cgColor
        loginContainerMaskLayer.lineJoin = .round
        loginContainerMaskLayer.lineCap = .round
        // Avoid implicit path animations when we set a final value
        loginContainerMaskLayer.actions = ["path": NSNull()]

        // Add tap gesture to login container view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(loginButtonTapped))
        loginContainerView.addGestureRecognizer(tapGesture)
        
        // Add button actions
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)

        // Set delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self

        // Initialize constraints
        // -- Initial State Constraints --
        loginContainerCenterXConstraint = loginContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        titleLabelInitialCenterXConstraint = titleLabel.centerXAnchor.constraint(equalTo: loginContainerView.centerXAnchor)
        titleLabelInitialCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: loginContainerView.centerYAnchor)

        // -- Login State Constraints --
        loginContainerTrailingConstraint = loginContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 125) // Positioned half-offscreen
        titleLabelFinalTopConstraint = titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120)
        titleLabelFinalCenterXConstraint = titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        // -- Shared & Login Fields Constraints
        emailTextFieldTopConstraint = emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60)
        passwordTextFieldTopConstraint = passwordTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1000)


        // Activate initial layout
        NSLayoutConstraint.activate([
            // Login Container (Sphere)
            loginContainerView.widthAnchor.constraint(equalToConstant: 280),
            loginContainerView.heightAnchor.constraint(equalToConstant: 280),
            loginContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loginContainerCenterXConstraint, // Initially centered
            
            // Login Label (inside container)
            loginLabel.centerYAnchor.constraint(equalTo: loginContainerView.centerYAnchor),
            loginLabel.centerXAnchor.constraint(equalTo: loginContainerView.centerXAnchor, constant: -62.5), // Center of the visible half

            // Title Label (inside sphere initially)
            titleLabelInitialCenterXConstraint,
            titleLabelInitialCenterYConstraint,

            // Instruction Label
            instructionLabel.topAnchor.constraint(equalTo: loginContainerView.bottomAnchor, constant: 30),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Email Text Field (positioned for login state, but hidden)
            emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            emailTextFieldTopConstraint,

            // Password Text Field (positioned for login state, but hidden)
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordTextFieldTopConstraint,

            // Forgot Password Button
            forgotPasswordButton.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),

            // Create Account Button
            createAccountButton.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            createAccountButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 10),
        ])
    }

    // MARK: - Animated Background
    private func addAnimatedBackground() {
        // Keyframe color animation to drift through nearby hues
        let colors1: [CGColor] = [
            UIColor(red: 0.02, green: 0.10, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.00, green: 0.50, blue: 1.00, alpha: 1.0).cgColor,
            UIColor(red: 0.00, green: 0.80, blue: 0.40, alpha: 1.0).cgColor
        ]
        let colors2: [CGColor] = [
            UIColor(red: 0.02, green: 0.10, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.20, green: 0.35, blue: 0.90, alpha: 1.0).cgColor,
            UIColor(red: 0.00, green: 0.70, blue: 0.55, alpha: 1.0).cgColor
        ]
        let colors3: [CGColor] = [
            UIColor(red: 0.02, green: 0.10, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.10, green: 0.60, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.00, green: 0.85, blue: 0.45, alpha: 1.0).cgColor
        ]

        let colorAnim = CAKeyframeAnimation(keyPath: "colors")
        colorAnim.values = [colors1, colors2, colors3, colors1]
        colorAnim.keyTimes = [0.0, 0.33, 0.66, 1.0] as [NSNumber]
        colorAnim.duration = 12.0
        colorAnim.calculationMode = .linear
        colorAnim.isRemovedOnCompletion = false
        colorAnim.fillMode = .forwards
        colorAnim.repeatCount = .infinity

        // Subtle panning by moving start/end points
        let startPointAnim = CAKeyframeAnimation(keyPath: "startPoint")
        startPointAnim.values = [
            NSValue(cgPoint: CGPoint(x: 0.0, y: 0.0)),
            NSValue(cgPoint: CGPoint(x: 0.0, y: 1.0)),
            NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0)),
            NSValue(cgPoint: CGPoint(x: 0.0, y: 0.0))
        ]
        startPointAnim.keyTimes = [0.0, 0.33, 0.66, 1.0]
        startPointAnim.duration = 18.0
        startPointAnim.isRemovedOnCompletion = false
        startPointAnim.fillMode = .forwards
        startPointAnim.repeatCount = .infinity

        let endPointAnim = CAKeyframeAnimation(keyPath: "endPoint")
        endPointAnim.values = [
            NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0)),
            NSValue(cgPoint: CGPoint(x: 1.0, y: 0.0)),
            NSValue(cgPoint: CGPoint(x: 0.0, y: 0.0)),
            NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0))
        ]
        endPointAnim.keyTimes = [0.0, 0.33, 0.66, 1.0]
        endPointAnim.duration = 18.0
        endPointAnim.isRemovedOnCompletion = false
        endPointAnim.fillMode = .forwards
        endPointAnim.repeatCount = .infinity

        backgroundGradientLayer.add(colorAnim, forKey: "bb.background.colors")
        backgroundGradientLayer.add(startPointAnim, forKey: "bb.background.startPoint")
        backgroundGradientLayer.add(endPointAnim, forKey: "bb.background.endPoint")
    }

    // MARK: - Animations & Actions

    private func performIntroAnimations() {
        guard currentLoginState == .initial else { return }
        UIView.animate(withDuration: defaultAnimDuration, delay: 0.5, options: .curveEaseOut) {
            self.loginContainerView.alpha = 1
            self.titleLabel.alpha = 1
            self.instructionLabel.alpha = 1
        }
    }

    @objc private func loginButtonTapped() {
        switch currentLoginState {
        case .initial:
            transitionToEmailInput()
        case .emailInput:
            if let email = emailTextField.text, !email.isEmpty {
                transitionToPasswordInput()
            } else {
                print("Please enter your email or nickname.")
                shakeView(emailTextField)
            }
        case .passwordInput:
            attemptLogin()
        }
    }
    
    @objc private func forgotPasswordTapped() {
        print("Forgot password tapped")
        let alert = UIAlertController(
            title: "Forgot Password",
            message: "Password reset functionality would be implemented here.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func createAccountTapped() {
        let signup = SignupViewController()
        signup.onSignupSuccess = { [weak self] email in
            guard let self = self else { return }
            self.emailTextField.text = email
            self.currentLoginState = .emailInput
            self.instructionLabel.alpha = 0
            self.emailTextField.alpha = 1
            self.loginLabel.alpha = 1
            self.focusTextField(self.emailTextField)
        }
        if let nav = self.navigationController {
            nav.pushViewController(signup, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: signup)
            nav.modalPresentationStyle = .formSheet
            self.present(nav, animated: true)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            transitionToPasswordInput()
        } else if textField == passwordTextField {
            attemptLogin()
        }
        return true
    }

    private func transitionToEmailInput() {
        guard currentLoginState == .initial else { return }

        // Respect Reduce Motion
        if UIAccessibility.isReduceMotionEnabled {
            currentLoginState = .emailInput

            NSLayoutConstraint.deactivate([
                loginContainerCenterXConstraint,
                titleLabelInitialCenterXConstraint,
                titleLabelInitialCenterYConstraint
            ])
            NSLayoutConstraint.activate([
                loginContainerTrailingConstraint,
                titleLabelFinalTopConstraint,
                titleLabelFinalCenterXConstraint
            ])

            view.layoutIfNeeded()
            updateLoginContainerMask()
            setBigBubbleOpacity(0.15, duration: 0)   // immediate fade

            instructionLabel.alpha = 0
            emailTextField.alpha = 1
            loginLabel.alpha = 1
            focusTextField(emailTextField)
            return
        }

        // Build paths in the SAME coordinate space
        let bounds = loginContainerView.bounds
        let startPath = UIBezierPath(ovalIn: bounds).cgPath
        let endPath = makeHalfCirclePath(bounds: bounds, overshoot: 0)

        // Ensure we capture the CURRENT (initial) layout state
        self.view.layoutIfNeeded()

        // Update state & constraints (do NOT layout yet; we'll animate it)
        currentLoginState = .emailInput
        NSLayoutConstraint.deactivate([
            loginContainerCenterXConstraint,
            titleLabelInitialCenterXConstraint,
            titleLabelInitialCenterYConstraint
        ])
        NSLayoutConstraint.activate([
            loginContainerTrailingConstraint,
            titleLabelFinalTopConstraint,
            titleLabelFinalCenterXConstraint
        ])

        // Animate mask path (Core Animation) with a soft overshoot keyframe to match the reference style
        let maxOvershoot = min(12.0, bounds.width * 0.08) // cap overshoot for large sizes
        let overshootPath = makeHalfCirclePath(bounds: bounds, overshoot: CGFloat(maxOvershoot))

        let pathAnimation = CAKeyframeAnimation(keyPath: "path")
        pathAnimation.values = [
            startPath,
            overshootPath,
            endPath
        ]
        
        pathAnimation.keyTimes = [0.0, 0.7, 1.0] as [NSNumber]
        pathAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeOut)
        ]
        pathAnimation.duration = defaultAnimDuration
        pathAnimation.fillMode = .forwards
        pathAnimation.isRemovedOnCompletion = false
        pathAnimation.calculationMode = .cubic
        // Ensure CA animation is time-aligned with the UIView animation
        pathAnimation.beginTime = CACurrentMediaTime()

        loginContainerMaskLayer.add(pathAnimation, forKey: maskAnimationKey)
        
        // Temporarily pause background bubble animations and rasterize for smoother transition
        pauseSmallBubbles()
        loginContainerView.layer.shouldRasterize = true
        loginContainerView.layer.rasterizationScale = UIScreen.main.scale
        bigBubbleLayer?.shouldRasterize = true

        // Shift the background bubbles and big bubble in sync with the morph
        shiftSmallBubblesLeft(0.18)
        shiftBigBubbleRight(0.18)
        setBigBubbleOpacity(0.05)
        

        // Animate constraints & fades (UIView) in sync
        UIView.animate(withDuration: defaultAnimDuration,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.instructionLabel.alpha = 0
            self.emailTextField.alpha = 1
            self.loginLabel.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: { _ in
            // Commit final path and clean up
            self.loginContainerMaskLayer.path = endPath
            self.loginContainerMaskLayer.removeAnimation(forKey: self.maskAnimationKey)

            // Restore after transition
            self.loginContainerView.layer.shouldRasterize = false
            self.bigBubbleLayer?.shouldRasterize = false
            self.resumeSmallBubbles()

            // Move focus to the email field
            self.focusTextField(self.emailTextField)
        })
    }
    
    private func transitionToPasswordInput() {
        guard currentLoginState == .emailInput else { return }
        currentLoginState = .passwordInput
        emailTextField.resignFirstResponder()

        let animationDuration: TimeInterval = defaultAnimDuration  // Increased from 0.7 to 0.875 (25% slower)

        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            // Animate email text field out (slide up and fade)
            self.emailTextFieldTopConstraint.constant = -self.emailTextField.frame.height - 50
            self.emailTextField.alpha = 0

            // Animate password text field in (slide up and fade)
            self.passwordTextFieldTopConstraint.constant = 60 // Move to where email field was
            self.passwordTextField.alpha = 1

            // Animate other buttons in
            self.forgotPasswordButton.alpha = 1
            self.createAccountButton.alpha = 1

            self.view.layoutIfNeeded()
        }) { _ in
            self.focusTextField(self.passwordTextField)
            self.emailTextField.isUserInteractionEnabled = false
        }
    }

    private func attemptLogin() {
        view.endEditing(true)

        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        if email.isEmpty || password.isEmpty {
            print("Please enter both email/nickname and password.")
            if email.isEmpty { shakeView(emailTextField) }
            if password.isEmpty { shakeView(passwordTextField) }
            return
        }
        if !isValidEmail(email) && !isValidNickname(email) {
            print("Invalid email or nickname format.")
            shakeView(emailTextField)
            return
        }

        self.lastLoggedInEmail = email
        print("Login tapped: starting authentication flow…")
        Task { [weak self] in
            guard let self = self else { return }
            do {
                print("➡️ Login: authenticating user…")
                let (user, token) = try await AuthService.shared.login(email: email, password: password)
                print("⬅️ Login: authenticated \(user.email) tokenLength=\(token.count)")
                print("➡️ Login: fetching rooms…")
                let rooms = try await Database.shared.getAllRooms()
                print("⬅️ Login: rooms fetched count=\(rooms.count)")
                await MainActor.run {
                    if rooms.isEmpty {
                        self.promptForRoomName()
                    } else {
                        self.presentRoomsChoice(with: rooms)
                    }
                }
            } catch let authError as AuthError {
                print("Login failed:", authError)
                await self.showLoginAlert(message: authError.localizedDescription)
            } catch {
                print("Login fetch error:", error)
                await self.showLoginAlert(message: "Failed to load rooms. Please try again.")
            }
        }
    }

    private func showLoginAlert(message: String) async {
        await MainActor.run {
            let alert = UIAlertController(title: "Login Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Improved UIResponder Management
    
    /// Enhanced first responder management with accessibility support
    private func focusTextField(_ textField: UITextField) {
        let focused = textField.becomeFirstResponder()
        
        if focused {
            // Add accessibility support for VoiceOver users
            if UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    textField.accessibilityHint = "Keyboard is now active"
                    UIAccessibility.post(notification: .layoutChanged, argument: textField)
                }
            }
        } else {
            print("Failed to focus text field")
            // Optional: Add failure state handling
        }
    }
    
    // MARK: - Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidNickname(_ nickname: String) -> Bool {
        // Nickname should be 3-20 characters, alphanumeric with underscores
        let nicknameRegex = "^[A-Za-z0-9_]{3,20}$"
        let nicknamePredicate = NSPredicate(format: "SELF MATCHES %@", nicknameRegex)
        return nicknamePredicate.evaluate(with: nickname)
    }

    private func shakeView(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        view.layer.add(animation, forKey: "shake")
    }

    // MARK: - Bubble Background Helpers
    private func animateBigBubble() {
        // Gently cycle the two colors to nearby hues for a living feel
        let c1a = UIColor(red: 0.05, green: 0.35, blue: 0.95, alpha: 1.0).cgColor
        let c1b = UIColor(red: 0.00, green: 0.60, blue: 1.00, alpha: 1.0).cgColor
        let c2a = UIColor(red: 0.00, green: 0.85, blue: 0.45, alpha: 1.0).cgColor
        let c2b = UIColor(red: 0.05, green: 0.95, blue: 0.55, alpha: 1.0).cgColor

        let colorAnim = CAKeyframeAnimation(keyPath: "colors")
        colorAnim.values = [[c1a, c2a], [c1b, c2b], [c1a, c2a]]
        colorAnim.keyTimes = [0.0, 0.5, 1.0] as [NSNumber]
        colorAnim.duration = 10.0
        colorAnim.isRemovedOnCompletion = false
        colorAnim.fillMode = .forwards
        colorAnim.repeatCount = .infinity
        bigBubbleLayer.add(colorAnim, forKey: "bb.big.colors")
    }

    private func createSmallBubbles(count: Int) {
        // Remove old ones if any
        smallBubbleLayers.forEach { $0.removeFromSuperlayer() }
        smallBubbleLayers.removeAll()

        // Color pairs (radial gradients)
        let palette: [[CGColor]] = [
            [UIColor(red: 0.95, green: 0.35, blue: 0.95, alpha: 1.0).cgColor,
             UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1.0).cgColor],
            [UIColor(red: 0.30, green: 0.95, blue: 0.95, alpha: 1.0).cgColor,
             UIColor(red: 0.90, green: 0.30, blue: 0.95, alpha: 1.0).cgColor],
            [UIColor(red: 0.95, green: 0.20, blue: 0.55, alpha: 1.0).cgColor,
             UIColor(red: 0.40, green: 0.80, blue: 1.00, alpha: 1.0).cgColor],
            [UIColor(red: 0.95, green: 0.75, blue: 0.20, alpha: 1.0).cgColor,
             UIColor(red: 0.60, green: 0.20, blue: 0.95, alpha: 1.0).cgColor]
        ]

        // Allow slight offscreen margins so bubbles peek at the edges
        let margin: CGFloat = 60
        // Use safeArea if you prefer: view.safeAreaLayoutGuide.layoutFrame
        let available = view.bounds.insetBy(dx: -margin, dy: -margin)

        for _ in 0..<count {
            let bubble = CAGradientLayer()
            bubble.type = .radial

            // Random size
            let size = CGFloat.random(in: 70...130)

            // Random position kept within available rect
            let x = CGFloat.random(in: available.minX...(available.maxX - size))
            let y = CGFloat.random(in: available.minY...(available.maxY - size))
            bubble.frame = CGRect(x: x, y: y, width: size, height: size)

            // Random palette
            let colors = palette[Int.random(in: 0..<palette.count)]
            bubble.colors = colors
            bubble.locations = [0.0, 1.0]
            bubble.startPoint = CGPoint(x: 0.5, y: 0.5)
            bubble.endPoint = CGPoint(x: 1.0, y: 1.0)

            // Circular mask
            let mask = CAShapeLayer()
            mask.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: size, height: size))).cgPath
            bubble.mask = mask

            view.layer.insertSublayer(bubble, below: vignetteLayer)
            smallBubbleLayers.append(bubble)
        }
    }
    private func animateSmallBubbles() {
        for (idx, bubble) in smallBubbleLayers.enumerated() {
            // Horizontal drift
            let driftX = CABasicAnimation(keyPath: "position.x")
            driftX.byValue = ((idx % 2 == 0) ? 16.0 : -16.0)
            driftX.duration = 4.0 + Double(idx) * 0.6
            driftX.autoreverses = true
            driftX.repeatCount = .infinity
            driftX.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            driftX.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.2)
            bubble.add(driftX, forKey: "bb.driftX")

            // Vertical float
            let driftY = CABasicAnimation(keyPath: "position.y")
            driftY.byValue = ((idx % 3 == 0) ? -14.0 : 14.0)
            driftY.duration = 3.2 + Double(idx) * 0.5
            driftY.autoreverses = true
            driftY.repeatCount = .infinity
            driftY.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            driftY.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.2)
            bubble.add(driftY, forKey: "bb.driftY")

            // Color cycle (if not already attached)
            if bubble.animation(forKey: "bb.colors") == nil,
               let colors = bubble.colors as? [CGColor], colors.count == 2 {
                let a = colors[0], b = colors[1]
                let colorAnim = CAKeyframeAnimation(keyPath: "colors")
                colorAnim.values = [[a, b], [b, a], [a, b]]
                colorAnim.keyTimes = [0.0, 0.5, 1.0] as [NSNumber]
                colorAnim.duration = 8.0 + Double(idx)
                colorAnim.isRemovedOnCompletion = false
                colorAnim.fillMode = .forwards
                colorAnim.repeatCount = .infinity
                colorAnim.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.0)
                bubble.add(colorAnim, forKey: "bb.colors")
            }
        }
    }

    private func shiftBigBubbleRight(_ fractionOfWidth: CGFloat = 0.18) {
        guard let bigBubbleLayer = bigBubbleLayer, let mask = bigBubbleLayer.mask as? CAShapeLayer else { return }

        // Compute geometry in current coordinates
        let diameter = min(view.bounds.width, view.bounds.height) * 0.7
        let centerY = view.bounds.midY
        let startCenterX = view.bounds.midX + bigBubbleOffsetX
        let endCenterX = startCenterX + view.bounds.width * fractionOfWidth

        let startPath = UIBezierPath(ovalIn: CGRect(x: startCenterX - diameter / 2,
                                                    y: centerY - diameter / 2,
                                                    width: diameter,
                                                    height: diameter)).cgPath
        let endPath = UIBezierPath(ovalIn: CGRect(x: endCenterX - diameter / 2,
                                                  y: centerY - diameter / 2,
                                                  width: diameter,
                                                  height: diameter)).cgPath

        // Reduce Motion: jump to final state
        if UIAccessibility.isReduceMotionEnabled {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            mask.path = endPath
            CATransaction.commit()
            bigBubbleOffsetX += view.bounds.width * fractionOfWidth
            return
        }

        // Animate the path for a smooth shift to the right
        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = startPath
        anim.toValue = endPath
        anim.duration = defaultAnimDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        anim.beginTime = CACurrentMediaTime()
        mask.add(anim, forKey: "bb.big.shiftRight")

        // Commit model values so it stays after animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.path = endPath
        CATransaction.commit()
        bigBubbleOffsetX += view.bounds.width * fractionOfWidth
    }
    private func setBigBubbleOpacity(_ to: Float, duration: CFTimeInterval? = nil) {
        guard let bigBubbleLayer = bigBubbleLayer else { return }
        let d = duration ?? defaultAnimDuration

        if UIAccessibility.isReduceMotionEnabled || d == 0 {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            bigBubbleLayer.opacity = to
            CATransaction.commit()
            return
        }

        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = bigBubbleLayer.opacity
        anim.toValue = to
        anim.duration = d
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bigBubbleLayer.add(anim, forKey: "bb.big.opacity")

        // commit model value so it sticks after the animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bigBubbleLayer.opacity = to
        CATransaction.commit()
    }
    // MARK: - Performance helpers for smoother transitions
    private func pauseLayer(_ layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = pausedTime
    }

    private func resumeLayer(_ layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }

    private func pauseSmallBubbles() {
        for bubble in smallBubbleLayers { pauseLayer(bubble) }
    }

    private func resumeSmallBubbles() {
        for bubble in smallBubbleLayers { resumeLayer(bubble) }
    }
    private func shiftSmallBubblesLeft(_ fractionOfWidth: CGFloat = 0.18) {
        guard !smallBubbleLayers.isEmpty else { return }
        let shift = view.bounds.width * fractionOfWidth
        for bubble in smallBubbleLayers {
            if UIAccessibility.isReduceMotionEnabled {
                // No animation: commit final position instantly
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                bubble.position.x -= shift
                CATransaction.commit()
            } else {
                let anim = CABasicAnimation(keyPath: "position.x")
                anim.byValue = -shift
                anim.duration = defaultAnimDuration
                anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                bubble.add(anim, forKey: "bb.shiftLeft")

                // Update model value so it stays after the animation
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                bubble.position.x -= shift
                CATransaction.commit()
            }
        }
    }
    // MARK: - Rooms Hub (Create or Select)
    private func presentRoomsChoice(with rooms: [RoomObject]) {
        let sheet = UIAlertController(title: "Your Room",
                                      message: rooms.isEmpty ? "Create your first room" : "Create a new room or choose one",
                                      preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Create new room", style: .default, handler: { _ in
            self.promptForRoomName()
        }))

        if !rooms.isEmpty {
            sheet.addAction(UIAlertAction(title: "Select existing…", style: .default, handler: { _ in
                let picker = RoomsPickerController(rooms: rooms) { selected in
                    self.presentRoomScene(for: selected)
                }
                picker.modalPresentationStyle = .pageSheet
                self.present(picker, animated: true)
            }))
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad compatibility
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY-44, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }

        present(sheet, animated: true)
    }

    private func promptForRoomName() {
        let alert = UIAlertController(title: "New Room",
                                      message: "Give your room a name",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g. Studio A"
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await Database.shared.addRoom(name: name.isEmpty ? "Untitled Room" : name, ownerEmail: self.lastLoggedInEmail)
                    let rooms = try await Database.shared.getAllRooms()
                    await MainActor.run {
                        if let latest = rooms.first {
                            self.presentRoomScene(for: latest)
                        } else {
                            self.presentRoomsChoice(with: rooms)
                        }
                    }
                } catch {
                    await MainActor.run {
                        let alert = UIAlertController(title: "Error", message: "Failed to refresh rooms. Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }))
        present(alert, animated: true)
    }

    private func presentRoomScene(for meta: RoomObject) {
        let roomVC = RoomViewController()
        roomVC.modalPresentationStyle = .fullScreen
        roomVC.currentRoom = meta
        roomVC.userEmail = self.lastLoggedInEmail
        if let nav = self.navigationController {
            nav.pushViewController(roomVC, animated: true)
        } else {
            self.present(roomVC, animated: true)
        }
    }
    // Lightweight table to pick an existing room
    private final class RoomsPickerController: UITableViewController {
        private var rooms: [RoomObject]
        private var onSelect: (RoomObject) -> Void

        init(rooms: [RoomObject], onSelect: @escaping (RoomObject) -> Void) {
            self.rooms = rooms
            self.onSelect = onSelect
            super.init(style: .insetGrouped)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Select Room"
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        }

        @objc private func close() { dismiss(animated: true) }

        override func numberOfSections(in tableView: UITableView) -> Int { 1 }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rooms.count }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let r = rooms[indexPath.row]
            var conf = UIListContentConfiguration.subtitleCell()
            conf.text = r.name
            let df = DateFormatter()
            df.dateStyle = .medium; df.timeStyle = .short
            conf.secondaryText = df.string(from: r.createdAt)
            cell.contentConfiguration = conf
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let r = rooms[indexPath.row]
            dismiss(animated: true) {
                self.onSelect(r)
            }
        }
    }

    // MARK: - Navigation to 3D Room
}
