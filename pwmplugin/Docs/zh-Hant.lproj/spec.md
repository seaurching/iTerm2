# 通用密碼管理器 CLI

通用密碼管理器 CLI 是一個命令列程式，接受單一參數來指定子命令。輸入和輸出為 JSON 文件，本文件中使用 Swift 結構體來描述，因為這樣可以形成簡潔的 JSON 架構。忽略 JSON 字典中未識別的鍵（使用 Swift 的 Codable 時會自動忽略）。

輸入透過 stdin 提供，輸出透過 stdout 提供。兩者均以 EOF（即關閉管道的寫入端）終止。

所有物件均使用 UTF-8 編碼為 JSON。

除 Handshake 外的所有子命令都接受一個 RequestHeader，其中包含某些 CLI 需要的可選資訊。

```
struct RequestHeader: Codable {
    var pathToDatabase: String?  // 使用者選擇的資料庫路徑。
    var pathToExecutable: String?  // 後端特定 CLI 的路徑
    var mode: Mode
    enum Mode: String, Codable {
        case terminal
        case browser
    }
}
```

終端模式和瀏覽器模式的密碼必須分開儲存，通常使用密碼資料庫中的標籤等功能。如果瀏覽器模式的密碼與密碼管理器瀏覽器擴充功能暴露給瀏覽器的密碼相同，那就更好了。

# 子命令

## handshake
用於在未來引入新版本協定並偵測 iTerm2 版本與 CLI 版本之間的不匹配。如果 CLI 無法完成協定版本交涉或已知 iTerm2 版本不相容，則可以傳回錯誤。這也提供了一種查詢功能和元資料的方式。

本文件描述協定版本 0。

 * 輸入：
```
struct HandshakeRequest {
  var iTermVersion: String  // 例如 "3.5.13"。
  var minProtocolVersion: Int  // 可接受的最低協定版本
  var maxProtocolVersion: Int  // 可接受的最高協定版本
}
```
 * 輸出：
```
struct HandshakeResponse {
  var protocolVersion: Int  // 指定您選擇使用的協定版本。必須在請求的版本範圍內。
  var name: String  // 密碼管理器的描述性名稱，例如 "Dashlane"。
  var requiresMasterPassword: Bool  // 指示是否應提示使用者輸入主密碼，該密碼將在 LoginRequest 中傳送。
  var canSetPasswords: Bool  // 指示 set-password API 是否可用。
  var userAccounts: [UserAccount]?  // 如果密碼管理器支援多個設定檔，則為可用使用者帳戶清單。否則省略。
}

struct UserAccount {
  var name: String // 例如 "個人"
  var identifier: String  // 唯一識別碼，如 UUID
  var needsPathToDatabase: Bool  // 如果使用者必須選擇資料庫路徑並在請求中提供，則為 true
  var databaseExtension: String?  // 相容資料庫的副檔名（例如 "kdbx"），如果可以選擇任何檔案則為 nil
  var needsPathToExecutable: String?  // 後端可執行檔名稱（例如 "keepassxc-cli"），如果不需要則為 nil

```

## login
向使用者呈現認證介面。例如，請求生物識別認證。CLI 負責顯示認證介面。它可以傳回一個權杖，在將來的呼叫中傳遞給密碼管理器。

 * 輸入：
```
struct LoginRequest {
  var header: RequestHeader

  var userAccountID: String?  // 如果 HandshakeResponse.userAccounts 已設定，則此欄位會設定
  var masterPassword: String?  // 如果 HandshakeResponse.requiresMasterPassword 為 true，則此欄位會設定
}
```

 * 輸出
```
struct LoginResponse {
  var token: String?  // 如果不需要在將來的請求中傳遞認證權杖，則可以省略
}
```

## list-accounts
傳回密碼管理器中的項目清單。

 * 輸入
```
struct ListAccountsRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
}
```
 * 輸出：
```
struct ListAccountsResponse {
  var accounts: [Account]
}

// 項目的唯一識別碼。通常是 UUID 之類的。
struct AccountIdentifier {
  var accountID: String
}

struct Account {
  var identifier: AccountIdentifier
  var userName: String  // 例如 "george"
  var accountName: String // 例如 "我的個人 Google 帳戶"
  var hasOTP: Bool  // 如果為 true，iTerm2 將在傳送密碼前要求輸入第二因素代碼，或使用密碼管理器提供的代碼
}
```

## get-password
取得帳戶的明文密碼。
 * 輸入
```
struct GetPasswordRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var accountIdentifier: AccountIdentifier
}
```

 * 輸出
```
struct Password {
  var password: String
  var otp: String?  // 如果密碼管理器支援產生雙因素代碼，則放在這裡，否則省略。
}
```

## set-password
變更帳戶的密碼。
 * 輸入
```
struct SetPasswordRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var accountIdentifier: AccountIdentifier
  var newPassword: String?
}
```
 * 輸出
```
struct SetPasswordResponse {
}
```

## delete-account
  * 輸入：
```
struct DeleteAccountRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var accountIdentifier: AccountIdentifier
}
```
  * 輸出：
```
struct DeleteAccountResponse {
}
```

## add-account
  * 輸入：
```
struct AddAccountRequest {
  var header: RequestHeader

  var userAccountID: String?
  var token: String?
  var userName: String
  var accountName: String
  var password: String?  // 如果 HandshakeResponse 指示不允許設定密碼，則省略此欄位；密碼管理器應在此情況下指派隨機密碼（這是 1password 的運作方式）。
}
```
  * 輸出：
```
struct AddAccountResponse {
  var accountIdentifier: AccountIdentifier
}
```

# 錯誤處理

如果發生錯誤，任何命令都可以傳回此結構的執行個體，而不是文件中記錄的輸出 JSON 文件：
```
struct ErrorResponse {
  var error: String
}
```

# 範例用法

```
% echo '{"header": { "pathToDatabase": "/Users/george/passwords.db", "pathToExecutable": "/opt/homebrew/bin/SomePasswordManagerCLI", mode: "terminal" }, "token": "secret goes here", "accountIdentifier": { "accountID": "123-456" } }' | pwmplugin get-password
{ "password": "Hunter2" }
```
