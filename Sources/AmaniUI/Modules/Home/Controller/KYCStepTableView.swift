import UIKit
import AmaniSDK
/**
 This class represents the KYC step list view
 */
@objc(KYCStepTblView)
final class KYCStepTblView: UITableView {
  
  private static let cellIdentifier =
  String(describing: KYCStepTableViewCell.self)
  
  fileprivate var callback: ((KYCStepViewModel) -> Void)?
  fileprivate var kycSteps: [KYCStepViewModel] = []
  
  override init(
    frame: CGRect,
    style: UITableView.Style
  ) {
    super.init(frame: frame, style: style)
    commonInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }
  
  private func commonInit() {
    
    delegate = self
    dataSource = self
    
    backgroundColor = .clear
    
    separatorStyle = .none
    
    isScrollEnabled = true
    alwaysBounceVertical = false
    
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    
    rowHeight = 73
    estimatedRowHeight = 73
    
    register(
      KYCStepTableViewCell.self,
      forCellReuseIdentifier: Self.cellIdentifier
    )
  }
  
  func showKYCStep(
    stepModels: [KYCStepViewModel],
    onSelectCallback: @escaping ((KYCStepViewModel?) -> Void)
  ) {
    
    let update = { [weak self] in
      guard let self else { return }
      
      self.callback = onSelectCallback
      self.kycSteps = stepModels
      self.reloadData()
    }
    
    if Thread.isMainThread {
      update()
    } else {
      DispatchQueue.main.async(execute: update)
    }
  }
  
  func updateStatus(
    for step: KYCStepViewModel,
    status: DocumentStatus
  ) {
    
    DispatchQueue.main.async { [weak self] in
      
      guard let self else { return }
      
      guard let tableIndex = self.kycSteps.firstIndex(
        where: { $0.id == step.id }
      ) else {
        return
      }
      
      step.updateStatus(status: status)
      
      self.reloadRows(
        at: [
          IndexPath(
            row: tableIndex,
            section: 0
          )
        ],
        with: .fade
      )
    }
  }
  
  func updateDataAndReload(
    stepModels: [KYCStepViewModel]
  ) {
    
    DispatchQueue.main.async { [weak self] in
      
      guard let self else { return }
      
      var indexPaths = Set<IndexPath>()
      
      for stepModel in stepModels {
        
        guard let tableIndex = self.kycSteps.firstIndex(
          where: {
            $0.id == stepModel.id
          }
        ) else {
          continue
        }
        
        self.kycSteps[tableIndex] = stepModel
        
        for mandatoryStepId in stepModel.mandatoryStepIDs {
          
          if let mandatoryIndex =
              self.kycSteps.firstIndex(
                where: {
                  $0.id == mandatoryStepId
                }
              ) {
            
            indexPaths.insert(
              IndexPath(
                row: mandatoryIndex,
                section: 0
              )
            )
          }
        }
        
        indexPaths.insert(
          IndexPath(
            row: tableIndex,
            section: 0
          )
        )
      }
      
      guard !indexPaths.isEmpty else {
        return
      }
      
      self.reloadRows(
        at: Array(indexPaths),
        with: .fade
      )
    }
  }
}

  // MARK: - Table view datasource and delegate methods
extension KYCStepTblView:
  UITableViewDelegate,
  UITableViewDataSource {
  
  func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    kycSteps.count
  }
  
  func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: Self.cellIdentifier,
      for: indexPath
    ) as? KYCStepTableViewCell else {
      
      assertionFailure(
        "KYCStepTableViewCell could not be dequeued"
      )
      
      return UITableViewCell()
    }
    
    let step = kycSteps[indexPath.row]
    
    let isEnabled = step.isEnabled()
    
    cell.bind(
      model: step,
      alpha: isEnabled ? 1.0 : 0.8,
      isEnabled: isEnabled
    )
    
    return cell
  }
  
  func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    
    tableView.deselectRow(
      at: indexPath,
      animated: true
    )
    
    let step = kycSteps[indexPath.row]
    
    guard
      step.status != .APPROVED,
      step.status != .PROCESSING,
      step.isEnabled()
    else {
      return
    }
    
    step.onStepPressed { [weak self] result in
      
      switch result {
        
      case .failure(let error):
        print(error)
        
      case .success(let model):
        self?.callback?(model)
      }
    }
  }
}
