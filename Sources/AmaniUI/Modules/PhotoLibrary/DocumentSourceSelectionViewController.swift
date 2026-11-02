//
//  DocumentSourceSelectionViewController.swift
//  AmaniUI
//

import UIKit
import AmaniSDK

final class DocumentSourceSelectionViewController: UIViewController {

    // MARK: - Source

  enum Source: String {
    case gallery
    case pdf = "pdffile"
    case camera
  }

    // MARK: - Data

  private var documentVersion: DocumentVersion?
  private var onSelect: ((Source) -> Void)?
  private var onCancel: (() -> Void)?

    // MARK: - UI

  private let dimmingView = UIView()
  private let cardView = UIView()
  private let stackView = UIStackView()

  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()

  private let galleryButton = UIButton(type: .custom)
  private let pdfButton = UIButton(type: .custom)
  private let cameraButton = UIButton(type: .custom)

    // MARK: - Bind

  func bind(
    documentVersion: DocumentVersion,
    onSelect: @escaping (Source) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.documentVersion = documentVersion
    self.onSelect = onSelect
    self.onCancel = onCancel
  }

    // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    setupUI()
  }
}

private extension DocumentSourceSelectionViewController {

  func setupUI() {

    guard let documentVersion else {
      assertionFailure("DocumentVersion must be bound before viewDidLoad")
      return
    }

    let appConfig = try? Amani.sharedInstance
      .appConfig()
      .getApplicationConfig()

    let gc = appConfig?.generalconfigs

    let cardBackgroundColor = hextoUIColor(
      hexString: gc?.appBackground ?? "FFFFFF"
    )

    let fontColor = hextoUIColor(
      hexString: gc?.appFontColor ?? "1A1A1A"
    )

    let cornerRadius = CGFloat(gc?.buttonRadius ?? 10)

    setupDimmingView()

    setupCard(
      backgroundColor: cardBackgroundColor,
      cornerRadius: cornerRadius * 1.6
    )

    setupContent(
      documentVersion: documentVersion,
      fontColor: fontColor
    )

    setupButtons(
      documentVersion: documentVersion,
      generalConfig: gc,
      cornerRadius: cornerRadius
    )

    setupLayout()
  }
}

private extension DocumentSourceSelectionViewController {

  func setupDimmingView() {

    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)

    let tapGesture = UITapGestureRecognizer(
      target: self,
      action: #selector(dimmingViewTapped)
    )

    dimmingView.addGestureRecognizer(tapGesture)

    view.addSubview(dimmingView)
  }

  @objc
  func dimmingViewTapped() {
    onCancel?()
  }
}

private extension DocumentSourceSelectionViewController {

  func setupCard(
    backgroundColor: UIColor,
    cornerRadius: CGFloat
  ) {

    cardView.translatesAutoresizingMaskIntoConstraints = false
    cardView.backgroundColor = backgroundColor
    cardView.layer.cornerRadius = cornerRadius
    cardView.layer.cornerCurve = .continuous

    view.addSubview(cardView)
  }
}

private extension DocumentSourceSelectionViewController {

  func setupContent(
    documentVersion: DocumentVersion,
    fontColor: UIColor
  ) {

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = documentVersion.steps?.first?.captureTitle
    titleLabel.textColor = fontColor
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)

    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.text = documentVersion.basicInfoText
    descriptionLabel.textColor = fontColor
    descriptionLabel.textAlignment = .center
    descriptionLabel.numberOfLines = 0
    descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)

    cardView.addSubview(titleLabel)
    cardView.addSubview(descriptionLabel)
  }
}

private extension DocumentSourceSelectionViewController {

  enum ButtonStyle {
    case primary
    case secondary
  }

  func setupButtons(
    documentVersion: DocumentVersion,
    generalConfig gc: GeneralConfig?,
    cornerRadius: CGFloat
  ) {

    style(
      button: galleryButton,
      title: documentVersion.uploadViaGalleryText ?? "Upload via gallery",
      buttonStyle: .secondary,
      generalConfig: gc,
      cornerRadius: cornerRadius
    )

    galleryButton.addTarget(
      self,
      action: #selector(galleryTapped),
      for: .touchUpInside
    )

    style(
      button: pdfButton,
      title: documentVersion.uploadViaPdfText ?? "Upload via PDF",
      buttonStyle: .primary,
      generalConfig: gc,
      cornerRadius: cornerRadius
    )

    pdfButton.addTarget(
      self,
      action: #selector(pdfTapped),
      for: .touchUpInside
    )

    style(
      button: cameraButton,
      title: documentVersion.uploadViaCameraText ?? "Upload via camera",
      buttonStyle: .secondary,
      generalConfig: gc,
      cornerRadius: cornerRadius
    )

    cameraButton.addTarget(
      self,
      action: #selector(cameraTapped),
      for: .touchUpInside
    )

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 12

    stackView.addArrangedSubview(galleryButton)
    stackView.addArrangedSubview(pdfButton)
    stackView.addArrangedSubview(cameraButton)

    cardView.addSubview(stackView)
  }

  func style(
    button: UIButton,
    title: String,
    buttonStyle: ButtonStyle,
    generalConfig gc: GeneralConfig?,
    cornerRadius: CGFloat
  ) {

    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)

    button.titleLabel?.font = UIFont.systemFont(
      ofSize: 16,
      weight: .semibold
    )

    button.layer.cornerRadius = cornerRadius
    button.layer.cornerCurve = .continuous

    button.heightAnchor.constraint(
      equalToConstant:
        AmaniUI.sharedInstance.style.ctaButtonHeight
    ).isActive = true

    switch buttonStyle {

    case .primary:

      button.backgroundColor = hextoUIColor(
        hexString: gc?.primaryButtonBackgroundColor ?? "C0395A"
      )

      button.setTitleColor(
        hextoUIColor(
          hexString: gc?.primaryButtonTextColor ?? "FFFFFF"
        ),
        for: .normal
      )

      button.layer.borderWidth = 0

    case .secondary:

      button.backgroundColor = hextoUIColor(
        hexString: gc?.secondaryButtonBackgroundColor ?? "FFFFFF"
      )

      let accentColor = gc?.secondaryButtonBorderColor
      ?? gc?.primaryButtonBackgroundColor
      ?? "C0395A"

      button.setTitleColor(
        hextoUIColor(
          hexString: gc?.secondaryButtonTextColor ?? accentColor
        ),
        for: .normal
      )

      button.layer.borderWidth = 1
      button.layer.borderColor = hextoUIColor(
        hexString: accentColor
      ).cgColor
    }
  }

  @objc
  func galleryTapped() {
    onSelect?(.gallery)
  }

  @objc
  func pdfTapped() {
    onSelect?(.pdf)
  }

  @objc
  func cameraTapped() {
    onSelect?(.camera)
  }
}

private extension DocumentSourceSelectionViewController {

  func setupLayout() {

    NSLayoutConstraint.activate([

        // MARK: - Dimming view

      dimmingView.topAnchor.constraint(
        equalTo: view.topAnchor
      ),

      dimmingView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor
      ),

      dimmingView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor
      ),

      dimmingView.bottomAnchor.constraint(
        equalTo: view.bottomAnchor
      ),

        // MARK: - Card

      cardView.centerYAnchor.constraint(
        equalTo: view.centerYAnchor
      ),

      cardView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 24
      ),

      cardView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -24
      ),

        // MARK: - Title

      titleLabel.topAnchor.constraint(
        equalTo: cardView.topAnchor,
        constant: 28
      ),

      titleLabel.leadingAnchor.constraint(
        equalTo: cardView.leadingAnchor,
        constant: 20
      ),

      titleLabel.trailingAnchor.constraint(
        equalTo: cardView.trailingAnchor,
        constant: -20
      ),

        // MARK: - Description

      descriptionLabel.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: 12
      ),

      descriptionLabel.leadingAnchor.constraint(
        equalTo: cardView.leadingAnchor,
        constant: 20
      ),

      descriptionLabel.trailingAnchor.constraint(
        equalTo: cardView.trailingAnchor,
        constant: -20
      ),

        // MARK: - Buttons

      stackView.topAnchor.constraint(
        equalTo: descriptionLabel.bottomAnchor,
        constant: 24
      ),

      stackView.leadingAnchor.constraint(
        equalTo: cardView.leadingAnchor,
        constant: 20
      ),

      stackView.trailingAnchor.constraint(
        equalTo: cardView.trailingAnchor,
        constant: -20
      ),

      stackView.bottomAnchor.constraint(
        equalTo: cardView.bottomAnchor,
        constant: -28
      )
    ])
  }
}
