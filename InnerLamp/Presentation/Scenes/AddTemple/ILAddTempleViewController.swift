//
//  ILAddTempleViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILAddTempleViewController: BaseViewController, TransitionProviding {

    var pushTransition: NavigationTransitionAnimating? {
        CrossFadeTransition()
    }

    // MARK: - Properties
    private let viewModel: ILAddTempleViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let nameChangedSubject = PassthroughSubject<String, Never>()
    private let provincePickerOpenedSubject = PassthroughSubject<Void, Never>()
    private let provinceSelectedSubject = PassthroughSubject<String, Never>()
    private let wardPickerOpenedSubject = PassthroughSubject<Void, Never>()
    private let wardSelectedSubject = PassthroughSubject<String, Never>()
    private let addressChangedSubject = PassthroughSubject<String, Never>()
    private let submitTappedSubject = PassthroughSubject<Void, Never>()
    private let cancelTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView: ILNavBar = {
        let view = ILNavBar(title: "addTemple.header.title".localized)
        view.subtitle = "addTemple.header.subtitle".localized
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.keyboardDismissMode = .interactive
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var introLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = ILTypography.makeAttributedString(
            text: "addTemple.intro".localized,
            font: ILTypography.scriptureDescription,
            color: ILColors.inkSecondary,
            lineHeightMultiple: 1.6
        )
        return label
    }()

    private lazy var nameField: ILField = {
        let field = ILField(
            label: "addTemple.field.name.label".localized,
            placeholder: "addTemple.field.name.placeholder".localized
        )
        field.innerTextField.returnKeyType = .next
        field.innerTextField.autocapitalizationType = .words
        return field
    }()

    private lazy var provinceField: ILSelectFieldView = {
        ILSelectFieldView(
            label: "addTemple.field.province.label".localized,
            placeholder: "addTemple.field.province.placeholder".localized
        )
    }()

    private lazy var wardField: ILSelectFieldView = {
        ILSelectFieldView(
            label: "addTemple.field.ward.label".localized,
            placeholder: "addTemple.field.ward.placeholder".localized
        )
    }()

    private lazy var addressField: ILField = {
        let field = ILField(
            label: "addTemple.field.address.label".localized,
            placeholder: "addTemple.field.address.placeholder".localized
        )
        field.innerTextField.returnKeyType = .done
        return field
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyCompact
        label.textColor = ILColors.danger
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private var activePicker: (kind: PickerKind, controller: ILOptionPickerViewController)?
    private var latestModel: ILAddTempleStateModel?

    private enum PickerKind {
        case province
        case ward
    }

    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var footerDivider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.ink.withAlphaComponent(0.08)
        return view
    }()

    private lazy var submitButton: ILButton = {
        let button = ILButton(title: "addTemple.cta.submit".localized, variant: .primary)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var cancelButton: ILButton = {
        let button = ILButton(title: "addTemple.cta.cancel".localized, variant: .ghost)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initializer
    init(viewModel: ILAddTempleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.cancelTappedSubject.send(()) }
        view.addSubview(headerView)

        view.addSubview(scrollView)

        scrollView.addSubview(contentStack)

        nameField.onTextChanged = { [weak self] in self?.nameChangedSubject.send($0) }
        nameField.onReturn = { [weak self] in self?.nameField.innerTextField.resignFirstResponder() }

        provinceField.onTap = { [weak self] in self?.presentPicker(.province) }
        wardField.onTap = { [weak self] in self?.presentPicker(.ward) }

        addressField.onTextChanged = { [weak self] in self?.addressChangedSubject.send($0) }
        addressField.onReturn = { [weak self] in self?.handleSubmitTapped() }

        contentStack.addArrangedSubview(introLabel)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: introLabel)
        [nameField, provinceField, wardField, addressField, errorLabel].forEach(contentStack.addArrangedSubview)

        submitButton.onTap = { [weak self] in self?.handleSubmitTapped() }
        cancelButton.onTap = { [weak self] in self?.cancelTappedSubject.send(()) }
        [footerDivider, submitButton, cancelButton].forEach(footerContainer.addSubview)
        view.addSubview(footerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        let side = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: side),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -side),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceLarge),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -side * 2),

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            footerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            footerDivider.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerDivider.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            footerDivider.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            footerDivider.heightAnchor.constraint(equalToConstant: 1),

            submitButton.topAnchor.constraint(equalTo: footerDivider.bottomAnchor, constant: ILMetrics.spaceMedium),
            submitButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            cancelButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: ILMetrics.rowSpacing),
            cancelButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),
            cancelButton.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILAddTempleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            nameChanged: nameChangedSubject.eraseToAnyPublisher(),
            provincePickerOpened: provincePickerOpenedSubject.eraseToAnyPublisher(),
            provinceSelected: provinceSelectedSubject.eraseToAnyPublisher(),
            wardPickerOpened: wardPickerOpenedSubject.eraseToAnyPublisher(),
            wardSelected: wardSelectedSubject.eraseToAnyPublisher(),
            addressChanged: addressChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            cancelTapped: cancelTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILAddTempleStateModel>) {
        guard case .success(let model) = state else { return }

        // Chỉ gán khi khác — gán `.text` luôn đẩy con trỏ về cuối chuỗi đang gõ.
        if nameField.text != model.name { nameField.text = model.name }
        provinceField.value = model.province
        wardField.value = model.ward
        if addressField.text != model.address { addressField.text = model.address }

        nameField.fieldState = model.errorField == .name ? .error(nil) : .normal
        provinceField.fieldState = model.errorField == .province ? .error : .normal
        // Phường/xã chỉ chọn được sau khi đã có tỉnh — như prototype.
        wardField.placeholder = model.province.isEmpty
            ? "addTemple.field.ward.placeholderNoProvince".localized
            : "addTemple.field.ward.placeholder".localized
        wardField.fieldState = model.province.isEmpty ? .disabled : (model.errorField == .ward ? .error : .normal)

        latestModel = model
        refreshActivePicker()

        errorLabel.text = model.errorMessage
        errorLabel.isHidden = model.errorMessage == nil
    }

    // MARK: - Pickers
    private func presentPicker(_ kind: PickerKind) {
        guard let model = latestModel, activePicker == nil else { return }
        view.endEditing(true)

        let picker: ILOptionPickerViewController
        switch kind {
        case .province:
            picker = ILOptionPickerViewController(
                title: "addTemple.picker.province.title".localized,
                subtitle: "addTemple.picker.province.subtitle".localized,
                searchPlaceholder: "addTemple.picker.province.search".localized
            )
            picker.onSelect = { [weak self] in self?.provinceSelectedSubject.send($0) }
        case .ward:
            guard !model.province.isEmpty else { return }
            picker = ILOptionPickerViewController(
                title: "addTemple.picker.ward.title".localized,
                subtitle: model.province,
                searchPlaceholder: "addTemple.picker.ward.search".localized
            )
            picker.onSelect = { [weak self] in self?.wardSelectedSubject.send($0) }
        }

        activePicker = (kind, picker)
        picker.onDismiss = { [weak self] in self?.activePicker = nil }
        refreshActivePicker()
        present(picker, animated: true)

        switch kind {
        case .province: provincePickerOpenedSubject.send(())
        case .ward: wardPickerOpenedSubject.send(())
        }
    }

    /// Danh mục có thể tải xong khi sheet đang mở — đẩy lại options/loading vào sheet.
    private func refreshActivePicker() {
        guard let model = latestModel, let activePicker else { return }
        switch activePicker.kind {
        case .province:
            activePicker.controller.update(
                options: model.provinceOptions, selected: model.province, isLoading: model.isLoadingProvinces
            )
        case .ward:
            activePicker.controller.update(
                options: model.wardOptions, selected: model.ward, isLoading: model.isLoadingWards
            )
        }
    }

    // MARK: - Actions
    private func handleSubmitTapped() {
        view.endEditing(true)
        submitTappedSubject.send(())
    }
}
