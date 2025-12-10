import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        let mainNav = self.createNav(with: "main", image: UIImage(systemName: "figure.stand"), vc: MainViewBuilder().build())
        let handNav = self.createNav(with: "Hand", image: UIImage(systemName: "hand.wave"), vc: HandViewBuilder().build())
        self.setViewControllers([mainNav, handNav], animated: true)
    }
    
    private func createNav(with title: String, image: UIImage?, vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem.title = title
        nav.tabBarItem.image = image
        return nav
    }
}
