import UIKit
import AmaniSDK
/**
 This class represents the KYC step list view
 */
@objc(KYCStepTblView)
class KYCStepTblView: UITableView {

    // MARK: - Local properties

    /// This property represents the rule selection callback
  fileprivate var callback: ((KYCStepViewModel) -> Void)?
  
    /// This property represents the list of KYC rules
  fileprivate var kycSteps: [KYCStepViewModel] = []
  
    // MARK: - Life cycle methods
    //    override func awakeFromNib() {
    //        self.delegate = self
    //        self.dataSource = self
    //        self.backgroundColor = .clear
    //    }
  
  override init(frame: CGRect, style: UITableView.Style) {
    super.init(frame: frame, style: style)
    self.delegate = self
    self.dataSource = self
    self.backgroundColor = .clear
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.delegate = self
    self.dataSource = self
    self.backgroundColor = .clear
  }
  
    // MARK: - Helper methods
  /**
   This method bind the kyc list model with view
   - parameter array: [KYCRuleModel]
   - parameter onSelectCallback: rule selection callback
   */
  func showKYCStep(stepModels: [KYCStepViewModel], onSelectCallback: @escaping ((KYCStepViewModel?) -> Void)) {
    self.kycSteps = stepModels
    
    self.callback = onSelectCallback
    DispatchQueue.main.async {
        //      self.register(UINib(nibName: String(describing: KYCStepTableViewCell.self), bundle: AmaniUI.sharedInstance.getBundle()), forCellReuseIdentifier: String(describing: KYCStepTableViewCell.self))
        //      self.reloadData()
      self.register(KYCStepTableViewCell.self, forCellReuseIdentifier: String(describing: KYCStepTableViewCell.self))
      self.isScrollEnabled = false
      self.showsVerticalScrollIndicator = false
      self.showsHorizontalScrollIndicator = false
      self.separatorStyle = .none
      self.reloadData()
    }
    
  }
  
  func updateStatus(for step: KYCStepViewModel, status: DocumentStatus) {
    DispatchQueue.main.async {
      
      step.updateStatus(status: status)
      self.reloadData()
    }
  }
  
  func updateDataAndReload(stepModels: [KYCStepViewModel]) {

    DispatchQueue.main.async {
      var indexpaths:[IndexPath] = []
      for stepModel in stepModels {
        if let tableIndex:Int = self.kycSteps.firstIndex(where:{ $0.id == stepModel.id}) {
          self.kycSteps[tableIndex] = stepModel
          if !stepModel.mandatoryStepIDs.isEmpty {
            for mandatoryStepId in stepModel.mandatoryStepIDs {
              if let mandatoryIndex = self.kycSteps.firstIndex(where: {$0.id == mandatoryStepId}) {
                indexpaths.append(IndexPath(row: mandatoryIndex, section: 0))
              }
            }
          }
          indexpaths.append(IndexPath(row: tableIndex, section: 0))
        }

      }
      self.reloadRows(at:indexpaths, with: .fade)

//      self.kycSteps = stepModels
//      self.reloadData()
    }
  }
  
}

  // MARK: - Table view datasource and delegate methods
extension KYCStepTblView: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.kycSteps.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "KYCStepTableViewCell", for: indexPath) as? KYCStepTableViewCell else {
      return UITableViewCell()
    }
      //      guard let cell: KYCStepTableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: KYCStepTableViewCell.self), for: indexPath) as? KYCStepTableViewCell else {
      //        return UITableViewCell()
      //      }
    
    let stepViewModel = self.kycSteps[indexPath.row]
    
    if !stepViewModel.isEnabled() {
      cell.bind(model: stepViewModel, alpha: 1, isEnabled: false)
    } else {
      cell.bind(model: stepViewModel, isEnabled: true)
    }
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 73
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return 73
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let step = self.kycSteps[indexPath.row]
    

      if (step.status != DocumentStatus.APPROVED && step.status != DocumentStatus.PROCESSING && step.isEnabled()) {
        step.onStepPressed { [weak self] result in
          switch result {
          case .failure(let error):
            print(error)
          case .success(let model):
            guard let callback = self?.callback else { return }
            callback(model)
          }
        }
      }
    
  }
}

