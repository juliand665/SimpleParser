public struct Parser {
	public var input: Substring
	
	public var isDone: Bool { input.isEmpty }
	
	public var next: Character? {
		input.first
	}
	
	public init<S>(reading string: S) where S: StringProtocol {
		input = Substring(string)
	}
	
	public mutating func tryConsume<S>(_ part: S) -> Bool where S: StringProtocol {
		if input.hasPrefix(part) {
			input.removeFirst(part.count)
			return true
		} else {
			return false
		}
	}
	
	public mutating func consume<S>(_ part: S) where S: StringProtocol {
		let wasConsumed = tryConsume(part)
		precondition(wasConsumed, "tried to consume '\(part)' but input started with '\(input.prefix(part.count))' instead.")
	}
	
	/// - returns: the consumed part, excluding the separator, or `nil` if the separator was not encountered
	@discardableResult
	public mutating func consume(through separator: Character) -> Substring? {
		let consumed = consume(upTo: separator)
		if consumed != nil {
			input.removeFirst()
		}
		return consumed
	}
	
	/// - returns: the consumed part, excluding the separator, or `nil` if the separator was not encountered
	@discardableResult
	public mutating func consume(upTo separator: Character) -> Substring? {
		guard let index = input.firstIndex(of: separator) else { return nil }
		defer { input = input[index...] }
		return input.prefix(upTo: index)
	}
	
	public mutating func consume(copiesOf separator: Character) {
		input = input.drop { $0 == separator }
	}
	
	@discardableResult
	public mutating func consume(while shouldConsume: (Character) -> Bool) -> Substring {
		let consumed = input.prefix(while: shouldConsume)
		input.removeFirst(consumed.count)
		return consumed
	}
	
	public mutating func consumeWhitespace() {
		consume(while: \.isWhitespace)
	}
	
	@discardableResult
	public mutating func consumeNext() -> Character {
		input.removeFirst()
	}
	
	@discardableResult
	public mutating func consumeNext(_ maxLength: Int) -> Substring {
		defer { input.removeFirst(maxLength) }
		return input.prefix(maxLength)
	}
	
	@discardableResult
	public mutating func consumeRest() -> Substring {
		defer { input = Substring() }
		return input
	}
	
	private static let numberCharacters = Set("+-0123456789")
	public mutating func readInt() -> Int {
		Int(consume(while: Self.numberCharacters.contains))!
	}
	
	private static let hexNumberCharacters = Set("0123456789ABCDEFabcdef")
	public mutating func readHexInt() -> Int {
		_ = tryConsume("0x")
		return Int(consume(while: Self.hexNumberCharacters.contains), radix: 16)!
	}
	
	public mutating func readWord() -> Substring {
		consume { $0.isLetter || $0.isNumber }
	}
	
	@_disfavoredOverload
	public mutating func readWord() -> String {
		String(readWord())
	}
	
	public mutating func readValue<T: Parseable>(of type: T.Type = T.self) -> T {
		T(from: &self)
	}
}

public protocol Parseable {
	init<S>(rawValue: S) where S: StringProtocol
	init(from parser: inout Parser)
}

public extension Parseable {
	init<S>(rawValue: S) where S: StringProtocol {
		var parser = Parser(reading: rawValue)
		self.init(from: &parser)
	}
}

extension Array: Parseable where Element == Int {
	public init(from parser: inout Parser) {
		self.init()
		repeat {
			parser.consume(copiesOf: " ")
			append(parser.readInt())
		} while parser.tryConsume(",")
	}
}
