//
//  DocumentUploadInfoViewController.swift
//  Pods
//
//  Created by Bedri Doğan on 10.09.2026.
//


import UIKit
import AmaniSDK

final class DocumentUploadInfoViewController: BaseViewController {
  
    // MARK: - Data
  
  private var documentVersion: DocumentVersion?
  private var uploadAction: (() -> Void)?
  
    // MARK: - UI
  
  private let scrollView = UIScrollView()
  private let contentView = UIView()
  
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
  
  private let uploadButton = UIButton(type: .custom)
  private let amaniLogo = UIImageView()
  
    // MARK: - Bind
  
  func bind(
    documentVersion: DocumentVersion,
    onUploadTapped: @escaping () -> Void
  ) {
    self.documentVersion = documentVersion
    self.uploadAction = onUploadTapped
  }
  
    // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
}

private extension DocumentUploadInfoViewController {
  
  func setupUI() {
    
    guard let documentVersion else {
      assertionFailure("DocumentVersion must be bound before viewDidLoad")
      return
    }
    
    let appConfig = try? Amani.sharedInstance
      .appConfig()
      .getApplicationConfig()
    
    let gc = appConfig?.generalconfigs
    
    let backgroundColor = hextoUIColor(
      hexString: gc?.appBackground ?? "FFFFFF"
    )
    
    let fontColor = hextoUIColor(
      hexString: gc?.appFontColor ?? "1A1A1A"
    )
    
    let topBarFontColor = hextoUIColor(
      hexString: gc?.topBarFontColor ?? "1A1A1A"
    )
    
    let buttonBackgroundColor = hextoUIColor(
      hexString: gc?.primaryButtonBackgroundColor ?? "C0395A"
    )
    
    let buttonTextColor = hextoUIColor(
      hexString: gc?.primaryButtonTextColor ?? "FFFFFF"
    )
    
    view.backgroundColor = backgroundColor
    
    setupNavigation(
      title: documentVersion.steps?.first?.captureTitle ?? "",
      color: topBarFontColor
    )
    
    setupContent(
      documentVersion: documentVersion,
      fontColor: fontColor
    )
    
    setupButton(
      title: documentVersion.captureDocumentText
      ?? gc?.continueText
      ?? "Continue",
      backgroundColor: buttonBackgroundColor,
      textColor: buttonTextColor,
      cornerRadius: CGFloat(gc?.buttonRadius ?? 10)
    )
    
    setupLogo()
    setupLayout()
  }
}


private extension DocumentUploadInfoViewController {
  
  func setupLogo() {
    
    amaniLogo.translatesAutoresizingMaskIntoConstraints = false
    
    amaniLogo.image = UIImage(
      named: "ic_poweredBy",
      in: AmaniUI.sharedInstance.getBundle(),
      with: nil
    )?.withRenderingMode(.alwaysTemplate)
    
    amaniLogo.tintColor = hextoUIColor(
      hexString: "#909090"
    )
    
    amaniLogo.contentMode = .scaleAspectFit
  }
}

private extension DocumentUploadInfoViewController {
  
    
    func setupNavigation(
      title: String,
      color: UIColor
    ) {
      
      setNavigationBarWith(
        title: title,
        textColor: color
      )
      
      setNavigationLeftButton(
        TintColor: color.toHexString()
      )
    }
}


private extension DocumentUploadInfoViewController {
  
  func setupButton(
    title: String,
    backgroundColor: UIColor,
    textColor: UIColor,
    cornerRadius: CGFloat
  ) {
    
    uploadButton.translatesAutoresizingMaskIntoConstraints = false
    
    uploadButton.setTitle(title, for: .normal)
    
    uploadButton.setTitleColor(
      textColor,
      for: .normal
    )
    
    uploadButton.backgroundColor = backgroundColor
    
    uploadButton.titleLabel?.font = UIFont.systemFont(
      ofSize: 18,
      weight: .semibold
    )
    
    uploadButton.layer.cornerRadius = cornerRadius
    uploadButton.layer.cornerCurve = .continuous
    
    uploadButton.addTarget(
      self,
      action: #selector(uploadButtonTapped),
      for: .touchUpInside
    )
  }
  
  @objc
  func uploadButtonTapped() {
    uploadAction?()
  }
}

private extension DocumentUploadInfoViewController {
  
  func setupLayout() {
    
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    
    contentView.addSubview(titleLabel)
    contentView.addSubview(descriptionLabel)
    
    view.addSubview(uploadButton)
    view.addSubview(amaniLogo)
    
    NSLayoutConstraint.activate([
      
      // MARK: - Powered by AMANI
      
      amaniLogo.centerXAnchor.constraint(
        equalTo: view.centerXAnchor
      ),
      
      amaniLogo.widthAnchor.constraint(
        equalToConstant: 114
      ),
      
      amaniLogo.heightAnchor.constraint(
        equalToConstant: 13
      ),
      
      amaniLogo.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor,
        constant: -12
      ),
      
      // MARK: - Upload Button
      
      uploadButton.leadingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.leadingAnchor,
        constant: 20
      ),
      
      uploadButton.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -20
      ),
      
      uploadButton.heightAnchor.constraint(
        equalToConstant:
          AmaniUI.sharedInstance.style.ctaButtonHeight
      ),
      
      uploadButton.bottomAnchor.constraint(
        equalTo: amaniLogo.topAnchor,
        constant: -24
      ),
      
      // MARK: - Scroll View
      
      scrollView.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor
      ),
      
      scrollView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor
      ),
      
      scrollView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor
      ),
      
      scrollView.bottomAnchor.constraint(
        equalTo: uploadButton.topAnchor,
        constant: -20
      ),
      
      // MARK: - Content View
      
      contentView.topAnchor.constraint(
        equalTo: scrollView.contentLayoutGuide.topAnchor
      ),
      
      contentView.leadingAnchor.constraint(
        equalTo: scrollView.contentLayoutGuide.leadingAnchor
      ),
      
      contentView.trailingAnchor.constraint(
        equalTo: scrollView.contentLayoutGuide.trailingAnchor
      ),
      
      contentView.bottomAnchor.constraint(
        equalTo: scrollView.contentLayoutGuide.bottomAnchor
      ),
      
      contentView.widthAnchor.constraint(
        equalTo: scrollView.frameLayoutGuide.widthAnchor
      ),
      
      // MARK: - Main title
      
      titleLabel.topAnchor.constraint(
        equalTo: contentView.topAnchor,
        constant: 32
      ),
      
      titleLabel.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 16
      ),
      
      titleLabel.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor,
        constant: -16
      ),
      
      // MARK: - Description
      
      descriptionLabel.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: 46
      ),
      
      descriptionLabel.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 60
      ),
      
      descriptionLabel.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor,
        constant: -60
      ),
      
      descriptionLabel.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: -24
      )
    ])
  }
}


private extension DocumentUploadInfoViewController {
  
  func setupContent(
    documentVersion: DocumentVersion,
    fontColor: UIColor
  ) {
    
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.alwaysBounceVertical = false
    
    contentView.translatesAutoresizingMaskIntoConstraints = false
    
      // MARK: - Main title
    
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setText(
      documentVersion.basicInfoText,
      lineSpacing: 2
    )
    titleLabel.textColor = fontColor
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    
    titleLabel.font = UIFont.systemFont(
      ofSize: 20,
      weight: .bold
    )
    
    titleLabel.setContentCompressionResistancePriority(
      .required,
      for: .vertical
    )
    
      // MARK: - Description
    
    let descriptionText = documentVersion
      .steps?
      .first?
      .captureDescription?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    ?? ""
    
    descriptionLabel.setText(
      descriptionText,
      lineSpacing: 3
    )
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.textColor = fontColor
    descriptionLabel.textAlignment = .left
    descriptionLabel.numberOfLines = 0
    
    descriptionLabel.font = UIFont.systemFont(
      ofSize: 16,
      weight: .regular
    )
    
    descriptionLabel.isHidden = descriptionText.isEmpty
    
    descriptionLabel.setContentCompressionResistancePriority(
      .required,
      for: .vertical
    )
  }
}
