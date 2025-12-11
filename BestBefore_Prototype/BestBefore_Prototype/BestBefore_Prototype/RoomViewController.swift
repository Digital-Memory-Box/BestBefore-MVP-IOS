//
//  RoomViewController.swift
//  BestBefore_Prototype
//
//  Created by Arya Zaeri on 4.11.2025.
//


import Foundation
import UIKit
import SceneKit
import PhotosUI
import UserNotifications
import CoreImage
import CoreImage.CIFilterBuiltins
import EventKit
#if canImport(RealmSwift)
import RealmSwift
#endif

// Simple profile persistence
struct BBProfile: Codable { var name: String; var email: String }
enum BBProfileStore {
    private static let nameKey = "bb.profile.name"
    private static let emailKey = "bb.profile.email"

    static func load() -> BBProfile? {
        let n = UserDefaults.standard.string(forKey: nameKey)
        let e = UserDefaults.standard.string(forKey: emailKey)
        if let e = e, let n = n { return BBProfile(name: n, email: e) }
        if let e = e { return BBProfile(name: "", email: e) }
        if let n = n { return BBProfile(name: n, email: "") }
        return nil
    }

    static func save(_ p: BBProfile) {
        UserDefaults.standard.set(p.name, forKey: nameKey)
        UserDefaults.standard.set(p.email, forKey: emailKey)
    }
}

final class RoomViewController: UIViewController {

    private var scnView: SCNView!
    private let scene = SCNScene()
    private var cameraNode: SCNNode!
    private var lookTarget: SCNNode!
    private var activeFrameNode: SCNNode?
    private var photoPicker: PHPickerViewController?

    // Time Capsule (room lock) state
    private var lockEndDate: Date?
    private var lockTimer: Timer?
    private var lockOverlay: UIView?
    private var countdownLabel: UILabel?

    // Incoming context
    var currentRoom: RoomObject?
    var userEmail: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // SceneKit view
        scnView = SCNView(frame: .zero)
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.scene = scene
        scnView.backgroundColor = UIColor(white: 0.12, alpha: 1.0) // slightly lighter so dark scenes aren't pitch black
        scnView.allowsCameraControl = true  // enable orbit/pan/zoom controls like the video
        scnView.showsStatistics = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
        view.addSubview(scnView)

        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: view.topAnchor),
            scnView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scnView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        setupRoom()
        addProfileButton()
        addTimeCapsuleButton()
        addCalendarSuggestButton()
        addRoomInfoButton()

        // Custom gestures: pinch to zoom (orthographic) and two-finger pan to move within the room
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.cancelsTouchesInView = false
        scnView.addGestureRecognizer(pinch)

        let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        scnView.addGestureRecognizer(twoFingerPan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTouchesRequired = 1
        tap.cancelsTouchesInView = false
        scnView.addGestureRecognizer(tap)

        // Restore time capsule lock if previously set for this room
        if let room = currentRoom, let ts = UserDefaults.standard.object(forKey: "bb.lock.end.\(roomIdString(room))") as? TimeInterval {
            let end = Date(timeIntervalSince1970: ts)
            if end > Date() {
                lockEndDate = end
                applyLockStateIfNeeded()
            } else {
                UserDefaults.standard.removeObject(forKey: "bb.lock.end.\(roomIdString(room))")
            }
        }

        // Ask notification permission early (used when setting a time capsule)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        UNUserNotificationCenter.current().delegate = self
    }
    private func addProfileButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "person.circle"), for: .normal)
        } else {
            btn.setTitle("Profile", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            btn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            btn.widthAnchor.constraint(equalToConstant: 30),
            btn.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    private func addTimeCapsuleButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "timer"), for: .normal)
        } else {
            btn.setTitle("Timer", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(timeCapsuleTapped), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            btn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            btn.widthAnchor.constraint(equalToConstant: 30),
            btn.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func addCalendarSuggestButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "calendar.badge.plus"), for: .normal)
        } else {
            btn.setTitle("Calendar", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(calendarSuggestTapped), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            btn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            btn.widthAnchor.constraint(equalToConstant: 34),
            btn.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func addRoomInfoButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "info.circle"), for: .normal)
        } else {
            btn.setTitle("Info", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(roomInfoTapped), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            btn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            btn.widthAnchor.constraint(equalToConstant: 34),
            btn.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    @objc private func roomInfoTapped() {
        presentRoomInfo()
    }

    private func presentRoomInfo() {
        let roomName = currentRoom?.name ?? "Untitled Room"
        let createdAt = currentRoom?.createdAt

        // Who created it: prefer stored profile name, fall back to email, then unknown
        let profile = BBProfileStore.load()
        let creator: String = {
            if let name = profile?.name, !name.isEmpty { return name }
            if let email = profile?.email, !email.isEmpty { return email }
            if let email = userEmail, !email.isEmpty { return email }
            return "(unknown)"
        }()

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let createdText = createdAt != nil ? df.string(from: createdAt!) : "(unknown)"

        let message = "Name: \(roomName)\nCreated: \(createdText)\nBy: \(creator)"

        let alert = UIAlertController(title: "Room Info", message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Switch Room…", style: .default, handler: { _ in
            self.presentRoomsSwitcher()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.maxX - 30, y: self.view.bounds.maxY - 60, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private func presentRoomsSwitcher() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let rooms = try await Database.shared.getAllRooms()
                await MainActor.run {
                    guard !rooms.isEmpty else {
                        let alert = UIAlertController(title: "No Rooms", message: "Create a room first, then you can switch between them.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                        return
                    }
                    let picker = RoomsSwitchController(rooms: rooms) { [weak self] selected in
                        self?.presentRoom(meta: selected)
                    }
                    if #available(iOS 15.0, *) {
                        picker.modalPresentationStyle = .pageSheet
                        if let sheet = picker.sheetPresentationController {
                            sheet.detents = [.medium(), .large()]
                        }
                    } else {
                        picker.modalPresentationStyle = .pageSheet
                    }
                    self.present(picker, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Room Error",
                                                  message: "Failed to load rooms. Please try again.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private final class RoomsSwitchController: UITableViewController {
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
            title = "Switch Room"
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        }

        override func numberOfSections(in tableView: UITableView) -> Int { 1 }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rooms.count }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let r = rooms[indexPath.row]
            if #available(iOS 14.0, *) {
                var conf = UIListContentConfiguration.subtitleCell()
                conf.text = r.name
                let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short
                conf.secondaryText = df.string(from: r.createdAt)
                cell.contentConfiguration = conf
            } else {
                cell.textLabel?.text = r.name
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let r = rooms[indexPath.row]
            dismiss(animated: true) { [onSelect] in onSelect(r) }
        }
    }

    @objc private func calendarSuggestTapped() {
        let sheet = UIAlertController(title: "Create Room from Calendar",
                                      message: "Import an event and make a room with its name.",
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "From iOS Calendars…", style: .default, handler: { _ in
            self.presentEventPicker()
        }))
        sheet.addAction(UIAlertAction(title: "From Google Calendar (via iOS)", style: .default, handler: { _ in
            let alert = UIAlertController(title: "Google Calendar",
                                          message: "Add your Google account to iOS Settings ▸ Calendar. Then choose ‘From iOS Calendars…’.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: 20, y: self.view.bounds.maxY - 60, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(sheet, animated: true)
    }

    @objc private func timeCapsuleTapped() {
        presentTimeCapsuleSheet()
    }
    @objc private func profileTapped() {
        let profile = BBProfileStore.load()
        let emailText = profile?.email ?? userEmail ?? "(unknown)"
        let usernameText = (profile?.name.isEmpty == false ? profile!.name : "(no name)")
        let roomName = currentRoom?.name ?? "Untitled Room"

        let sheet = UIAlertController(title: "Account",
                                      message: "User: \(usernameText)\nEmail: \(emailText)\nRoom: \(roomName)",
                                      preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "View & Edit Profile…", style: .default, handler: { _ in
            self.presentProfileEditor()
        }))

        sheet.addAction(UIAlertAction(title: "Rename Room", style: .default, handler: { _ in
            self.promptRenameRoom()
        }))

        sheet.addAction(UIAlertAction(title: "Delete Room", style: .destructive, handler: { _ in
            self.confirmDeleteRoom()
        }))

//        sheet.addAction(UIAlertAction(title: "Start Time Capsule…", style: .default, handler: { _ in
//            self.presentTimeCapsuleSheet()
//        }))

        sheet.addAction(UIAlertAction(title: "Share Room…", style: .default, handler: { _ in
            self.presentShareOptions()
        }))

        sheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            self.logoutToLogin()
        }))

        sheet.addAction(UIAlertAction(title: "Close", style: .cancel))

        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.maxX - 30, y: 44, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }

        present(sheet, animated: true)
    }

    private func presentProfileEditor() {
        let current = BBProfileStore.load() ?? BBProfile(name: "", email: userEmail ?? "")
        let editor = ProfileEditorController(defaultProfile: current) { [weak self] newProfile in
            guard let self = self else { return }
            BBProfileStore.save(newProfile)
            // Update our cached email so the Account sheet reflects it immediately
            if !newProfile.email.isEmpty { self.userEmail = newProfile.email }
        }
        if #available(iOS 15.0, *) {
            editor.modalPresentationStyle = .pageSheet
            if let sheet = editor.sheetPresentationController {
                sheet.detents = [.medium()]
            }
        } else {
            editor.modalPresentationStyle = .pageSheet
        }
        present(editor, animated: true)
    }

    private func promptRenameRoom() {
        guard let room = currentRoom else { return }
        let alert = UIAlertController(title: "Rename Room", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = room.name
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let name = newName, !name.isEmpty else { return }
#if canImport(RealmSwift)
            Task {
                do {
                    try await Database.shared.updateRoomName(id: room.id, newName: name)
                } catch {
                    print("Failed to rename room:", error)
                }
            }
#else
            Task {
                do {
                    try await Database.shared.updateRoomName(id: roomIdString(room), newName: name)
                } catch {
                    print("Failed to rename room:", error)
                }
            }
#endif
            self.currentRoom?.name = name
        }))
        present(alert, animated: true)
    }

    private func confirmDeleteRoom() {
        guard let room = currentRoom else { return }
        let alert = UIAlertController(title: "Delete Room",
                                      message: "This will remove \"\(room.name)\" from your device.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
#if canImport(RealmSwift)
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await Database.shared.deleteRoom(id: room.id)
                    await MainActor.run {
                        self.logoutToLogin()
                    }
                } catch {
                    print("Failed to delete room:", error)
                }
            }
#else
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await Database.shared.deleteRoom(id: roomIdString(room))
                    await MainActor.run {
                        self.logoutToLogin()
                    }
                } catch {
                    print("Failed to delete room:", error)
                }
            }
#endif
        }))
        present(alert, animated: true)
    }

    private func logoutToLogin() {
        if let nav = self.navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    // Lightweight Profile Editor (name + email)
    private final class ProfileEditorController: UIViewController {
        private let onSave: (BBProfile) -> Void
        private let nameField = UITextField()
        private let emailField = UITextField()

        init(defaultProfile: BBProfile?, onSave: @escaping (BBProfile) -> Void) {
            self.onSave = onSave
            super.init(nibName: nil, bundle: nil)
            if let p = defaultProfile {
                nameField.text = p.name
                emailField.text = p.email
            }
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .systemBackground
            title = "Profile"

            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 12
            stack.translatesAutoresizingMaskIntoConstraints = false

            let nameLabel = UILabel(); nameLabel.text = "Username"; nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            nameField.borderStyle = .roundedRect
            nameField.autocapitalizationType = .words

            let emailLabel = UILabel(); emailLabel.text = "Email"; emailLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            emailField.borderStyle = .roundedRect
            emailField.keyboardType = .emailAddress
            emailField.autocapitalizationType = .none

            let btns = UIStackView(); btns.axis = .horizontal; btns.distribution = .fillEqually; btns.spacing = 12
            let cancel = UIButton(type: .system); cancel.setTitle("Cancel", for: .normal)
            cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            let save = UIButton(type: .system); save.setTitle("Save", for: .normal)
            save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
            btns.addArrangedSubview(cancel); btns.addArrangedSubview(save)

            stack.addArrangedSubview(nameLabel); stack.addArrangedSubview(nameField)
            stack.addArrangedSubview(emailLabel); stack.addArrangedSubview(emailField)
            stack.addArrangedSubview(btns)

            view.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
            ])
        }

        @objc private func cancelTapped() { dismiss(animated: true) }
        @objc private func saveTapped() {
            let p = BBProfile(name: nameField.text ?? "", email: emailField.text ?? "")
            dismiss(animated: true) { [onSave] in onSave(p) }
        }
    }

    // MARK: - Room Sharing (Link & QR)
    private func presentShareOptions() {
        guard let room = currentRoom else { return }
        let url = shareURL(for: room)

        let sheet = UIAlertController(title: "Share Room",
                                      message: room.name,
                                      preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Share Link…", style: .default, handler: { _ in
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let pop = av.popoverPresentationController {
                pop.sourceView = self.view
                pop.sourceRect = CGRect(x: self.view.bounds.maxX - 30, y: 44, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            self.present(av, animated: true)
        }))

        sheet.addAction(UIAlertAction(title: "Show QR Code", style: .default, handler: { _ in
            let img = self.generateQRCode(from: url.absoluteString, scale: 8)
            let qr = QRPreviewController(image: img, url: url, titleText: room.name)
            if #available(iOS 15.0, *) {
                qr.modalPresentationStyle = .pageSheet
                if let sheet = qr.sheetPresentationController {
                    sheet.detents = [.medium()]
                }
            } else {
                qr.modalPresentationStyle = .pageSheet
            }
            self.present(qr, animated: true)
        }))

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.maxX - 30, y: 44, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(sheet, animated: true)
    }

    private func shareURL(for room: RoomObject) -> URL {
        // Replace with your real deep link/domain when available
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "bestbefore.app"
        comps.path = "/r/\(roomIdString(room))"
        // Optional: include room name in the URL as a query item
        if !room.name.isEmpty {
            comps.queryItems = [URLQueryItem(name: "n", value: room.name)]
        }
        return comps.url ?? URL(string: "https://bestbefore.app/r/\(roomIdString(room))")!
    }

    private func generateQRCode(from string: String, scale: CGFloat = 8) -> UIImage {
        let data = Data(string.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return UIImage() }
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaled = ciImage.transformed(by: transform)
        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage()
    }

    // Lightweight QR preview controller with a Share button
    private final class QRPreviewController: UIViewController {
        private let image: UIImage
        private let url: URL
        private let titleText: String?

        init(image: UIImage, url: URL, titleText: String?) {
            self.image = image
            self.url = url
            self.titleText = titleText
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .systemBackground

            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = titleText?.isEmpty == false ? titleText : "Room QR"
            titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textAlignment = .center

            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit

            let shareBtn = UIButton(type: .system)
            shareBtn.translatesAutoresizingMaskIntoConstraints = false
            shareBtn.setTitle("Share", for: .normal)
            shareBtn.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

            view.addSubview(titleLabel)
            view.addSubview(imageView)
            view.addSubview(shareBtn)

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

                imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

                shareBtn.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
                shareBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }

        @objc private func shareTapped() {
            let items: [Any] = [url, image]
            let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let pop = av.popoverPresentationController {
                pop.sourceView = self.view
                pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY-44, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            present(av, animated: true)
        }
    }

    // MARK: - Time Capsule Picker (Alarm-style HH:MM:SS)
    private final class TimeCapsulePickerController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
        private let onConfirm: (TimeInterval) -> Void
        private let picker = UIPickerView()
        private let hoursRange = Array(0...23)
        private let minutesRange = Array(0...59)
        private let secondsRange = Array(0...59)
        private let defaultH: Int
        private let defaultM: Int
        private let defaultS: Int

        init(defaultHours: Int = 0, defaultMinutes: Int = 15, defaultSeconds: Int = 0, onConfirm: @escaping (TimeInterval) -> Void) {
            self.defaultH = max(0, min(23, defaultHours))
            self.defaultM = max(0, min(59, defaultMinutes))
            self.defaultS = max(0, min(59, defaultSeconds))
            self.onConfirm = onConfirm
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .systemBackground

            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = "Time Capsule"
            titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textAlignment = .center

            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.dataSource = self
            picker.delegate = self

            // Toolbar with Cancel / Start
            let toolbar = UIStackView()
            toolbar.axis = .horizontal
            toolbar.alignment = .center
            toolbar.distribution = .equalCentering
            toolbar.translatesAutoresizingMaskIntoConstraints = false

            let cancel = UIButton(type: .system)
            cancel.setTitle("Cancel", for: .normal)
            cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

            let start = UIButton(type: .system)
            start.setTitle("Start", for: .normal)
            start.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

            toolbar.addArrangedSubview(cancel)
            toolbar.addArrangedSubview(start)

            view.addSubview(titleLabel)
            view.addSubview(picker)
            view.addSubview(toolbar)

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

                picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
                picker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                picker.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                toolbar.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 8),
                toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                toolbar.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
            ])

            // Preselect defaults
            picker.selectRow(defaultH, inComponent: 0, animated: false)
            picker.selectRow(defaultM, inComponent: 1, animated: false)
            picker.selectRow(defaultS, inComponent: 2, animated: false)
        }

        // MARK: UIPickerView
        func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return hoursRange.count
            case 1: return minutesRange.count
            default: return secondsRange.count
            }
        }
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch component {
            case 0: return "\(hoursRange[row]) h"
            case 1: return "\(minutesRange[row]) m"
            default: return "\(secondsRange[row]) s"
            }
        }

        @objc private func cancelTapped() { dismiss(animated: true) }

        @objc private func startTapped() {
            let h = hoursRange[picker.selectedRow(inComponent: 0)]
            let m = minutesRange[picker.selectedRow(inComponent: 1)]
            let s = secondsRange[picker.selectedRow(inComponent: 2)]
            let total = TimeInterval(h * 3600 + m * 60 + s)
            dismiss(animated: true) { [onConfirm] in
                onConfirm(total)
            }
        }
    }

    // MARK: - Time Capsule (Lock Room)
    private func presentTimeCapsuleSheet() {
        let picker = TimeCapsulePickerController(defaultHours: 0, defaultMinutes: 15, defaultSeconds: 0) { [weak self] totalSeconds in
            guard let self = self else { return }
            if totalSeconds >= 1 { self.startTimeCapsule(seconds: totalSeconds) }
        }
        if #available(iOS 15.0, *) {
            picker.modalPresentationStyle = .pageSheet
            if let sheet = picker.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        } else {
            picker.modalPresentationStyle = .pageSheet
        }
        present(picker, animated: true)
    }

    private func startTimeCapsule(seconds: TimeInterval) {
        guard let room = currentRoom else { return }
        let roomId = roomIdString(room)
        let end = Date().addingTimeInterval(seconds)
        lockEndDate = end
        UserDefaults.standard.set(end.timeIntervalSince1970, forKey: "bb.lock.end.\(roomId)")
        scheduleLockNotification(end: end)
        applyLockStateIfNeeded()
    }

    private func scheduleLockNotification(end: Date) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Time Capsule Complete"
        content.body = "Your room is unlocked."
        content.sound = .default
        if let roomName = currentRoom?.name { content.subtitle = roomName }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSinceNow), repeats: false)
        let id = "bb.lock.\(currentRoom.map { roomIdString($0) } ?? UUID().uuidString)"
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(req, withCompletionHandler: nil)
    }

    private func applyLockStateIfNeeded() {
        guard let end = lockEndDate else { return }
        // Create overlay if not already present
        if lockOverlay == nil {
            let overlay = UIView()
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.backgroundColor = UIColor(white: 0, alpha: 0.35)
            overlay.isUserInteractionEnabled = false

            // container for countdown
            let container = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
            container.translatesAutoresizingMaskIntoConstraints = false
            container.layer.cornerRadius = 16
            container.clipsToBounds = true

            let title = UILabel()
            title.translatesAutoresizingMaskIntoConstraints = false
            title.text = "Time Capsule"
            title.font = .systemFont(ofSize: 16, weight: .semibold)
            title.textColor = .white

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
            label.textColor = .white
            label.textAlignment = .center
            label.text = "--:--:--"
            countdownLabel = label

            overlay.addSubview(container)
            container.contentView.addSubview(title)
            container.contentView.addSubview(label)
            view.addSubview(overlay)

            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                container.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),

                title.topAnchor.constraint(equalTo: container.contentView.topAnchor, constant: 10),
                title.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 14),
                title.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -14),

                label.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
                label.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 14),
                label.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -14),
                label.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor, constant: -10)
            ])

            lockOverlay = overlay
        }

        // Block interactions with scene (overlay intercepts touches)
        scnView.isUserInteractionEnabled = false
        updateCountdownLabel()
        startLockCountdownTimer()
    }

    private func startLockCountdownTimer() {
        lockTimer?.invalidate()
        lockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdownLabel()
        }
        RunLoop.main.add(lockTimer!, forMode: .common)
    }

    private func updateCountdownLabel() {
        guard let end = lockEndDate else { return }
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            lockFinished()
            return
        }
        let total = Int(remaining)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        countdownLabel?.text = String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func lockFinished() {
        lockTimer?.invalidate(); lockTimer = nil
        countdownLabel?.text = "00:00:00"
        // Re-enable interactions
        scnView.isUserInteractionEnabled = true

        // Clear saved state
        if let room = currentRoom {
            let roomId = roomIdString(room)
            UserDefaults.standard.removeObject(forKey: "bb.lock.end.\(roomId)")
        }
        lockEndDate = nil

        // Remove overlay after a small fade
        if let overlay = lockOverlay {
            UIView.animate(withDuration: 0.25, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
            lockOverlay = nil
            countdownLabel = nil
        }

        // Optional: in-app alert that the lock finished
//        let alert = UIAlertController(title: "Time Capsule Complete", message: "Your room is unlocked.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
    }

    private func setupRoom() {
        // Camera (isometric-ish angle like the reference video)
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        if let cam = cameraNode.camera {
            cam.usesOrthographicProjection = true
            cam.orthographicScale = 5.5   // widen view; tune as needed
            cam.zNear = 0.01
            cam.zFar = 200.0
        }

        // Position camera on a circle around origin at ~35° pitch, 45° yaw
        let radius: Float = 10.0
        let pitchDeg: Float = 35.264   // classic isometric pitch
        let yawDeg: Float = 45.0
        let pitch = pitchDeg * .pi / 180
        let yaw = yawDeg * .pi / 180
        let y = radius * sin(pitch)
        let flat = radius * cos(pitch)
        let x = flat * cos(yaw)
        let z = flat * sin(yaw)
        cameraNode.position = SCNVector3(x, y, z)

        // Look at center at about eye height
        lookTarget = SCNNode()
        lookTarget.position = SCNVector3(0, 1.2, 0)
        scene.rootNode.addChildNode(lookTarget)
        let look = SCNLookAtConstraint(target: lookTarget)
        look.isGimbalLockEnabled = true
        cameraNode.constraints = [look]

        // Softer, brighter lighting so geometry is clearly visible
        let omni = SCNNode()
        omni.light = SCNLight()
        omni.light?.type = .omni
        omni.light?.intensity = 1200   // brighter so it doesn't look black
        omni.position = SCNVector3(0, 4, 4)
        scene.rootNode.addChildNode(omni)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 650
        ambient.light?.color = UIColor(white: 0.9, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        // Gentle directional light for readable shading
        let dir = SCNNode()
        dir.light = SCNLight()
        dir.light?.type = .directional
        dir.light?.intensity = 600
        dir.eulerAngles = SCNVector3(-0.9, 0.6, 0)
        scene.rootNode.addChildNode(dir)

        // Floor
        let floor = SCNFloor()
        floor.reflectivity = 0.02
        floor.firstMaterial = SCNMaterial()
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.16, alpha: 1)
        floor.firstMaterial?.lightingModel = .lambert
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)

        // Gentle fog to compress depth and feel flatter
        // Keep fog subtle and farther so it doesn't swallow the scene
        scene.fogStartDistance = 18.0
        scene.fogEndDistance = 28.0
        scene.fogColor = UIColor(white: 0.12, alpha: 1.0)


        // Build a single interior corner (two perpendicular walls)
        let corner = buildSingleCornerRoom()

        // === Add two interactive frames on the white walls ===
        let frameSize1 = CGSize(width: 0.9, height: 0.7)
        let frameSize2 = CGSize(width: 0.8, height: 0.8)

        // Frame on the RIGHT wall (child of rightWall so it follows its surface)
        if let rightWall = corner.childNode(withName: "rightWall", recursively: false) {
            let f1 = makeFrameNode(size: frameSize1, name: "frame1")
            // Face inward (toward -Z), and place at the center of the wall
            f1.eulerAngles.y = .pi
            let thicknessZ = Float(rightWall.boundingBox.max.z - rightWall.boundingBox.min.z)
            f1.position = SCNVector3(0.0, 0.0, thicknessZ / 2 + 0.001)
            rightWall.addChildNode(f1)
        }

        // Frame on the LEFT wall (child of leftWall, rotate to face +X into the room)
        if let leftWall = corner.childNode(withName: "leftWall", recursively: false) {
            let f2 = makeFrameNode(size: frameSize2, name: "frame2")
            // Face inward (+X) and center on the wall
            f2.eulerAngles.y = -.pi / 2
            let thicknessX = Float(leftWall.boundingBox.max.x - leftWall.boundingBox.min.x)
            f2.position = SCNVector3(thicknessX / 2 + 0.001, 0.0, 0.0)
            leftWall.addChildNode(f2)
        }

        // Configure SceneKit's camera controller to allow turntable-style orbiting
        scnView.pointOfView = cameraNode
        let controller = scnView.defaultCameraController
        controller.interactionMode = .orbitTurntable
        controller.inertiaEnabled = true
        controller.maximumVerticalAngle = 80
        controller.minimumVerticalAngle = 5
        controller.target = lookTarget.presentation.worldPosition
    }

    // MARK: - Single Corner Room (two perpendicular walls meeting like an interior cube corner)
    @discardableResult
    private func buildSingleCornerRoom() -> SCNNode {
        let wallHeight: CGFloat = 2.1
        let wallLength: CGFloat = 3.2
        let thickness: CGFloat = 0.05

        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(white: 0.94, alpha: 1.0)
        mat.lightingModel = .lambert
        mat.roughness.contents = 0.4
        mat.metalness.contents = 0.0

        // Right wall (extends along +X)
        let rightGeom = SCNBox(width: wallLength, height: wallHeight, length: thickness, chamferRadius: 0)
        rightGeom.firstMaterial = mat
        let rightWall = SCNNode(geometry: rightGeom)
        rightWall.name = "rightWall"
        rightWall.position = SCNVector3(Float(wallLength/2), Float(wallHeight/2), 0)

        // Left wall (extends along +Z)
        let leftGeom = SCNBox(width: thickness, height: wallHeight, length: wallLength, chamferRadius: 0)
        leftGeom.firstMaterial = mat
        let leftWall = SCNNode(geometry: leftGeom)
        leftWall.name = "leftWall"
        leftWall.position = SCNVector3(0, Float(wallHeight/2), Float(wallLength/2))

        // Group them so we can place/rotate as a single corner
        let cornerRoot = SCNNode()
        cornerRoot.name = "cornerRoot"
        cornerRoot.position = SCNVector3(-1.2, 0, -1.2) // tuned for your isometric camera
        cornerRoot.addChildNode(rightWall)
        cornerRoot.addChildNode(leftWall)

        // Tiny cap to hide the seam
        let capGeom = SCNBox(width: thickness, height: wallHeight, length: thickness, chamferRadius: 0)
        capGeom.firstMaterial = mat
        let capNode = SCNNode(geometry: capGeom)
        capNode.position = SCNVector3(0, Float(wallHeight/2), 0)
        cornerRoot.addChildNode(capNode)

        scene.rootNode.addChildNode(cornerRoot)
        return cornerRoot
    }

    // MARK: - Frame Helpers
    private func makeFrameNode(size: CGSize, name: String) -> SCNNode {
        // Backing plane (image surface)
        let plane = SCNPlane(width: size.width, height: size.height)
        let imgMat = SCNMaterial()
        imgMat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0) // placeholder until user picks
        imgMat.isDoubleSided = true  // avoid backface culling when mounted on walls
        plane.firstMaterial = imgMat
        let imageNode = SCNNode(geometry: plane)
        imageNode.name = name

        // Thin border using a slightly larger plane with an unlit material and "+" blend
        let border = SCNPlane(width: size.width + 0.04, height: size.height + 0.04)
        let borderMat = SCNMaterial()
        borderMat.diffuse.contents = UIColor(white: 1.0, alpha: 0.85)
        borderMat.emission.contents = UIColor(white: 1.0, alpha: 0.4)
        borderMat.lightingModel = .constant
        border.firstMaterial = borderMat
        let borderNode = SCNNode(geometry: border)
        borderNode.position = SCNVector3(0, 0, -0.0006) // sit just behind to avoid z-fighting

        let root = SCNNode()
        root.addChildNode(borderNode)
        root.addChildNode(imageNode)
        return root
    }

// MARK: - Gesture Handlers
@objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
    guard let cam = cameraNode.camera, cam.usesOrthographicProjection else { return }
    // Adjust ortho scale to zoom in/out smoothly
    let current = cam.orthographicScale
    let factor = Double(1.0 / gr.scale) // pinch in -> zoom in
    let next = max(3.5, min(7.5, current * factor))
    cam.orthographicScale = next
    gr.scale = 1.0
}

@objc private func handleTwoFingerPan(_ gr: UIPanGestureRecognizer) {
    // Translate the look target on X/Z plane so user can roam
    let translation = gr.translation(in: scnView)
    gr.setTranslation(.zero, in: scnView)

    // Convert screen delta to world-space movement roughly proportional to view size
    let dx = Float(-translation.x) * 0.01
    let dz = Float( translation.y) * 0.01
    var pos = lookTarget.position
    pos.x = max(-3.5, min(3.5, pos.x + dx))
    pos.z = max(-3.5, min(3.5, pos.z + dz))
    lookTarget.position = pos

    // Keep camera controller looking at the new target
    scnView.defaultCameraController.target = lookTarget.presentation.worldPosition
}

    // MARK: - Tap hit-testing for frames
    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        let pt = gr.location(in: scnView)
        let results = scnView.hitTest(pt, options: [SCNHitTestOption.firstFoundOnly: true, SCNHitTestOption.boundingBoxOnly: false])
        guard let hit = results.first else { return }

        // Find the frame node by walking up the chain (we named the image child "frame1"/"frame2")
        var node: SCNNode? = hit.node
        while let n = node, n.name != "frame1" && n.name != "frame2" && n.parent != nil {
            node = n.parent
        }
        guard let frameNode = node, frameNode.name == "frame1" || frameNode.name == "frame2" else { return }

        activeFrameNode = frameNode
        presentPhotoPicker()
    }

    // MARK: - Photo picker
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        photoPicker = picker
        present(picker, animated: true)
    }
}

extension RoomViewController: UNUserNotificationCenterDelegate {
    // Show the local notification even if the app is foregrounded
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

extension RoomViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        defer { picker.dismiss(animated: true); photoPicker = nil }
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else { return }

        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let self = self, let img = obj as? UIImage else { return }
            DispatchQueue.main.async {
                // The visible image plane is the child named frame1/frame2; set its material
                if let frame = self.activeFrameNode,
                   let plane = frame.geometry as? SCNPlane {
                    plane.firstMaterial?.diffuse.contents = img
                } else if let frame = self.activeFrameNode?.childNodes.first(where: { ($0.geometry as? SCNPlane) != nil }),
                          let plane = frame.geometry as? SCNPlane {
                    plane.firstMaterial?.diffuse.contents = img
                }
                self.activeFrameNode = nil
            }
        }
    }
}

extension RoomViewController {
    // MARK: - Calendar Import
    private func presentEventPicker() {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    let alert = UIAlertController(title: "Calendar Access Denied",
                                                  message: "Enable access in Settings to import events.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    return
                }
                let picker = EventsPickerController(eventStore: store, onSelect: { [weak self] event in
                    guard let self = self else { return }
                    // Create a room from the selected event
                    let name = (event.title?.isEmpty == false) ? event.title! : "Untitled Event"
                    let owner = self.userEmail ?? ""
                    Task { [weak self] in
                        guard let self = self else { return }
                        do {
                            try await Database.shared.addRoom(name: name, ownerEmail: owner)
                            let rooms = try await Database.shared.getAllRooms()
                            if let meta = rooms.first {
                                await MainActor.run {
                                    self.presentRoom(meta: meta)
                                }
                            }
                        } catch {
                            print("Failed to import calendar event room:", error)
                        }
                    }
                })
                if #available(iOS 15.0, *) {
                    picker.modalPresentationStyle = .pageSheet
                    if let sheet = picker.sheetPresentationController {
                        sheet.detents = [.medium(), .large()]
                    }
                } else {
                    picker.modalPresentationStyle = .pageSheet
                }
                self.present(picker, animated: true)
            }
        }
    }

    private func presentRoom(meta: RoomObject) {
        // Navigate to the new room
        let roomVC = RoomViewController()
        roomVC.modalPresentationStyle = .fullScreen
        roomVC.currentRoom = meta
        roomVC.userEmail = self.userEmail
        if let nav = self.navigationController {
            nav.pushViewController(roomVC, animated: true)
        } else {
            self.present(roomVC, animated: true)
        }
    }

    private final class EventsPickerController: UITableViewController {
        private let store: EKEventStore
        private var events: [EKEvent] = []
        private var onSelect: (EKEvent) -> Void

        init(eventStore: EKEventStore, onSelect: @escaping (EKEvent) -> Void) {
            self.store = eventStore
            self.onSelect = onSelect
            super.init(style: .insetGrouped)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Pick an Event"
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            loadUpcoming()
        }

        private func loadUpcoming() {
            let calendars = store.calendars(for: .event)
            let start = Date()
            let end = Calendar.current.date(byAdding: .day, value: 30, to: start) ?? start
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
            let found = store.events(matching: predicate).sorted(by: { $0.startDate < $1.startDate })
            self.events = found
            self.tableView.reloadData()
        }

        override func numberOfSections(in tableView: UITableView) -> Int { 1 }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { events.count }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let ev = events[indexPath.row]
            if #available(iOS 14.0, *) {
                var conf = UIListContentConfiguration.subtitleCell()
                conf.text = ev.title ?? "(No Title)"
                let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short
                conf.secondaryText = df.string(from: ev.startDate)
                cell.contentConfiguration = conf
            } else {
                cell.textLabel?.text = ev.title ?? "(No Title)"
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let ev = events[indexPath.row]
            dismiss(animated: true) { [onSelect] in onSelect(ev) }
        }
    }
}

private func roomIdString(_ room: RoomObject) -> String {
#if canImport(RealmSwift)
    // If Realm's ObjectId is available at compile time, try to cast and stringify safely
    if let objectId = (room.id as AnyObject) as? ObjectId {
        // ObjectId conforms to CustomStringConvertible; interpolation yields the hex string
        return "\(objectId)"
    }
#endif
    // If the id is already a String, return it directly
    if let s = room.id as? String { return s }
    // Otherwise, fall back to a descriptive string
    return String(describing: room.id)
}
