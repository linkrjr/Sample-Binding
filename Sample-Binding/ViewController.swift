//
//  ViewController.swift
//  Sample-Binding
//
//  Created by Ronaldo GomesJr on 28/04/2016.
//  Copyright © 2016 Technophile IT. All rights reserved.
//

import UIKit

infix operator ->> { associativity left precedence 105 }

func ->><T>(left: Dynamic<T>, right: Bond<T>) {
    right.bind(left)
}

func ->><T, U: Bondable where U.BondType == T>(left: Dynamic<T>, right: U) {
    left ->> right.designatedBond
}

protocol Bondable {
    associatedtype BondType
    var designatedBond: Bond<BondType> { get }
}

extension UILabel: Bondable {
    
    typealias BondType = String
    
    var designatedBond: Bond<BondType> {
        return self.textBond
    }
    
    struct AssociatedKeys {
        static var BondKey:UInt8 = 0
    }

    var textBond: Bond<BondType> {
        
        if let b: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.BondKey) {
            return b as! Bond<String>
        } else {
            let b = Bond<String>() { [unowned self] value in
                self.text = value
            }
            objc_setAssociatedObject(self, &AssociatedKeys.BondKey, b, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return b
        }
        
    }

}

class BondBox<T> {
    weak var bond: Bond<T>?
    init(_ b:Bond<T>) { bond = b }
}

class Bond<T> {
    
    typealias Listener = T -> Void
    
    var listener: Listener
    
    init(_ listener: Listener) {
        self.listener = listener
    }
    
    func bind(dynamic: Dynamic<T>) {
        dynamic.bonds.append(self)
    }
    
}

class Dynamic<T> {
    
    var bonds:[Bond<T>] = []
    
    var value: T {
        didSet {
            bonds.map { (bond) -> Void in
                bond.listener(value)
            }
        }
    }
    
    init(_ v:T) {
        self.value = v
    }
    
    func map<U>(transform: T -> U) -> Dynamic<U> {
        return Dynamic<U>(transform(value))
    }
    
}

class ViewController: UIViewController {
    
    @IBOutlet weak private var nameLabel:UILabel!
    @IBOutlet weak private var nameLabel2:UILabel!
    @IBOutlet weak private var textField:UITextField!

    var name: Dynamic<String> = Dynamic("Ronaldo")
    
    var tapCount: Dynamic<Int> = Dynamic(0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nameLabel.textBond.bind(self.name)
        
//        tapCount.map { "\($0)" } ->> self.nameLabel2
        
        self.nameLabel2.textBond.bind(self.tapCount.map({ (v) -> String in
            return "\(v)"
        }))
        
        self.textField.addTarget(self, action: #selector(ViewController.textChanged(_:)), forControlEvents: .EditingChanged)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapped(_:))))
        
    }

    func tapped(sender:AnyObject) {
        
        self.tapCount.value += 1
        
    }
    
    func textChanged(sender:AnyObject) {
        self.name.value = self.textField.text!
    }

}

