//
//  SSHEndpointException.swift
//  iTerm2
//
//  Created by George Nachman on 7/1/25.
//

enum SSHEndpointException: LocalizedError {
    case connectionClosed
    case fileNotFound
    case internalError  // e.g., non-decodable data from fetch
    case transferCanceled

    var errorDescription: String? {
        get {
            switch self {
            case .connectionClosed:
                return NSLocalizedString("Connection closed", tableName: "SSH", comment: "SSH endpoint: connection closed error")
            case .fileNotFound:
                return NSLocalizedString("File not found", tableName: "SSH", comment: "SSH endpoint: file not found error")
            case .internalError:
                return NSLocalizedString("Internal error", tableName: "SSH", comment: "SSH endpoint: internal error")
            case .transferCanceled:
                return NSLocalizedString("File transfer canceled", tableName: "SSH", comment: "SSH endpoint: transfer canceled error")
            }
        }
    }
}

