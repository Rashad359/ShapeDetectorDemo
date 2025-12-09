import UIKit

final class HandViewBuilder {
    func build() -> UIViewController {
        let viewModel = HandViewModel()
        let handVC = HandViewController(viewModel: viewModel)
        return handVC
    }
}
