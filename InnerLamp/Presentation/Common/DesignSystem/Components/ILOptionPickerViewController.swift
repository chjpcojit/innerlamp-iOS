//
//  ILOptionPickerViewController.swift
//  InnerLamp
//

import UIKit

/// Bộ chọn một giá trị từ danh sách chuỗi dạng bottom sheet (tiêu đề + phụ đề, ô tìm kiếm, danh
/// sách có dấu tick, skeleton khi đang tải) — khớp sheet của `IL-AddressPicker` trong design
/// handoff. Không biết dữ liệu đến từ đâu: nơi gọi đẩy `options`/`isLoading` qua `update(...)`
/// (có thể gọi lại khi danh sách tải xong lúc sheet đang mở). Trình bày bằng `present(_:)` như
/// `ILCountryPickerViewController`.
final class ILOptionPickerViewController: BaseViewController {

    var onSelect: ((String) -> Void)?
    /// Gọi khi sheet đã đóng (chọn, nút đóng hoặc vuốt xuống) — để nơi gọi bỏ tham chiếu.
    var onDismiss: (() -> Void)?

    private let searchPlaceholder: String
    private var options: [String] = []
    private var selected = ""
    private var isLoading = false
    private var filtered: [String] = []

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let headerView: ILNavBar
    private let searchContainer = UIView()
    private let searchField = UITextField()
    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private let skeletonStack = UIStackView()

    init(title: String, subtitle: String, searchPlaceholder: String) {
        self.searchPlaceholder = searchPlaceholder
        self.headerView = ILNavBar(title: title, subtitle: subtitle, showBack: false, showClose: true)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = ILMetrics.radiusCardLarge
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed { onDismiss?() }
    }

    // MARK: - Public
    func update(options: [String], selected: String, isLoading: Bool) {
        self.options = options
        self.selected = selected
        self.isLoading = isLoading
        guard isViewLoaded else { return }
        applyFilter()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        // Nền mờ: blur làm lớp dưới cùng, phủ nhẹ màu canvas để giữ tông ấm của app.
        view.backgroundColor = .clear
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.backgroundColor = ILColors.canvasWarm.withAlphaComponent(0.55)
        view.addSubview(blurView)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.onClose = { [weak self] in self?.dismiss(animated: true) }
        view.addSubview(headerView)

        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.backgroundColor = ILColors.surface
        searchContainer.layer.cornerRadius = ILMetrics.radiusInput
        searchContainer.layer.borderWidth = 1
        searchContainer.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
        view.addSubview(searchContainer)

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.font = ILTypography.bodyLarge
        searchField.textColor = ILColors.ink
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .done
        searchField.attributedPlaceholder = NSAttributedString(
            string: searchPlaceholder,
            attributes: [.foregroundColor: ILColors.ink.withAlphaComponent(0.36)]
        )
        searchField.addTarget(self, action: #selector(handleSearchChanged), for: .editingChanged)
        searchField.addTarget(searchField, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)
        searchContainer.addSubview(searchField)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ILOptionPickerCell.self, forCellReuseIdentifier: ILOptionPickerCell.reuseID)
        view.addSubview(tableView)

        skeletonStack.translatesAutoresizingMaskIntoConstraints = false
        skeletonStack.axis = .vertical
        skeletonStack.spacing = 0
        [0.62, 0.48, 0.70, 0.54, 0.66, 0.44, 0.58].enumerated().forEach { index, ratio in
            skeletonStack.addArrangedSubview(Self.makeSkeletonRow(widthRatio: ratio, delay: Double(index) * 0.08))
        }
        view.addSubview(skeletonStack)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.font = ILTypography.body
        emptyLabel.textColor = ILColors.inkSubtle
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)

        applyFilter()
    }

    override func setupConstraints() {
        super.setupConstraints()
        let side = ILMetrics.screenHorizontal
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Chừa chỗ cho grabber của sheet — 8pt làm header dính sát mép trên.
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceLarge),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),

            searchContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            searchContainer.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),

            searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 14),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -14),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: ILMetrics.spaceSmall),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            skeletonStack.topAnchor.constraint(equalTo: tableView.topAnchor),
            skeletonStack.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            skeletonStack.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),

            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 34),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side)
        ])
    }

    // MARK: - Filtering
    @objc private func handleSearchChanged() {
        applyFilter()
    }

    private func applyFilter() {
        let query = Self.normalize(searchField.text ?? "")
        filtered = query.isEmpty ? options : options.filter { Self.normalize($0).contains(query) }

        skeletonStack.isHidden = !isLoading
        tableView.isHidden = isLoading
        let isEmpty = !isLoading && filtered.isEmpty
        emptyLabel.isHidden = !isEmpty
        if isEmpty {
            let typed = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            emptyLabel.text = String(format: "optionPicker.empty".localized, typed)
        }
        tableView.reloadData()
    }

    /// Không phân biệt hoa thường và dấu tiếng Việt (kể cả "đ").
    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func makeSkeletonRow(widthRatio: CGFloat, delay: TimeInterval) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let bar = ILSkeletonBarView(pulseDelay: delay)
        row.addSubview(bar)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 48),
            bar.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            bar.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            bar.heightAnchor.constraint(equalToConstant: 11),
            bar.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: widthRatio)
        ])
        return row
    }
}

// MARK: - UITableViewDataSource / Delegate
extension ILOptionPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ILOptionPickerCell.reuseID,
            for: indexPath
        ) as? ILOptionPickerCell else { return UITableViewCell() }
        let option = filtered[indexPath.row]
        cell.configure(title: option, isSelected: option == selected)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = filtered[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(option)
        }
    }
}

// MARK: - Cell
private final class ILOptionPickerCell: UITableViewCell {
    static let reuseID = "ILOptionPickerCell"

    private let titleLabel = UILabel()
    private let tickView = UIImageView(image: ILIcons.checkmark)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        titleLabel.font = ILTypography.bodyLarge
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 2

        tickView.tintColor = ILColors.goldDeep
        tickView.contentMode = .scaleAspectFit
        tickView.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, tickView])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        contentView.layer.cornerRadius = ILMetrics.radiusCardSmall
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tickView.widthAnchor.constraint(equalToConstant: 16),
            tickView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        tickView.isHidden = !isSelected
        contentView.backgroundColor = isSelected ? ILColors.gold.withAlphaComponent(0.10) : .clear
    }
}
