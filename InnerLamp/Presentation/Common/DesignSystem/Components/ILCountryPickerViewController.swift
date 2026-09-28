//
//  ILCountryPickerViewController.swift
//  InnerLamp
//

import UIKit

/// Bộ chọn quốc gia dạng bottom sheet (cờ + tên + mã vùng + ô tìm kiếm) — khớp sheet `ccOpen`
/// trong design handoff. Thuần lựa chọn dữ liệu tĩnh (`ILCountry.all`), không có UseCase/luồng
/// điều hướng riêng nên trình bày qua `present(_:)` trực tiếp từ nơi gọi thay vì đi qua
/// Coordinator — không phải một "màn hình" theo nghĩa `il-screen-builder` (không push lên
/// navigation stack, không có state cần lưu qua session).
final class ILCountryPickerViewController: BaseViewController {

    var onSelect: ((ILCountry) -> Void)?

    private let selectedCountry: ILCountry
    private var filtered: [ILCountry] = ILCountry.all

    private let headerView = ILNavBar(title: "countryPicker.title".localized, showBack: false, showClose: true)
    private let searchContainer = UIView()
    private let searchField = UITextField()
    private let tableView = UITableView()
    private let emptyLabel = UILabel()

    init(selectedCountry: ILCountry) {
        self.selectedCountry = selectedCountry
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

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvasWarm

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
        searchField.attributedPlaceholder = NSAttributedString(
            string: "countryPicker.search.placeholder".localized,
            attributes: [.foregroundColor: ILColors.ink.withAlphaComponent(0.36)]
        )
        searchField.addTarget(self, action: #selector(handleSearchChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ILCountryPickerCell.self, forCellReuseIdentifier: ILCountryPickerCell.reuseID)
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.font = ILTypography.body
        emptyLabel.textColor = ILColors.inkSubtle
        emptyLabel.textAlignment = .center
        emptyLabel.text = "countryPicker.empty".localized
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            searchContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            searchContainer.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),

            searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 14),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -14),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: ILMetrics.spaceSmall),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 34),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal)
        ])
    }

    @objc private func handleSearchChanged() {
        let query = searchField.text ?? ""
        filtered = ILCountry.all.filter { $0.matches(query: query) }
        emptyLabel.isHidden = !filtered.isEmpty
        tableView.reloadData()
    }
}

extension ILCountryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ILCountryPickerCell.reuseID, for: indexPath) as! ILCountryPickerCell
        let country = filtered[indexPath.row]
        cell.configure(country: country, isSelected: country == selectedCountry)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = filtered[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(country)
        }
    }
}

private final class ILCountryPickerCell: UITableViewCell {
    static let reuseID = "ILCountryPickerCell"

    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let dialLabel = UILabel()
    private let tickView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        flagLabel.font = .systemFont(ofSize: 22)
        nameLabel.font = ILTypography.bodyLarge
        nameLabel.textColor = ILColors.ink
        dialLabel.font = ILTypography.body
        dialLabel.textColor = ILColors.inkSubtle

        tickView.backgroundColor = .clear
        let tickLayer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 3))
        path.addLine(to: CGPoint(x: 3, y: 6))
        path.addLine(to: CGPoint(x: 8, y: 0))
        tickLayer.path = path.cgPath
        tickLayer.strokeColor = ILColors.goldDeep.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
        tickLayer.lineWidth = 1.8
        tickLayer.lineCap = .round
        tickLayer.lineJoin = .round
        tickLayer.frame = CGRect(x: 4, y: 5, width: 8, height: 6)
        tickView.layer.addSublayer(tickLayer)

        let stack = UIStackView(arrangedSubviews: [flagLabel, nameLabel, dialLabel, tickView])
        stack.axis = .horizontal
        stack.spacing = 13
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        contentView.addSubview(stack)
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

    func configure(country: ILCountry, isSelected: Bool) {
        flagLabel.text = country.flag
        nameLabel.text = country.name
        dialLabel.text = country.dialCode
        tickView.alpha = isSelected ? 1 : 0
        contentView.backgroundColor = isSelected ? ILColors.gold.withAlphaComponent(0.10) : .clear
        contentView.layer.cornerRadius = ILMetrics.radiusCardSmall
    }
}
