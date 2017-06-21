
// Coding Exercise 1: Generic programming with protocols (Answers)

import Foundation

protocol Number {
  
    // The main operator requirements you'll want are...
    
    static func +(lhs: Self, rhs: Self) -> Self
    static func +=(lhs: inout Self, rhs: Self)

    static func -(lhs: Self, rhs: Self) -> Self
    static func -=(lhs: inout Self, rhs: Self)

    static func *(lhs: Self, rhs: Self) -> Self
    static func *=(lhs: inout Self, rhs: Self)
    
    // Note that / is not included here, as it has different semantics
    // for integers – namely it truncates the fractional component.
    //
    // Therefore, generalising it for all numeric type may yield unexpected
    // results in some generic algorithms.
    
    // For the rest of the requirements, compare:
    // - In Swift 3: The Numeric protocol described in https://github.com/apple/swift-evolution/blob/master/proposals/0104-improved-integers.md#numeric
    // - In Swift 4: The Standard Library Numeric protocol
}


// We need to constrain to Number (or Numeric in Swift 4).
//
func square<T : Number>(_ value: T) -> T {
    return value * value
}


// In Swift 3, we can use the SignedNumber protocol, which all signed number types conform to.
//
// In Swift 4, you can use SignedNumeric.
//
func sameSign<T : SignedNumber>(_ lhs: T, _ rhs: T) -> Bool {
    return (lhs < 0 && rhs < 0) || (lhs >= 0 && rhs >= 0)
}

print(sameSign(5, -4))  // false
print(sameSign(-1, -9)) // true
print(sameSign(7, 6))   // true


// Didn't compile because the types T, U and V aren't necessarily the same type.
// (the caller can satisfy them with arbitrary concrete types! e.g (String, Int) -> Double)
//
// Solution: Only use one generic placeholder, therefore expressing that
// the function takes two parameters of the same type, and returns that same type.
//
func pickRandom<T>(_ lhs: T, rhs: T) -> T {
    return arc4random_uniform(2) == 0 ? lhs : rhs
}

// Because the class Node is nested, we only need the generic placeholder on LinkedList.
//
struct LinkedList<Element> : Collection {
    
    // Usually this should be private to hide the implementation details of the node
    // from the caller (they should only deal with indices), but is internal
    // here in order to simplify the example (you'll need an index wrapper to hide the
    // node associated value in Index, for example).
    class Node {
        
        var element: Element
        
        private var _next: Node?
        
        var next: Node? {
            get {
                // Ensure that the next node always has a greater depth than the current.
                // (this could, for example, get invalidated upon a middle insert)
                //
                // Any stored references to a given Node in the linked list MUST
                // also update the depth upon any mutations that would invalidate it.
                //
                _next?.depth = depth + 1
                return _next
            }
            set {
                _next = newValue
            }
        }
        
        // A quick and simple way for us to implement Comparable
        // for the linked list's indices.
        fileprivate(set) var depth: Int
        
        init(element: Element, depth: Int) {
            self.element = element
            self.depth = depth
        }
    }
    
    private var head: Node?
    private var tail: Node?
    
    init() {}
    
    // To implement a generic Sequence initialiser, we need a generic placeholder constrained to Sequence,
    // and a where clause constraining that the sequence's elements be the same type as the 
    // linked list's Element type.
    //
    init<S : Sequence>(_ s: S) where S.Iterator.Element == Element {
        for element in s {
            append(element)
        }
    }
    
    mutating func append(_ newElement: Element) {
        
        // The new tail node will either have a depth of oldTail + 1, or 0 if it's the head.
        //
        let newNode = Node(element: newElement, depth: (tail?.depth ?? -1) + 1)
        
        if let tail = tail {
            tail.next = newNode
        } else {
            head = newNode
        }
        
        tail = newNode
    }
    
    // Collection conformance for LinkedList...
    // (notice how we can remove the makeIterator() implementation,
    // as Collection provides us with a default implementation using IndexingIterator).
    
    // Simple wrapper for a Node, or endIndex.
    enum Index : Comparable {
        
        static func == (lhs: Index, rhs: Index) -> Bool {
            switch (lhs, rhs) {
            case let (.node(lhsNode), .node(rhsNode)):
                return lhsNode === rhsNode
            case (.endIndex, .endIndex):
                return true
            default:
                return false
            }
        }
        
        static func < (lhs: Index, rhs: Index) -> Bool {
            switch (lhs, rhs) {
            case let (.node(lhsNode), .node(rhsNode)):
                return lhsNode.depth < rhsNode.depth
            case (.node, .endIndex):
                return true
            default:
                return false
            }
        }
        
        case node(Node)
        case endIndex
        
        init(_ node: Node?) {
            if let node = node {
                self = .node(node)
            } else {
                self = .endIndex
            }
        }
    }
    
    var startIndex: Index {
        // Wrap the head node in an Index, or give the endIndex if nil.
        return Index(head)
    }
    
    let endIndex = Index.endIndex
    
    func index(after i: Index) -> Index {
        
        guard case let .node(node) = i else {
            fatalError("Cannot advance past endIndex")
        }
        
        return Index(node.next)
    }
    
    subscript(index: Index) -> Element {
        
        guard case let .node(node) = index else {
            fatalError("Index out of bounds")
        }
        
        // Simply return the node's element.
        return node.element
    }
}


// We construct a new instance by providing a type for the Element placeholder.
//
var linkedList = LinkedList<String>()
linkedList.append("foo")
linkedList.append("bar")

for element in linkedList {
    print(element)
}

// foo
// bar


// We can construct a new instance with our sequence initialiser,
// allowing the compiler to infer the Element type to be Int.
//
let linkedList2 = LinkedList([2, 3, 4])

for element in linkedList2 {
    print(element)
}

// 2
// 3
// 4


var index = linkedList2.startIndex

while index < linkedList2.endIndex {
    print(linkedList2[index])
    linkedList2.formIndex(after: &index)
}

// 2
// 3
// 4
