import UIKit

final class MainViewBuilder {
    func build() -> UIViewController {
        let viewModel = MainViewModel()
        let vc = MainViewController(viewModel: viewModel)
        return vc
    }
}
