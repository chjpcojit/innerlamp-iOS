//
//  ILOrdinationPlaceFieldView.swift
//  InnerLamp
//

import UIKit

/// Dựng các hàng của bộ chọn nơi xuất gia — thuần dữ liệu để test được, không phụ thuộc UI.
enum ILOrdinationPlaceFilter {

    /// Hàng của danh sách. `isNone` là lựa chọn "Chưa xuất gia" (cư sĩ tu tại gia).
    struct Row: Equatable {
        let id: String
        let name: String
        let subtitle: String
        let isNone: Bool
    }

    static let noneRowID = "none"

    /// Không gõ gì: "Chưa xuất gia" + toàn bộ chùa đã tải. Có gõ: đúng những chùa server trả về cho
    /// từ khoá đó (server đã tìm theo tên, không lọc lại ở máy) và không có dòng "Chưa xuất gia".
    static func rows(options: [ILOrdinationPlaceEntity], query: String, noneName: String, noneSubtitle: String) -> [Row] {
        let places = options.map { Row(id: $0.id, name: $0.name, subtitle: $0.subtitle, isNone: false) }
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return places }
        let none = Row(id: noneRowID, name: noneName, subtitle: noneSubtitle, isNone: true)
        return [none] + places
    }
}

/// Ô "Nơi xuất gia" của màn Đăng ký (`toggleOrd`/`ordOpts` trong design handoff): thẻ giá trị bấm để
/// mở khung chọn — ô tìm kiếm, danh sách chùa, dòng trống và "Không thấy chùa của bạn? Thêm thông
/// tin chùa". Khung chọn là lớp phủ nổi đè lên các ô bên dưới (`position:absolute` của design):
/// không tham gia chiều cao của view nên mở/đóng không làm form dịch chuyển hay giật.
///
/// Chỉ giữ trạng thái giao diện (đang mở, từ khoá, dòng đang chọn); dữ liệu chùa do ViewModel tải
/// rồi gán vào `options`.
final class ILOrdinationPlaceFieldView: UIView {

    // MARK: - Spec
    private enum Metrics {
        static let searchRowHeight: CGFloat = 46
        static let rowHeight: CGFloat = 58
        static let maxListHeight: CGFloat = 264
        static let panelSpacing: CGFloat = 6
        /// Dòng "Thêm thông tin chùa" + hai đường kẻ — phần cố định của khung ngoài danh sách.
        static let addRowChromeHeight: CGFloat = 68
        static let minVisibleRows: CGFloat = 2
    }

    // MARK: - Properties
    /// Gọi khi khung chọn vừa mở — ViewController dùng để yêu cầu tải danh sách chùa.
    var onOpened: (() -> Void)?
    /// Chùa được chọn: id server và tên; `(nil, "")` khi chọn "Chưa xuất gia".
    var onSelect: ((String?, String) -> Void)?
    /// Từ khoá tìm kiếm đổi (mỗi lần gõ, và `""` khi khung đóng lại) — ViewModel tìm bằng server.
    var onSearchChanged: ((String) -> Void)?
    /// Danh sách đã cuộn gần cuối và server còn trang kế tiếp.
    var onLoadMore: (() -> Void)?
    /// Bấm "Thêm thông tin chùa" — kèm từ khoá đang gõ để điền sẵn tên.
    var onAddTapped: ((String) -> Void)?

    /// Chùa đã tải, đúng thứ tự server. Khi chỉ có thêm chùa ở cuối (tải trang kế tiếp) thì chỉ chèn
    /// hàng mới — không dựng lại cả danh sách.
    var options: [ILOrdinationPlaceEntity] = [] {
        didSet {
            guard options != oldValue else { return }
            if !appendRows(after: oldValue) {
                reloadRows()
                tableView.setContentOffset(.zero, animated: false)
            }
        }
    }

    var isLoading: Bool = false {
        didSet { if isLoading != oldValue { reloadRows() } }
    }

    /// Đang tải trang kế tiếp — hiện vòng xoay ở cuối danh sách.
    var isLoadingMore: Bool = false {
        didSet { if isLoadingMore != oldValue { updateFooter() } }
    }

    /// Server còn trang kế tiếp cho từ khoá hiện tại.
    var hasMore: Bool = false

    private(set) var isExpanded = false
    private var query = ""
    private var selectedID: String?
    private var selectedName: String?
    private var rows: [ILOrdinationPlaceFilter.Row] = []

    // MARK: - UI Elements
    private lazy var headerCard: UIControl = {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = ILColors.surface
        control.layer.cornerRadius = ILMetrics.radiusInput
        control.layer.borderWidth = 1
        return control
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkMuted
        label.text = "signup.ordination.label".localized
        return label
    }()

    private lazy var optionalLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.microCaption
        label.textColor = ILColors.inkFaint
        label.text = "signup.ordination.optional".localized
        label.textAlignment = .right
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.fieldValue
        label.numberOfLines = 1
        return label
    }()

    private lazy var chevronView: UIImageView = {
        let view = UIImageView(image: ILIcons.chevronDown)
        view.tintColor = ILColors.inkMuted
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private lazy var panel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.surface
        view.layer.cornerRadius = ILMetrics.radiusInput
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    /// Kính lúp: vòng tròn viền, cùng cách vẽ với `ILSearchInputView`.
    private lazy var searchIcon: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 7
        view.layer.borderWidth = 1.5
        view.layer.borderColor = ILColors.inkMuted.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var searchField: UITextField = {
        let field = UITextField()
        field.font = ILTypography.bodyLarge
        field.textColor = ILColors.ink
        field.tintColor = ILColors.gold
        field.autocorrectionType = .no
        field.returnKeyType = .search
        field.attributedPlaceholder = NSAttributedString(
            string: "signup.ordination.search".localized,
            attributes: [.foregroundColor: ILColors.inkFaint]
        )
        return field
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("signup.ordination.clear".localized, for: .normal)
        button.setTitleColor(ILColors.link, for: .normal)
        button.titleLabel?.font = ILTypography.chip
        button.isHidden = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    private lazy var searchDivider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.ink.withAlphaComponent(0.07)
        return view
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.rowHeight = Metrics.rowHeight
        table.keyboardDismissMode = .onDrag
        return table
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyCompact
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emptyContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var footerSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = ILColors.inkMuted
        return spinner
    }()

    private lazy var addDivider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.ink.withAlphaComponent(0.07)
        return view
    }()

    private lazy var addRow: UIControl = {
        UIControl()
    }()
    private var tableHeightConstraint: NSLayoutConstraint!

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        reloadRows()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public
    /// Chọn một dòng theo id từ bên ngoài (chùa vừa được đề xuất) — không báo ngược `onSelect`.
    func select(id: String) {
        guard id != selectedID, let place = options.first(where: { $0.id == id }) else { return }
        selectedID = id
        selectedName = place.name
        updateValueLabel()
        setExpanded(false, notify: false)
        tableView.reloadData()
    }

    func collapse() {
        setExpanded(false, notify: false)
    }

    // Khung chọn nằm ngoài bounds nên phải nhận chạm ở đó.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        guard !panel.isHidden else { return false }
        return panel.frame.contains(point)
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        setupHeaderCard()
        setupPanel()

        [headerCard, panel].forEach {
            addSubview($0)
        }
        // `panel` neo dưới `headerCard` nhưng không ràng buộc `bottomAnchor` của view: chiều cao
        // của view luôn chỉ bằng thẻ giá trị.
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: topAnchor),
            headerCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerCard.bottomAnchor.constraint(equalTo: bottomAnchor),
            panel.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: Metrics.panelSpacing),
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        applyBorderColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILOrdinationPlaceFieldView, _) in
            view.applyBorderColors()
        }
    }

    private func setupHeaderCard() {
        headerCard.addTarget(self, action: #selector(handleHeaderTapped), for: .touchUpInside)

        let captionRow = UIStackView(arrangedSubviews: [captionLabel, optionalLabel])
        captionRow.axis = .horizontal
        captionRow.spacing = ILMetrics.spaceSmall
        let textStack = UIStackView(arrangedSubviews: [captionRow, valueLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        let row = UIStackView(arrangedSubviews: [textStack, chevronView])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: ILMetrics.spaceStandard),
            row.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -ILMetrics.spaceStandard),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 12)
        ])
        updateValueLabel()
    }

    private func setupPanel() {
        searchField.addTarget(self, action: #selector(handleSearchChanged), for: .editingChanged)

        clearButton.addTarget(self, action: #selector(handleClearTapped), for: .touchUpInside)

        let searchRow = UIStackView(arrangedSubviews: [searchIcon, searchField, clearButton])
        searchRow.axis = .horizontal
        searchRow.alignment = .center
        searchRow.spacing = 10
        searchRow.isLayoutMarginsRelativeArrangement = true
        searchRow.layoutMargins = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PlaceCell.self, forCellReuseIdentifier: PlaceCell.reuseID)
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)

        emptyContainer.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.topAnchor.constraint(equalTo: emptyContainer.topAnchor, constant: 14),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyContainer.bottomAnchor, constant: -14),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor, constant: ILMetrics.spaceStandard),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyContainer.trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        let addTitle = UILabel()
        addTitle.font = ILTypography.sectionTitle
        addTitle.textColor = ILColors.link
        addTitle.text = "signup.ordination.addTitle".localized
        let addSubtitle = UILabel()
        addSubtitle.font = ILTypography.label
        addSubtitle.textColor = ILColors.inkTertiary
        addSubtitle.text = "signup.ordination.addSubtitle".localized
        let addText = UIStackView(arrangedSubviews: [addTitle, addSubtitle])
        addText.axis = .vertical
        addText.spacing = 2
        let plus = UILabel()
        plus.font = ILTypography.title1
        plus.textColor = ILColors.link
        plus.text = "+"
        plus.setContentHuggingPriority(.required, for: .horizontal)
        let addStack = UIStackView(arrangedSubviews: [addText, plus])
        addStack.axis = .horizontal
        addStack.alignment = .center
        addStack.spacing = 12
        addStack.isUserInteractionEnabled = false
        addStack.translatesAutoresizingMaskIntoConstraints = false
        addRow.addSubview(addStack)
        NSLayoutConstraint.activate([
            addStack.topAnchor.constraint(equalTo: addRow.topAnchor, constant: 13),
            addStack.bottomAnchor.constraint(equalTo: addRow.bottomAnchor, constant: -13),
            addStack.leadingAnchor.constraint(equalTo: addRow.leadingAnchor, constant: ILMetrics.spaceStandard),
            addStack.trailingAnchor.constraint(equalTo: addRow.trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])
        addRow.addTarget(self, action: #selector(handleAddTapped), for: .touchUpInside)

        [searchDivider, addDivider].forEach {
            $0.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }

        let panelStack = UIStackView(arrangedSubviews: [searchRow, searchDivider, tableView, emptyContainer, addDivider, addRow])
        panelStack.axis = .vertical
        panelStack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(panelStack)
        NSLayoutConstraint.activate([
            panelStack.topAnchor.constraint(equalTo: panel.topAnchor),
            panelStack.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
            panelStack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            panelStack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            searchRow.heightAnchor.constraint(equalToConstant: Metrics.searchRowHeight),
            searchIcon.widthAnchor.constraint(equalToConstant: 14),
            searchIcon.heightAnchor.constraint(equalToConstant: 14),
            tableHeightConstraint
        ])
    }

    private func applyBorderColors() {
        let isOpen = isExpanded
        headerCard.layer.borderColor = (isOpen ? ILColors.gold.withAlphaComponent(0.55) : ILColors.ink.withAlphaComponent(0.12)).cgColor
        panel.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
        searchIcon.layer.borderColor = ILColors.inkMuted.cgColor
    }

    // MARK: - State
    private func setExpanded(_ expanded: Bool, notify: Bool) {
        guard expanded != isExpanded else { return }
        isExpanded = expanded
        if expanded {
            // Các view anh em phía sau (ô tiếp theo trong stack, hàng điều khoản bên ngoài stack) vẽ
            // đè lên khung chọn nếu không đưa view này và mọi view cha lên trên, tới scroll view.
            var view: UIView = self
            while let parent = view.superview, !(parent is UIScrollView) {
                parent.bringSubviewToFront(view)
                view = parent
            }
            view.superview?.bringSubviewToFront(view)
            reloadRows()
            panel.isHidden = false
        } else {
            searchField.resignFirstResponder()
            let hadQuery = !query.isEmpty
            query = ""
            searchField.text = ""
            clearButton.isHidden = true
            reloadRows()
            // Mở lại bộ chọn phải thấy toàn bộ danh bạ chứ không phải kết quả của từ khoá cũ.
            if hadQuery { onSearchChanged?("") }
        }
        // Chỉ đổi alpha/xoay mũi tên — không đụng layout nên form phía dưới không nhúc nhích.
        UIView.animate(withDuration: 0.2, animations: {
            self.panel.alpha = expanded ? 1 : 0
            self.chevronView.transform = expanded ? CGAffineTransform(rotationAngle: .pi) : .identity
            self.applyBorderColors()
        }, completion: { _ in
            if !self.isExpanded { self.panel.isHidden = true }
        })
        if expanded && notify { onOpened?() }
    }

    private func choose(id: String, name: String) {
        selectedID = id
        selectedName = name
        updateValueLabel()
        setExpanded(false, notify: false)
        let isNone = id == ILOrdinationPlaceFilter.noneRowID
        onSelect?(isNone ? nil : id, isNone ? "" : name)
    }

    private func updateValueLabel() {
        if let name = selectedName {
            valueLabel.text = name
            valueLabel.textColor = ILColors.ink
        } else {
            valueLabel.text = "signup.ordination.placeholder".localized
            valueLabel.textColor = ILColors.inkFaint
        }
    }

    /// Khung nổi không làm tăng `contentSize`, nên danh sách phải vừa với phần form còn lại bên dưới
    /// ô — nếu không phần dưới của khung (kể cả dòng "Thêm thông tin chùa") sẽ bị cắt.
    private var maxListHeight: CGFloat {
        var ancestor = superview
        while let view = ancestor, !(view is UIScrollView) { ancestor = view.superview }
        guard let scrollView = ancestor as? UIScrollView, scrollView.contentSize.height > 0 else {
            return Metrics.maxListHeight
        }
        let bottom = convert(bounds, to: scrollView).maxY
        let room = scrollView.contentSize.height - bottom
            - Metrics.panelSpacing - Metrics.searchRowHeight - Metrics.addRowChromeHeight
        return max(Metrics.rowHeight * Metrics.minVisibleRows, min(Metrics.maxListHeight, room))
    }

    private func makeRows() -> [ILOrdinationPlaceFilter.Row] {
        ILOrdinationPlaceFilter.rows(
            options: options,
            query: query,
            noneName: "signup.ordination.none".localized,
            noneSubtitle: "signup.ordination.noneSubtitle".localized
        )
    }

    private func reloadRows() {
        rows = makeRows()
        tableView.reloadData()
        updateListChrome()
    }

    /// Chèn đúng các hàng mới khi `options` chỉ dài thêm ở cuối; `false` nếu không phải trường hợp
    /// đó (đổi từ khoá, tải lại) để người gọi dựng lại toàn bộ.
    private func appendRows(after previous: [ILOrdinationPlaceEntity]) -> Bool {
        guard !previous.isEmpty, options.count > previous.count,
              Array(options.prefix(previous.count)) == previous else { return false }
        let previousCount = rows.count
        rows = makeRows()
        guard rows.count > previousCount else { return false }
        tableView.insertRows(
            at: (previousCount..<rows.count).map { IndexPath(row: $0, section: 0) },
            with: .none
        )
        updateListChrome()
        return true
    }

    private func updateListChrome() {
        tableHeightConstraint.constant = min(CGFloat(rows.count) * Metrics.rowHeight, maxListHeight)

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        emptyContainer.isHidden = !rows.isEmpty
        emptyLabel.isHidden = !rows.isEmpty
        emptyLabel.text = isLoading
            ? "signup.ordination.loading".localized
            : String(format: "signup.ordination.empty".localized, trimmed)
    }

    private func updateFooter() {
        if isLoadingMore {
            footerSpinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: Metrics.rowHeight)
            footerSpinner.startAnimating()
            tableView.tableFooterView = footerSpinner
        } else {
            footerSpinner.stopAnimating()
            tableView.tableFooterView = nil
        }
    }

    // MARK: - Actions
    @objc private func handleHeaderTapped() {
        setExpanded(!isExpanded, notify: true)
    }

    @objc private func handleSearchChanged() {
        query = searchField.text ?? ""
        clearButton.isHidden = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        reloadRows()
        onSearchChanged?(query)
    }

    @objc private func handleClearTapped() {
        searchField.text = ""
        handleSearchChanged()
    }

    @objc private func handleAddTapped() {
        let name = query.trimmingCharacters(in: .whitespacesAndNewlines)
        setExpanded(false, notify: false)
        onAddTapped?(name)
    }
}

// MARK: - UITableViewDataSource / Delegate
extension ILOrdinationPlaceFieldView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceCell.reuseID, for: indexPath) as? PlaceCell else {
            return UITableViewCell()
        }
        let row = rows[indexPath.row]
        cell.configure(row: row, isFirst: indexPath.row == 0, isSelected: row.id == selectedID)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let row = rows[indexPath.row]
        choose(id: row.id, name: row.name)
    }

    /// Cuộn gần cuối thì xin trang kế tiếp (server còn trang, không có lượt tải nào đang chạy).
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isExpanded, hasMore, !isLoading, !isLoadingMore else { return }
        let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
        if remaining < Metrics.rowHeight * 5 { onLoadMore?() }
    }
}

// MARK: - Cell
private final class PlaceCell: UITableViewCell {

    static let reuseID = "ILOrdinationPlaceCell"

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyLarge
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkMuted
        return label
    }()

    private lazy var topSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.ink.withAlphaComponent(0.07)
        return view
    }()

    private lazy var radioRing: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1.5
        return view
    }()

    private lazy var radioDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 3.5
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        let text = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        text.axis = .vertical
        text.spacing = 2

        radioRing.addSubview(radioDot)

        text.translatesAutoresizingMaskIntoConstraints = false
        [text, radioRing, topSeparator].forEach {
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 1),

            text.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ILMetrics.spaceStandard),
            text.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            text.trailingAnchor.constraint(lessThanOrEqualTo: radioRing.leadingAnchor, constant: -10),

            radioRing.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ILMetrics.spaceStandard),
            radioRing.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radioRing.widthAnchor.constraint(equalToConstant: 16),
            radioRing.heightAnchor.constraint(equalToConstant: 16),
            radioDot.centerXAnchor.constraint(equalTo: radioRing.centerXAnchor),
            radioDot.centerYAnchor.constraint(equalTo: radioRing.centerYAnchor),
            radioDot.widthAnchor.constraint(equalToConstant: 7),
            radioDot.heightAnchor.constraint(equalToConstant: 7)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(row: ILOrdinationPlaceFilter.Row, isFirst: Bool, isSelected: Bool) {
        nameLabel.text = row.name
        subtitleLabel.text = row.subtitle
        subtitleLabel.isHidden = row.subtitle.isEmpty
        topSeparator.isHidden = isFirst
        contentView.backgroundColor = isSelected ? ILColors.gold.withAlphaComponent(0.08) : .clear
        radioRing.layer.borderColor = (isSelected ? ILColors.gold : ILColors.ink.withAlphaComponent(0.18)).cgColor
        radioDot.backgroundColor = isSelected ? ILColors.gold : .clear
    }
}
