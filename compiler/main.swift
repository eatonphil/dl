import Foundation

let fileName = CommandLine.arguments[1]
let program = try String(contentsOfFile: fileName)

let ast = parse(program)
generate(ast)
