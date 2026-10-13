在此頁面中，你可以編輯各項 AI 功能所使用的提示詞。

## 編輯 > 啟用人工智慧

當你呼叫選單項目**編輯 > 啟用人工智慧**（⌘Y）時會使用此提示詞。它會取目前正在編輯的文字，並將其替換為一條終端機命令。這段文字可能位於 shell 提示字元（前提是你已安裝 Shell 整合）、撰寫器（Composer）中，或 App 內各處的文字方塊中。

例如，你可以開啟撰寫器（⇧⌘.）並輸入 `Remove files whose name contains a vowel`，然後選擇「啟用人工智慧」，它會把你的表述改寫為 `rm *[aeiou]*`。

其語法遵循[插值字串](https://iterm2.com/documentation-scripting-fundamentals.html#:~:text=References%2C%20below.-,Interpolated%20Strings,-Another%20way%20that)。`shell` 和 `uname` 變數始終有定義，它們基於對目前工作階段中這些設定的最佳推測。如果你使用了 SSH 整合，它們對遠端主機也應當是正確的。這樣做是為了讓回答能針對你正在使用的系統量身訂製。提示詞的形式是一段 shell 指令碼，這是說服 ChatGPT 撰寫命令的好方法。`\(ai.prompt)` 僅在 AI 上下文中求值插值字串時可用，它的值就是你在撰寫器中輸入的內容。

## AI 對話

AI 對話針對不同功能組合提供了大量提示詞。

AI 對話可以與終端機工作階段及網頁瀏覽器工作階段關聯，前提是 AI 供應商支援函式呼叫（function calling）。如果供應商不支援函式呼叫（也稱為「工具使用」），則只有 `AI Chat (no function calling)` 會生效。

如果你把 `Act in Web Browser`（在網頁瀏覽器中操作）對話權限設為 `Never Allow`（從不允許），則包含 `Browser Access`（瀏覽器存取）的提示詞不會被使用。

如果 `Run Commands`（執行命令）和 `Control Terminal`（控制終端機）都設為 `Never`（從不），則包含 `Full Terminal`（完全終端機）的提示詞不會被使用。

如果所有與終端機相關的權限都設為 `Never`（從不），則 `Full Terminal` 和 `Read-Only Terminal`（唯讀終端機）提示詞都不會被使用。

透過逐一排除，你可以確定哪種提示詞適用於你的情況。

## 程式碼審查系統提示詞

當工作區中有一個具有「程式碼審查」角色的成員時，此提示詞會放入系統訊息中，告訴代理如何把它的發現更新到 iTerm2 中。

## 對話列表圖示

此提示詞讓 AI 在為某個對話選定標題後立即為其繪製一個 SVG 圖示。該圖示會被點陣化並顯示在對話列表中對話名稱的旁邊。語法遵循插值字串，其中 `\(ai.subject)` 的值為對話的標題。回應必須包含一個 SVG 文件；其周圍的內容會被忽略，如果找不到可渲染的 SVG，對話將保留預設圖示。
