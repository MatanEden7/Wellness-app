import UIKit

/// Implements `PresentationHostApi` (Dart → Swift) for native sheets,
/// alerts, menus, date pickers, share, and haptics.
@available(iOS 15.0, *)
final class PresentationHostApiImpl: PresentationHostApi {

    private weak var presenter: UIViewController?

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    // MARK: - Action sheet

    func presentActionSheet(
        spec: ActionSheetSpec,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        guard let presenter else { completion(.success(nil)); return }

        let alert = UIAlertController(
            title: spec.title,
            message: spec.message,
            preferredStyle: .actionSheet
        )

        for item in spec.items.compactMap({ $0 }) {
            let style: UIAlertAction.Style = item.isDestructive ? .destructive : .default
            alert.addAction(UIAlertAction(title: item.title, style: style) { _ in
                completion(.success(item.id))
            })
        }

        alert.addAction(UIAlertAction(title: spec.cancelLabel, style: .cancel) { _ in
            completion(.success(nil))
        })

        presenter.present(alert, animated: true)
    }

    // MARK: - Alert

    func presentAlert(
        spec: AlertSpec,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let presenter else { completion(.success(false)); return }

        let alert = UIAlertController(
            title: spec.title,
            message: spec.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: spec.cancelLabel, style: .cancel) { _ in
            completion(.success(false))
        })

        let confirmStyle: UIAlertAction.Style = spec.isDestructive ? .destructive : .default
        alert.addAction(UIAlertAction(title: spec.confirmLabel, style: confirmStyle) { _ in
            completion(.success(true))
        })

        presenter.present(alert, animated: true)
    }

    // MARK: - Menu (popover on iPad, action sheet on phone)

    func presentMenu(
        spec: MenuSpec,
        anchor: AnchorRect,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        // Reuse action-sheet path — menus share the same data shape.
        let sheetSpec = ActionSheetSpec(
            title: nil, message: nil,
            items: spec.items,
            cancelLabel: "Cancel"
        )
        presentActionSheet(spec: sheetSpec, completion: completion)
    }

    // MARK: - Date picker

    func presentDatePicker(
        spec: DatePickerSpec,
        completion: @escaping (Result<Int64?, Error>) -> Void
    ) {
        guard let presenter else { completion(.success(nil)); return }

        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels

        switch spec.mode {
        case "date":     picker.datePickerMode = .date
        case "time":     picker.datePickerMode = .time
        default:         picker.datePickerMode = .dateAndTime
        }

        if let ms = spec.initialTimestamp {
            picker.date = Date(timeIntervalSince1970: Double(ms) / 1000)
        }
        if let ms = spec.minTimestamp {
            picker.minimumDate = Date(timeIntervalSince1970: Double(ms) / 1000)
        }
        if let ms = spec.maxTimestamp {
            picker.maximumDate = Date(timeIntervalSince1970: Double(ms) / 1000)
        }

        let container = UIAlertController(title: "\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        container.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: container.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: container.view.topAnchor, constant: 8),
        ])

        container.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(.success(nil))
        })
        container.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            let ms = Int64(picker.date.timeIntervalSince1970 * 1000)
            completion(.success(ms))
        })

        presenter.present(container, animated: true)
    }

    // MARK: - Share

    func presentShare(
        paths: [String],
        anchor: AnchorRect,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let presenter else { completion(.success(())); return }

        let items: [Any] = paths.compactMap { URL(fileURLWithPath: $0) }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            completion(.success(()))
        }
        presenter.present(vc, animated: true)
    }

    // MARK: - Haptics

    func haptic(kind: String) throws {
        Haptics.trigger(kind)
    }
}
