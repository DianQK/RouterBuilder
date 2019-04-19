import UIKit

class ExampleSecondViewController: UIViewController {

    let a: Int
    let c: String?
    let g: Int?

    required init(a: Int, c: String?, g: Int?) {
        self.a = a
        self.c = c
        self.g = g
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 25)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        label.text = """
        \(type(of: self))
        a: \(self.a)
        c: \(String(describing: self.c))
        g: \(String(describing: self.g))
        """
    }
}

