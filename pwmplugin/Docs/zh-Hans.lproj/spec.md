# 通用密码管理器 CLI

通用密码管理器 CLI 是一个命令行程序，接受单个参数来指定子命令。输入和输出为 JSON 文档，本文档中使用 Swift 结构体来描述，因为这样可以形成简洁的 JSON 架构。忽略 JSON 字典中未识别的键（使用 Swift 的 Codable 时会自动忽略）。

输入通过 stdin 提供，输出通过 stdout 提供。两者均以 EOF（即关闭管道的写入端）终止。

所有对象均使用 UTF-8 编码为 JSON。

除 Handshake 外的所有子命令都接受一个 RequestHeader，其中包含某些 CLI 需要的可选信息。

```
struct RequestHeader: Codable {
    var pathToDatabase: String?  // 用户选择的数据库路径。
    var pathToExecutable: String?  // 后端特定 CLI 的路径
    var mode: Mode
    enum Mode: String, Codable {
        case terminal
        case browser
    }
}
```

终端模式和浏览器模式的密码必须分开保存，通常使用密码数据库中的标签等功能。如果浏览器模式的密码与密码管理器浏览器扩展暴露给浏览器的密码相同，那就更好了。

# 子命令

## handshake
用于在未来引入新版本协议并检测 iTerm2 版本与 CLI 版本之间的不匹配。如果 CLI 无法完成协议版本协商或已知 iTerm2 版本不兼容，则可以返回错误。这也提供了一种查询功能和元数据的方式。

本文档描述协议版本 0。

 * 输入：
```
struct HandshakeRequest {
  var iTermVersion: String  // 例如 "3.5.13"。
  var minProtocolVersion: Int  // 可接受的最低协议版本
  var maxProtocolVersion: Int  // 可接受的最高协议版本
}
```
 * 输出：
```
struct HandshakeResponse {
  var protocolVersion: Int  // 指定您选择使用的协议版本。必须在请求的版本范围内。
  var name: String  // 密码管理器的描述性名称，例如 "Dashlane"。
  var requiresMasterPassword: Bool  // 指示是否应提示用户输入主密码，该密码将在 LoginRequest 中发送。
  var canSetPasswords: Bool  // 指示 set-password API 是否可用。
  var userAccounts: [UserAccount]?  // 如果密码管理器支持多个配置文件，则为可用用户账户列表。否则省略。
}

struct UserAccount {
  var name: String // 例如 "个人"
  var identifier: String  // 唯一标识符，如 UUID
  var needsPathToDatabase: Bool  // 如果用户必须选择数据库路径并在请求中提供，则为 true
  var databaseExtension: String?  // 兼容数据库的文件扩展名（例如 "kdbx"），如果可以选择任何文件则为 nil
  var needsPathToExecutable: String?  // 后端可执行文件名称（例如 "keepassxc-cli"），如果不需要则为 nil

```

## login
向用户呈现认证界面。例如，请求生物识别认证。CLI 负责显示认证界面。它可以返回一个令牌，在将来的调用中传递给密码管理器。

 * 输入：
```
struct LoginRequest {
  var header: RequestHeader

  var userAccountID: String?  // 如果 HandshakeResponse.userAccounts 已设置，则此字段会设置
  var masterPassword: String?  // 如果 HandshakeResponse.requiresMasterPassword 为 true，则此字段会设置
}
```

 * 输出
```
struct LoginResponse {
  var token: String?  // 如果不需要在将来的请求中传递认证令牌，则可以省略
}
```

## list-accounts
返回密码管理器中的项目列表。

 * 输入
```
struct ListAccountsRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
}
```
 * 输出：
```
struct ListAccountsResponse {
  var accounts: [Account]
}

// 项目的唯一标识符。通常是 UUID 之类的。
struct AccountIdentifier {
  var accountID: String
}

struct Account {
  var identifier: AccountIdentifier
  var userName: String  // 例如 "george"
  var accountName: String // 例如 "我的个人 Google 账户"
  var hasOTP: Bool  // 如果为 true，iTerm2 将在发送密码前要求输入第二因素代码，或使用密码管理器提供的代码
}
```

## get-password
获取账户的明文密码。
 * 输入
```
struct GetPasswordRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var accountIdentifier: AccountIdentifier
}
```

 * 输出
```
struct Password {
  var password: String
  var otp: String?  // 如果密码管理器支持生成双因素代码，则放在这里，否则省略。
}
```

## set-password
更改账户的密码。
 * 输入
```
struct SetPasswordRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var accountIdentifier: AccountIdentifier
  var newPassword: String?
}
```
 * 输出
```
struct SetPasswordResponse {
}
```

## delete-account
  * 输入：
```
struct DeleteAccountRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var accountIdentifier: AccountIdentifier
}
```
  * 输出：
```
struct DeleteAccountResponse {
}
```

## add-account
  * 输入：
```
struct AddAccountRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var userName: String
  var accountName: String
  var password: String?  // 如果 HandshakeResponse 指示不允许设置密码，则省略此字段；密码管理器应在此情况下分配随机密码（这是 1password 的工作方式）。
}
```
  * 输出：
```
struct AddAccountResponse {
  var accountIdentifier: AccountIdentifier
}
```

# 错误处理

如果发生错误，任何命令都可以返回此结构的实例，而不是文档中记录的输出 JSON 文档：
```
struct ErrorResponse {
  var error: String
}
```

# 示例用法

```
% echo '{"header": { "pathToDatabase": "/Users/george/passwords.db", "pathToExecutable": "/opt/homebrew/bin/SomePasswordManagerCLI", mode: "terminal" }, "token": "secret goes here", "accountIdentifier": { "accountID": "123-456" } }' | pwmplugin get-password
{ "password": "Hunter2" }
```
