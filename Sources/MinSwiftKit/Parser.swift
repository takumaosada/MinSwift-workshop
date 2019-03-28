import Foundation
import SwiftSyntax

class Parser: SyntaxVisitor {
    private(set) var tokens: [TokenSyntax] = []
    private var index = 0
    private(set) var currentToken: TokenSyntax!

    // MARK: Practice 1

    override func visit(_ token: TokenSyntax) {
        print("Parsing \(token.tokenKind)")
        tokens.append(token)
    }

    @discardableResult
    func read() -> TokenSyntax {
        let hogehoge = tokens[index]
        currentToken = hogehoge
        index += 1
        return hogehoge
    }

    func peek(_ n: Int = 0) -> TokenSyntax {
        let tokenIndex = tokens[index + n]
        return tokenIndex
    }

    // MARK: Practice 2

    private func extractNumberLiteral(from token: TokenSyntax) -> Double? {
        switch token.tokenKind {
        case .integerLiteral(let tokenInt):
            return Double(tokenInt)
        case .floatingLiteral(let tokenFloat):
            return Double(tokenFloat)
        default:
            return nil
        }
    }

    func parseNumber() -> Node {
        guard let value = extractNumberLiteral(from: currentToken) else {
            fatalError("any number is expected")
        }
        read() // eat literal
        return NumberNode(value: value)
    }
    
    

    func parseIdentifierExpression() -> Node {

        guard case .identifier(let value1) = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        guard case .leftParen = currentToken.tokenKind else {
            return VariableNode(identifier: value1)
        }
        read()
        
        var arguments: Array<CallExpressionNode.Argument> = []
        while true {
            if case .rightParen = currentToken.tokenKind {
                read()
                break
            } else if case .identifier(let argumentName) = currentToken.tokenKind {
                read()
                
                guard case .colon = currentToken.tokenKind else {
                    fatalError()
                }
                read()
                
                let value = parseExpression()
                let argument = CallExpressionNode.Argument(label: argumentName, value: value!)
                arguments.append(argument)
            } else if case .comma = currentToken.tokenKind {
                read()
            }
        }
        
         return CallExpressionNode(callee: value1, arguments: arguments)
    }

    // MARK: Practice 3

    func extractBinaryOperator(from token: TokenSyntax) -> BinaryExpressionNode.Operator? {
        switch token.tokenKind {
        case .spacedBinaryOperator(let value):
            return BinaryExpressionNode.Operator.init(rawValue: value)
        default:
            return nil
        }
    }

    private func parseBinaryOperatorRHS(expressionPrecedence: Int, lhs: Node?) -> Node? {
        var currentLHS: Node? = lhs
        while true {
            let binaryOperator = extractBinaryOperator(from: currentToken!)
            let operatorPrecedence = binaryOperator?.precedence ?? -1
            
            // Compare between nextOperator's precedences and current one
            if operatorPrecedence < expressionPrecedence {
                return currentLHS
            }
            
            read() // eat binary operator
            var rhs = parsePrimary()
            if rhs == nil {
                return nil
            }
            
            // If binOperator binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrecedence = extractBinaryOperator(from: currentToken)?.precedence ?? -1
            if (operatorPrecedence < nextPrecedence) {
                // Search next RHS from currentRHS
                // next precedence will be `operatorPrecedence + 1`
                rhs = parseBinaryOperatorRHS(expressionPrecedence: operatorPrecedence + 1, lhs: rhs)
                if rhs == nil {
                    return nil
                }
            }
            
            guard let nonOptionalRHS = rhs else {
                fatalError("rhs must be nonnull")
            }
            
            currentLHS = BinaryExpressionNode(binaryOperator!,
                                              lhs: currentLHS!,
                                              rhs: nonOptionalRHS)
        }
    }

    // MARK: Practice 4

    func parseFunctionDefinitionArgument() -> FunctionNode.Argument {
        let firstIdentifier: FunctionNode.Argument
        switch currentToken.tokenKind {
        case .identifier(let value):
            firstIdentifier = FunctionNode.Argument.init(label: value, variableName: value)
            read()
        default:
            fatalError("Not Implemented")
        }
        
        switch currentToken.tokenKind {
        case .colon:
            read()
        default:
            fatalError("Not Implemented")
        }
        
        switch currentToken.tokenKind {
        case .identifier:
            read()
        default:
            fatalError("Not Implemented")
        }
        
        return firstIdentifier
    }

    func parseFunctionDefinition() -> Node {
        
        guard case .funcKeyword = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        guard case .identifier(let functionName) = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        guard case .leftParen = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        
        var arguments: [FunctionNode.Argument] = []
        while true {
            if case .rightParen = currentToken.tokenKind {
                read()
                break
            } else if case .identifier(let value) = currentToken.tokenKind {
                read()
                
                guard case .colon = currentToken.tokenKind else {
                    fatalError()
                }
                read()
                
                let argument = FunctionNode.Argument(label: value, variableName: value)
                arguments.append(argument)
                
            } else if case .comma = currentToken.tokenKind {
                read()
            }
        }
        
        guard case .arrow = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        guard case .identifier = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        guard case .leftBrace = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        guard let body = parseExpression() else {
            fatalError()
        }

        guard case .rightBrace = currentToken.tokenKind else {
            fatalError()
        }
        read()
        
        return FunctionNode.init(name: functionName, arguments: arguments, returnType: .double, body: body)
    }

    // MARK: Practice 7

    func parseIfElse() -> Node {
        fatalError("Not Implemented")
    }

    // PROBABLY WORKS WELL, TRUST ME

    func parse() -> [Node] {
        var nodes: [Node] = []
        read()
        while true {
            switch currentToken.tokenKind {
            case .eof:
                return nodes
            case .funcKeyword:
                let node = parseFunctionDefinition()
                nodes.append(node)
            default:
                if let node = parseTopLevelExpression() {
                    nodes.append(node)
                    break
                } else {
                    read()
                }
            }
        }
        return nodes
    }

    private func parsePrimary() -> Node? {
        switch currentToken.tokenKind {
        case .identifier:
            return parseIdentifierExpression()
        case .integerLiteral, .floatingLiteral:
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        case .eof:
            return nil
        default:
            fatalError("Unexpected token \(currentToken.tokenKind) \(currentToken.text)")
        }
        return nil
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node {
        guard case .returnKeyword = currentToken.tokenKind else {
            fatalError("returnKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat return
        if let expression = parseExpression() {
            return ReturnNode(body: expression)
        } else {
            // return nothing
            return ReturnNode(body: nil)
        }
    }

    private func parseParen() -> Node? {
        read() // eat (
        guard let v = parseExpression() else {
            return nil
        }

        guard case .rightParen = currentToken.tokenKind else {
                fatalError("expected ')'")
        }
        read() // eat )

        return v
    }

    private func parseTopLevelExpression() -> Node? {
        if let expression = parseExpression() {
            // we treat top level expressions as anonymous functions
            let anonymousPrototype = FunctionNode(name: "main", arguments: [], returnType: .int, body: expression)
            return anonymousPrototype
        }
        return nil
    }
}

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division: return 40
        case .lessThan:
            fatalError("Not Implemented")
        }
    }
}
