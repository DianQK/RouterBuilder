import UIKit

class ExampleFirstViewController: UIViewController {

    let a: Int
    let b: String
    let c: String?
    let d: Float

    required init(a: Int, b: String, c: String?, d: Float) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
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
        a: \(self.a) \(type(of: self.a))
        b: \(self.b) \(type(of: self.b))
        c: \(String(describing: self.c))
        d: \(self.d) \(type(of: self.d))
        """
    }

}
