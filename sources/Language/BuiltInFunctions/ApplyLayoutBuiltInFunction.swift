//
//  ApplyLayoutBuiltInFunction.swift
//  iTerm2SharedARC
//
//  Registers `iterm2.apply_layout(spec_json)` as a built-in function
//  callable from the Python API. The Python wrapper
//  `App.async_apply_layout` serializes the user-supplied spec dict to
//  JSON and invokes this function.
//

import Foundation

class ApplyLayoutBuiltInFunction: iTermBuiltInFunction {
    @objc static func registerBuiltInFunction() {
        let f = iTermBuiltInFunction(
            name: "apply_layout",
            arguments: ["spec_json_b64": NSString.self],
            optionalArguments: Set(),
            defaultValues: [:],
            context: .app,
            sideEffectsPlaceholder: "[apply_layout]") { parameters, completion in
                // The spec is a JSON object containing arbitrary GUIDs and
                // user-controlled strings. Sending it as a literal expression-
                // level string would require backslash-escaping every `"`,
                // but the iTerm expression parser does not decode `\"` back
                // to `"`. Base64 sidesteps that entirely.
                guard let specB64 = parameters["spec_json_b64"] as? String else {
                    completion(nil, Self.error(NSLocalizedString("Missing spec_json_b64 argument", tableName: "Language", comment: "Apply layout error: missing spec argument")))
                    return
                }
                guard let data = Data(base64Encoded: specB64),
                      let parsed = try? JSONSerialization.jsonObject(with: data),
                      let dict = parsed as? [String: Any] else {
                    completion(nil, Self.error(NSLocalizedString("spec_json_b64 is not valid base64-encoded JSON", tableName: "Language", comment: "Apply layout error: invalid base64 JSON")))
                    return
                }

                do {
                    let spec = try LayoutSpec.parse(dict)

                    let environment = iTermLayoutEnvironment()
                    let plan = try LayoutResolver.resolve(spec, environment: environment)

                    let mutator = iTermLayoutMutator()
                    try LayoutTransaction.execute(plan: plan, mutator: mutator)

                    // Pass nil (not NSNull) so the wire response carries
                    // the literal string "null" — `it_jsonStringForObject`
                    // returns nil for NSNull, which would result in an
                    // empty json_result and a JSONDecodeError in the
                    // Python helper.
                    completion(nil, nil)
                } catch let error as LayoutSpecError {
                    completion(nil, Self.error(Self.describe(error)))
                } catch let error as LayoutResolverError {
                    completion(nil, Self.error(Self.describe(error)))
                } catch let error as LayoutMutatorError {
                    completion(nil, Self.error(error.localizedDescription))
                } catch {
                    completion(nil, Self.error(String(format: NSLocalizedString("%@: %@", tableName: "Language", comment: "Apply layout error: unexpected error type"), String(describing: type(of: error)), String(describing: error))))
                }
            }
        iTermBuiltInFunctions.sharedInstance().register(f, namespace: "iterm2")
    }

    private static func error(_ message: String) -> NSError {
        return NSError(domain: "com.iterm2.apply-layout",
                       code: 1,
                       userInfo: [NSLocalizedDescriptionKey: message])
    }

    private static func describe(_ error: LayoutSpecError) -> String {
        switch error {
        case .missingField(let path, let field):
            return String(format: NSLocalizedString("Missing field '%@' at %@", tableName: "Language", comment: "Apply layout spec error: missing field"), field, path)
        case .wrongType(let path, let expected):
            return String(format: NSLocalizedString("Wrong type at %@: expected %@", tableName: "Language", comment: "Apply layout spec error: wrong type"), path, expected)
        case .unknownLeafKind(let path):
            return String(format: NSLocalizedString("Unknown leaf kind at %@ (must be session_id, new_session, or splitter)", tableName: "Language", comment: "Apply layout spec error: unknown leaf kind"), path)
        case .splitterTooFewChildren(let path, let count):
            return String(format: NSLocalizedString("Splitter at %@ has %d children; must have at least 2", tableName: "Language", comment: "Apply layout spec error: splitter too few children"), path, count)
        case .nestedSameOrientation(let path):
            return String(format: NSLocalizedString("Same-orientation splitter nesting at %@ (vertical inside vertical or horizontal inside horizontal)", tableName: "Language", comment: "Apply layout spec error: nested same orientation"), path)
        case .treeTooDeep(let path, let depth):
            return String(format: NSLocalizedString("Layout tree at %@ is too deep (%d)", tableName: "Language", comment: "Apply layout spec error: tree too deep"), path, depth)
        case .duplicateSessionID(let guid):
            return String(format: NSLocalizedString("Session GUID '%@' appears more than once in the spec", tableName: "Language", comment: "Apply layout spec error: duplicate session ID"), guid)
        }
    }

    private static func describe(_ error: LayoutResolverError) -> String {
        switch error {
        case .unknownSession(let guid):
            return String(format: NSLocalizedString("Unknown session: %@", tableName: "Language", comment: "Apply layout resolver error: unknown session"), guid)
        case .unknownTab(let guid):
            return String(format: NSLocalizedString("Unknown tab: %@", tableName: "Language", comment: "Apply layout resolver error: unknown tab"), guid)
        case .unknownWindow(let guid):
            return String(format: NSLocalizedString("Unknown window: %@", tableName: "Language", comment: "Apply layout resolver error: unknown window"), guid)
        case .orphanedSession(let tabGUID, let sessionGUID):
            return String(format: NSLocalizedString("Session %@ in tab %@ is unaccounted for; it must appear in the new layout or in close_sessions/close_tabs", tableName: "Language", comment: "Apply layout resolver error: orphaned session"), sessionGUID, tabGUID)
        case .tmuxTabNotSupported(let tabGUID):
            return String(format: NSLocalizedString("Tab %@ is a tmux integration tab; layout application is not supported on tmux tabs", tableName: "Language", comment: "Apply layout resolver error: tmux tab not supported"), tabGUID)
        case .newTabsNotSupported:
            return NSLocalizedString("The 'new_tabs' field is not supported by apply_layout", tableName: "Language", comment: "Apply layout resolver error: new tabs not supported")
        case .newWindowsNotSupported:
            return NSLocalizedString("The 'new_windows' field is not supported by apply_layout", tableName: "Language", comment: "Apply layout resolver error: new windows not supported")
        case .unknownProfile(let guid):
            return String(format: NSLocalizedString("Unknown profile: %@", tableName: "Language", comment: "Apply layout resolver error: unknown profile"), guid)
        }
    }
}
