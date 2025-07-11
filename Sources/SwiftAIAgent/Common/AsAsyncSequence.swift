import Foundation

struct AsAsyncSequence<S: Sequence>: AsyncSequence {
    typealias Element = S.Element

    let sequence: S

    init(_ sequence: S) {
        self.sequence = sequence
    }

    struct Iterator: AsyncIteratorProtocol {
        var iterator: S.Iterator

        mutating func next() async -> S.Element? {
            return iterator.next()
        }
    }

    func makeAsyncIterator() -> Iterator {
        Iterator(iterator: sequence.makeIterator())
    }
}

extension Sequence {
    var async: AsAsyncSequence<Self> {
        AsAsyncSequence(self)
    }
}
