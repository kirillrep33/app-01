import UIKit
import SwiftUI

class GameViewController: UIViewController {
    private var hostingController: UIHostingController<AppRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rootView = AppRootView(store: AppContext.shared.store)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.isUserInteractionEnabled = true
        hostingController.view.isMultipleTouchEnabled = false

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    override var prefersStatusBarHidden: Bool {
        false
    }
}
