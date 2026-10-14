//
//  ILDonateQRView.swift
//  InnerLamp
//

import UIKit
import CoreImage.CIFilterBuiltins

/// White rounded card with the transfer QR code. The image is rendered off the main thread and
/// assigned once finished.
final class ILDonateQRView: UIView {

    private enum Layout {
        static let codeSize: CGFloat = 196
        static let padding: CGFloat = 12
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var renderedPayload: String?
    private var renderTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ILColors.qrBackground
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.cornerCurve = .continuous
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            imageView.widthAnchor.constraint(equalToConstant: Layout.codeSize),
            imageView.heightAnchor.constraint(equalToConstant: Layout.codeSize)
        ])
        isAccessibilityElement = true
        accessibilityLabel = "donate.transfer.title".localized
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(payload: String) {
        guard payload != renderedPayload else { return }
        renderedPayload = payload
        renderTask?.cancel()
        renderTask = Task { [weak self] in
            let cgImage = await Task.detached(priority: .userInitiated) {
                Self.renderQR(payload: payload)
            }.value
            guard let self, !Task.isCancelled, self.renderedPayload == payload else { return }
            self.imageView.image = cgImage.map { UIImage(cgImage: $0) }
        }
    }

    private nonisolated static func renderQR(payload: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}
