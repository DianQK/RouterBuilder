import UIKit

let routes: [String: ([URLQueryItem]) -> UIViewController] = [
    "ExampleFirstViewController": { queryItems in
        return ExampleFirstViewController(
            a: Int(queryItems.first(where: { $0.name == "a" })!.value!)!,
            b: queryItems.first(where: { $0.name == "b" })!.value!,
            c: queryItems.first(where: { $0.name == "c" })?.value,
            d: Float(queryItems.first(where: { $0.name == "d" })!.value!)!
        )
    },
    "ExampleSecondViewController": { queryItems in
        return ExampleSecondViewController(
            a: Int(queryItems.first(where: { $0.name == "a" })!.value!)!,
            c: queryItems.first(where: { $0.name == "c" })?.value,
            g: queryItems.first(where: { $0.name == "g" })?.value.flatMap(Int.init)
        )
    },
]
