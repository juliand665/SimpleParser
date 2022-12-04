public struct Parser {
	public var input: Substring
	
	@inlinable
	public var isDone: Bool { input.isEmpty }
	
	@inlinable
	public var next: Character? {
		input.first
	}
	
	@inlinable
	public var offsetInInput: Int {
		input.base.distance(from: input.base.startIndex, to: input.startIndex)
	}
	
	@inlinable
	public init<S>(reading string: S) where S: StringProtocol {
		input = Substring(string)
	}
	
	@inlinable
	public mutating func tryConsume<S>(_ part: S) -> Bool where S: StringProtocol {
		if input.hasPrefix(part) {
			input.removeFirst(part.count)
			return true
		} else {
			return false
		}
	}
	
	@inlinable
	public mutating func consume<S>(_ part: S) where S: StringProtocol {
		let wasConsumed = tryConsume(part)
		precondition(wasConsumed, "tried to consume '\(part)' but input started with '\(input.prefix(part.count))' instead.")
	}
	
	/// - returns: the consumed part, excluding the separator, or `nil` if the separator was not encountered
	@inlinable
	@discardableResult
	public mutating func consume(through separator: Character) -> Substring? {
		let consumed = consume(upTo: separator)
		if consumed != nil {
			input.removeFirst()
		}
		return consumed
	}
	
	/// - returns: the consumed part, excluding the separator, or `nil` if the separator was not encountered
	@inlinable
	@discardableResult
	public mutating func consume(upTo separator: Character) -> Substring? {
		guard let index = input.firstIndex(of: separator) else { return nil }
		defer { input = input[index...] }
		return input.prefix(upTo: index)
	}
	
	@inlinable
	public mutating func consume(copiesOf separator: Character) {
		input = input.drop { $0 == separator }
	}
	
	@inlinable
	@discardableResult
	public mutating func consume(while shouldConsume: (Character) -> Bool) -> Substring {
		let consumed = input.prefix(while: shouldConsume)
		input.removeFirst(consumed.count)
		return consumed
	}
	
	@inlinable
	public mutating func consumeWhitespace() {
		consume(while: \.isWhitespace)
	}
	
	@inlinable
	@discardableResult
	public mutating func consumeNext() -> Character {
		input.removeFirst()
	}
	
	@inlinable
	@discardableResult
	public mutating func tryConsumeNext() -> Character? {
		guard !isDone else { return nil }
		return consumeNext()
	}
	
	@inlinable
	@discardableResult
	public mutating func consumeNext(_ maxLength: Int) -> Substring {
		defer { input.removeFirst(maxLength) }
		return input.prefix(maxLength)
	}
	
	@inlinable
	@discardableResult
	public mutating func consumeRest() -> Substring {
		defer { input = Substring() }
		return input
	}
	
	@usableFromInline
	static let numberCharacters = Set("0123456789")
	@inlinable
	public mutating func readInt() -> Int {
		let sign = tryConsume("-") ? -1 : tryConsume("+") ? 1 : 1
		return sign * Int(consume(while: Self.numberCharacters.contains))!
	}
	
	@usableFromInline
	static let hexNumberCharacters = Set("0123456789ABCDEFabcdef")
	@inlinable
	public mutating func readHexInt() -> Int {
		_ = tryConsume("0x")
		return Int(consume(while: Self.hexNumberCharacters.contains), radix: 16)!
	}
	
	@inlinable
	public mutating func readWord() -> Substring {
		consume { $0.isLetter || $0.isNumber }
	}
	
	@_disfavoredOverload
	@inlinable
	public mutating func readWord() -> String {
		String(readWord())
	}
	
	@inlinable
	public mutating func readValue<T: Parseable>(of type: T.Type = T.self) -> T {
		T(from: &self)
	}
}

public protocol Parseable {
	init<S>(rawValue: S) where S: StringProtocol
	init(from parser: inout Parser)
}

public extension Parseable {
	@inlinable
	init<S>(rawValue: S) where S: StringProtocol {
		var parser = Parser(reading: rawValue)
		self.init(from: &parser)
	}
}

extension Array: Parseable where Element: Parseable {
	@inlinable
	public init(from parser: inout Parser) {
		self.init()
		repeat {
			parser.consume(copiesOf: " ")
			append(parser.readValue())
		} while parser.tryConsume(",")
	}
}
