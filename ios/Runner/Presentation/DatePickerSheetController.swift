import UIKit

/// A `UIDatePicker` in a proper sheet, with a Cancel/Done toolbar.
///
/// Replaces a hack: the picker used to be added as a *subview* of a
/// `UIAlertController` whose title was nine newline characters, sized to
/// reserve room. That is not a supported use of UIAlertController — its
/// content view has no layout contract — and it showed: the wheels were
/// clipped top and bottom, and the reserved height was a guess that Dynamic
/// Type could invalidate.
///
/// This is the ordinary way: a view controller owning its picker, presented
/// with a `UISheetPresentationController` detent sized to its content.
@available(iOS 15.0, *)
final class DatePickerSheetController: UIViewController {

    private let picker = UIDatePicker()
    private let onDone: (Date?) -> Void

    /// The button titles, handed over from Dart already translated. See
    /// `DatePickerSpec.cancelLabel`.
    private let cancelLabel: String
    private let doneLabel: String

    /// Applied in `viewDidLoad`, not `init`: touching `view` in an
    /// initialiser forces the view hierarchy to load before the controller is
    /// finished being built.
    private let isRTL: Bool

    /// Guards against the completion firing twice — once from a button and
    /// again from an interactive dismiss. Dart awaits a single reply, and a
    /// second one on the same pigeon channel is a hard error.
    private var didComplete = false

    init(spec: DatePickerSpec, onDone: @escaping (Date?) -> Void) {
        self.onDone = onDone
        self.cancelLabel = spec.cancelLabel
        self.doneLabel = spec.doneLabel
        // Mirrors the sheet for Hebrew, so Cancel/Done land on the side the
        // rest of the app puts them on.
        self.isRTL = Locale.characterDirection(
            forLanguage: spec.localeIdentifier) == .rightToLeft
        super.init(nibName: nil, bundle: nil)

        // The app's language, not the device's. Drives the month name, the
        // weekday headers and the calendar's first day of the week; without it
        // a Hebrew app on an English phone renders an English calendar.
        let locale = Locale(identifier: spec.localeIdentifier)
        picker.locale = locale
        picker.calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = locale
            return calendar
        }()


        switch spec.mode {
        case "date":
            picker.datePickerMode = .date
            // Apple's own date entry is the inline calendar, not a wheel.
            picker.preferredDatePickerStyle = .inline
        case "time":
            picker.datePickerMode = .time
            picker.preferredDatePickerStyle = .wheels
        default:
            picker.datePickerMode = .dateAndTime
            picker.preferredDatePickerStyle = .wheels
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
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isRTL { view.semanticContentAttribute = .forceRightToLeft }

        let cancel = UIButton(type: .system)
        cancel.setTitle(cancelLabel, for: .normal)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let done = UIButton(type: .system)
        done.setTitle(doneLabel, for: .normal)
        done.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        done.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let bar = UIStackView(arrangedSubviews: [cancel, UIView(), done])
        bar.axis = .horizontal
        bar.alignment = .center

        let stack = UIStackView(arrangedSubviews: [bar, picker])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            // Equality, not `lessThanOrEqualTo`: the custom detent below sizes
            // the sheet from `systemLayoutSizeFitting`, and an inequality
            // leaves the height underdetermined -- the sheet then resolves far
            // taller than its content, with dead space under the wheels.
            stack.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -12),
        ])
    }

    /// Configures the sheet to hug its content rather than take a fixed
    /// fraction of the screen — the inline calendar and the time wheels are
    /// very different heights.
    func configureSheet() {
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [
                    .custom { [weak self] _ in
                        guard let self else { return 320 }
                        return self.view.systemLayoutSizeFitting(
                            UIView.layoutFittingCompressedSize
                        ).height + 24
                    }
                ]
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
    }

    @objc private func cancelTapped() { complete(with: nil) }
    @objc private func doneTapped() { complete(with: picker.date) }

    private func complete(with date: Date?) {
        guard !didComplete else { return }
        didComplete = true
        let handler = onDone
        dismiss(animated: true) { handler(date) }
    }

    /// Swiping the sheet down is a cancel, and it does not route through the
    /// buttons — without this the Dart future never resolves and the caller
    /// hangs forever.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard !didComplete else { return }
        didComplete = true
        onDone(nil)
    }
}
