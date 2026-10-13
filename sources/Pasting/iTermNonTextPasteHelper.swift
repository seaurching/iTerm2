//
//  iTermNonTextPasteHelper.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 3/9/26.
//

import AppKit
import UniformTypeIdentifiers

@objc(iTermNonTextPasteHelperDelegate)
protocol iTermNonTextPasteHelperDelegate: AnyObject {
    func nonTextPasteHelper(_ sender: iTermNonTextPasteHelper, pasteString string: String)
    func nonTextPasteHelperWindow(_ sender: iTermNonTextPasteHelper) -> NSWindow?
    func nonTextPasteHelperCanUpload(_ sender: iTermNonTextPasteHelper) -> Bool
    func nonTextPasteHelper(_ sender: iTermNonTextPasteHelper, uploadFiles paths: [String])
    func nonTextPasteHelper(_ sender: iTermNonTextPasteHelper, uploadFileAndPastePath path: String)
}

@objc(iTermNonTextPasteHelper)
class iTermNonTextPasteHelper: NSObject {
    @objc weak var delegate: iTermNonTextPasteHelperDelegate?

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    @objc static func pasteboardHasNonTextContent() -> Bool {
        let pb = NSPasteboard.general
        return pb.hasFileURLs() || pb.hasRawImageData()
    }

    @objc func pasteNonTextContent() -> Bool {
        DLog("pasteNonTextContent called")
        let pb = NSPasteboard.general
        if pb.hasFileURLs() {
            guard let paths = pb.filePaths(), !paths.isEmpty else {
                RLog("hasFileURLs but no paths found")
                return false
            }
            RLog("Handling file paste with \(paths.count) paths")
            return handleFilePaste(paths)
        } else if pb.hasRawImageData() {
            guard let imageData = pb.rawImageData() else {
                RLog("hasRawImageData but rawImageData() returned nil")
                return false
            }
            // Try to determine the file extension, but proceed even if we can't
            var fileExtension: String? = nil
            if let utType = pb.rawImageDataUTType(),
               let type = UTType(utType) {
                fileExtension = type.preferredFilenameExtension
            }
            RLog("Handling image data paste: \(imageData.count) bytes, extension=\(fileExtension ?? "unknown")")
            return handleImageDataPaste(imageData: imageData, fileExtension: fileExtension)
        }
        DLog("No non-text content found on pasteboard")
        return false
    }

    @objc func showPasteOptionsForFiles(_ files: [String]) {
        _ = handleFilePaste(files)
    }

    private enum FilePasteAction: String {
        case pastePath = "Paste Path"
        case pastePaths = "Paste Paths"
        case pasteBase64 = "Paste Base64-Encoded Contents"
        case pasteBase64Archive = "Paste Base64-Encoded Archive (tar.gz)"
        case pasteAsText = "Paste as Text"
        case upload = "Upload"
        case uploadAndPastePath = "Upload and Paste Path"
        case cancel = "Cancel"

        var localizedLabel: String {
            return NSLocalizedString(rawValue, tableName: "Pasting", comment: "Pasting: \(rawValue) action")
        }
    }

    private func handleFilePaste(_ paths: [String]) -> Bool {
        guard !paths.isEmpty else {
            return false
        }

        // Verify files exist
        let existingPaths = paths.filter { FileManager.default.fileExists(atPath: $0) }
        if existingPaths.isEmpty {
            showError(NSLocalizedString("The copied file no longer exists.", tableName: "Pasting", comment: "Pasting: copied file gone error"))
            return true
        }
        if existingPaths.count < paths.count {
            let missing = paths.count - existingPaths.count
            showError(String(format: NSLocalizedString("%d of %d files no longer exist. Proceeding with remaining files.", tableName: "Pasting", comment: "Pasting: some files gone error"), missing, paths.count))
        }

        let singleFile = existingPaths.count == 1
        let canUpload = delegate?.nonTextPasteHelperCanUpload(self) ?? false
        let isDirectory = singleFile && isDirectoryPath(existingPaths.first!)
        let canPasteAsText = singleFile && !isDirectory && firstFileIsValidUTF8(existingPaths)

        RLog("handleFilePaste: singleFile=\(singleFile) canUpload=\(canUpload) isDirectory=\(isDirectory) canPasteAsText=\(canPasteAsText)")

        // Build actions list and track what each index means
        var actions = [FilePasteAction]()
        if singleFile {
            if canUpload {
                // Remote host: offer upload options and base64
                if !isDirectory {
                    actions.append(.uploadAndPastePath)
                }
                actions.append(.upload)
                if isDirectory {
                    actions.append(.pasteBase64Archive)
                } else {
                    actions.append(.pasteBase64)
                }
            } else {
                // Local host: offer path and base64 options
                actions.append(.pastePath)
                if isDirectory {
                    actions.append(.pasteBase64Archive)
                } else {
                    actions.append(.pasteBase64)
                    if canPasteAsText {
                        actions.append(.pasteAsText)
                    }
                }
            }
        } else {
            // Multiple files
            if canUpload {
                actions.append(.upload)
            }
            actions.append(.pastePaths)
        }
        actions.append(.cancel)

        DLog("handleFilePaste: actions=\(actions.map { $0.rawValue })")

        // Build description of files for the dialog
        let fileDescription = descriptionForFiles(existingPaths, isDirectory: isDirectory)

        let warning = iTermWarning()
        warning.title = String(format: NSLocalizedString("How would you like to paste %@?", tableName: "Pasting", comment: "Pasting: file paste warning title"), fileDescription)
        warning.actionLabels = actions.map { $0.localizedLabel }
        warning.identifier = singleFile ? "NoSyncPasteNonTextFile" : "NoSyncPasteNonTextFiles"
        warning.warningType = .kiTermWarningTypePermanentlySilenceable
        warning.heading = isDirectory ? NSLocalizedString("Paste Folder", tableName: "Pasting", comment: "Pasting: paste folder heading") : (singleFile ? NSLocalizedString("Paste File", tableName: "Pasting", comment: "Pasting: paste file heading") : NSLocalizedString("Paste Files", tableName: "Pasting", comment: "Pasting: paste files heading"))
        warning.cancelLabel = FilePasteAction.cancel.localizedLabel
        warning.window = delegate?.nonTextPasteHelperWindow(self)

        warning.runModalAsync { [weak self] selection, _ in
            guard let self = self else {
                DLog("handleFilePaste: self was deallocated")
                return
            }
            let index = self.selectionToIndex(selection)
            RLog("handleFilePaste: user selected index \(index)")
            guard index >= 0 && index < actions.count else {
                RLog("handleFilePaste: invalid selection index")
                return
            }

            switch actions[index] {
            case .pastePath:
                DLog("handleFilePaste: pastePath")
                self.delegate?.nonTextPasteHelper(self, pasteString: existingPaths.first!.quotedStringForPaste())
            case .pastePaths:
                DLog("handleFilePaste: pastePaths")
                let escapedPaths = existingPaths.map { $0.quotedStringForPaste() }.joined(separator: " ")
                self.delegate?.nonTextPasteHelper(self, pasteString: escapedPaths)
            case .pasteBase64:
                DLog("handleFilePaste: pasteBase64")
                self.pasteBase64EncodedContents(of: existingPaths.first!)
            case .pasteBase64Archive:
                DLog("handleFilePaste: pasteBase64Archive")
                self.pasteBase64EncodedArchive(of: existingPaths.first!)
            case .pasteAsText:
                DLog("handleFilePaste: pasteAsText")
                self.pasteFileAsText(existingPaths.first!)
            case .upload:
                DLog("handleFilePaste: upload")
                self.delegate?.nonTextPasteHelper(self, uploadFiles: existingPaths)
            case .uploadAndPastePath:
                DLog("handleFilePaste: uploadAndPastePath")
                self.delegate?.nonTextPasteHelper(self, uploadFileAndPastePath: existingPaths.first!)
            case .cancel:
                DLog("handleFilePaste: cancelled")
                break
            }
        }
        return true
    }

    private func descriptionForFiles(_ paths: [String], isDirectory: Bool = false) -> String {
        if paths.count == 1 {
            let filename = (paths.first! as NSString).lastPathComponent
            let prefix = isDirectory ? NSLocalizedString(" the folder ", tableName: "Pasting", comment: "Pasting: folder prefix fragment") : ""
            return prefix + "\u{201C}" + filename + "\u{201D}"
        } else if paths.count <= 3 {
            let filenames = paths.map { "\u{201C}\(($0 as NSString).lastPathComponent)\u{201D}" }
            return filenames.joined(separator: ", ")
        } else {
            let first = (paths.first! as NSString).lastPathComponent
            return String(format: NSLocalizedString("“%@” and %d other files", tableName: "Pasting", comment: "Pasting: multiple files description"), first, paths.count - 1)
        }
    }

    private func isDirectoryPath(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    private func selectionToIndex(_ selection: iTermWarningSelection) -> Int {
        switch selection {
        case .kiTermWarningSelection0: return 0
        case .kiTermWarningSelection1: return 1
        case .kiTermWarningSelection2: return 2
        case .kiTermWarningSelection3: return 3
        case .kiTermWarningSelection4: return 4
        case .kiTermWarningSelection5: return 5
        case .kiTermWarningSelection6: return 6
        default: return -1
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Paste Failed", tableName: "Pasting", comment: "Pasting: paste failed alert title")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", tableName: "Pasting", comment: "Pasting: paste failed OK button"))
        if let window = delegate?.nonTextPasteHelperWindow(self) {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    private enum ImagePasteAction: String {
        case saveTempAndPastePath = "Save to Temp File and Paste Path"
        case pasteBase64 = "Paste Base64-Encoded Contents"
        case upload = "Upload"
        case uploadAndPastePath = "Upload and Paste Path"
        case cancel = "Cancel"

        var localizedLabel: String {
            return NSLocalizedString(rawValue, tableName: "Pasting", comment: "Pasting: \(rawValue) action")
        }
    }

    private func handleImageDataPaste(imageData: Data, fileExtension: String?) -> Bool {
        DLog("handleImageDataPaste: \(imageData.count) bytes, extension=\(fileExtension ?? "nil")")
        let canUpload = delegate?.nonTextPasteHelperCanUpload(self) ?? false
        let sizeDescription = ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)
        let typeDescription = fileExtension.map { imageTypeDescription($0) } ?? NSLocalizedString("some", tableName: "Pasting", comment: "Pasting: unknown image type fallback")

        DLog("handleImageDataPaste: canUpload=\(canUpload)")

        // Build actions based on whether we can upload and whether we know the file type
        var actions = [ImagePasteAction]()
        if fileExtension != nil {
            if canUpload {
                actions.append(.uploadAndPastePath)
                actions.append(.upload)
            } else {
                actions.append(.saveTempAndPastePath)
            }
        }
        actions.append(.pasteBase64)
        actions.append(.cancel)

        DLog("handleImageDataPaste: actions=\(actions.map { $0.rawValue })")

        let warning = iTermWarning()
        warning.title = String(format: NSLocalizedString("The clipboard contains %1$@ image data (%2$@). How would you like to paste it?", tableName: "Pasting", comment: "Pasting: image paste warning title"), typeDescription, sizeDescription)
        warning.actionLabels = actions.map { $0.localizedLabel }
        warning.identifier = canUpload ? "NoSyncPasteImageDataRemote" : "NoSyncPasteImageData"
        warning.warningType = .kiTermWarningTypePermanentlySilenceable
        warning.heading = NSLocalizedString("Paste Image", tableName: "Pasting", comment: "Pasting: paste image heading")
        warning.cancelLabel = ImagePasteAction.cancel.localizedLabel
        warning.window = delegate?.nonTextPasteHelperWindow(self)

        warning.runModalAsync { [weak self] selection, _ in
            guard let self = self else {
                DLog("handleImageDataPaste: self was deallocated")
                return
            }
            let index = self.selectionToIndex(selection)
            RLog("handleImageDataPaste: user selected index \(index)")
            guard index >= 0 && index < actions.count else {
                RLog("handleImageDataPaste: invalid selection index")
                return
            }

            switch actions[index] {
            case .saveTempAndPastePath:
                DLog("handleImageDataPaste: saveTempAndPastePath")
                self.saveTempFileAndPastePath(imageData: imageData, fileExtension: fileExtension!)
            case .pasteBase64:
                DLog("handleImageDataPaste: pasteBase64")
                let base64 = (imageData as NSData).stringWithBase64Encoding(withLineBreak: "\r")
                self.pasteBase64WithConfirmationIfNeeded(base64)
            case .upload:
                DLog("handleImageDataPaste: upload")
                self.uploadImageData(imageData, fileExtension: fileExtension!, pastePath: false)
            case .uploadAndPastePath:
                DLog("handleImageDataPaste: uploadAndPastePath")
                self.uploadImageData(imageData, fileExtension: fileExtension!, pastePath: true)
            case .cancel:
                DLog("handleImageDataPaste: cancelled")
                break
            }
        }
        return true
    }

    private func uploadImageData(_ imageData: Data, fileExtension: String, pastePath: Bool) {
        DLog("uploadImageData: \(imageData.count) bytes, extension=\(fileExtension), pastePath=\(pastePath)")
        guard let tempPath = saveImageToTempFile(imageData: imageData, fileExtension: fileExtension) else {
            RLog("uploadImageData: failed to save temp file")
            return
        }
        if pastePath {
            DLog("uploadImageData: calling delegate uploadFileAndPastePath")
            delegate?.nonTextPasteHelper(self, uploadFileAndPastePath: tempPath)
        } else {
            DLog("uploadImageData: calling delegate uploadFiles")
            delegate?.nonTextPasteHelper(self, uploadFiles: [tempPath])
        }
    }

    private func saveImageToTempFile(imageData: Data, fileExtension: String) -> String? {
        DLog("saveImageToTempFile: \(imageData.count) bytes, extension=\(fileExtension)")
        guard let tempDir = FileManager.default.it_temporaryDirectory() else {
            RLog("saveImageToTempFile: failed to get temporary directory")
            showError(NSLocalizedString("Could not create temporary directory.", tableName: "Pasting", comment: "Pasting: temp dir error"))
            return nil
        }

        let timestamp = Self.timestampFormatter.string(from: Date())
        let filename = "pasted-image-\(timestamp).\(fileExtension)"
        let tempPath = (tempDir as NSString).appendingPathComponent(filename)

        do {
            try imageData.write(to: URL(fileURLWithPath: tempPath))
            DLog("saveImageToTempFile: saved to \(tempPath)")
            return tempPath
        } catch {
            RLog("saveImageToTempFile: failed to write: \(error)")
            showError(String(format: NSLocalizedString("Could not save image to temporary file: %@", tableName: "Pasting", comment: "Pasting: save image error"), error.localizedDescription))
            return nil
        }
    }

    private func imageTypeDescription(_ fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "png": return NSLocalizedString("a PNG", tableName: "Pasting", comment: "Pasting: PNG image type")
        case "jpg", "jpeg": return NSLocalizedString("a JPEG", tableName: "Pasting", comment: "Pasting: JPEG image type")
        case "gif": return NSLocalizedString("a GIF", tableName: "Pasting", comment: "Pasting: GIF image type")
        case "tiff", "tif": return NSLocalizedString("a TIFF", tableName: "Pasting", comment: "Pasting: TIFF image type")
        case "bmp": return NSLocalizedString("a BMP", tableName: "Pasting", comment: "Pasting: BMP image type")
        case "webp": return NSLocalizedString("a WebP", tableName: "Pasting", comment: "Pasting: WebP image type")
        case "heic": return NSLocalizedString("a HEIC", tableName: "Pasting", comment: "Pasting: HEIC image type")
        default: return NSLocalizedString("an", tableName: "Pasting", comment: "Pasting: unknown image type article")
        }
    }

    private func firstFileIsValidUTF8(_ paths: [String]) -> Bool {
        guard let firstPath = paths.first,
              let data = FileManager.default.contents(atPath: firstPath) else {
            return false
        }
        return String(data: data, encoding: .utf8) != nil
    }

    private func pasteBase64EncodedContents(of path: String) {
        DLog("pasteBase64EncodedContents: \(path)")
        guard let data = FileManager.default.contents(atPath: path) else {
            RLog("pasteBase64EncodedContents: failed to read file")
            let filename = (path as NSString).lastPathComponent
            showError(String(format: NSLocalizedString("Could not read file “%@”.", tableName: "Pasting", comment: "Pasting: read file error"), filename))
            return
        }
        DLog("pasteBase64EncodedContents: read \(data.count) bytes")
        let base64 = (data as NSData).stringWithBase64Encoding(withLineBreak: "\r")
        pasteBase64WithConfirmationIfNeeded(base64)
    }

    private func pasteBase64EncodedArchive(of folderPath: String) {
        DLog("pasteBase64EncodedArchive: \(folderPath)")
        let folderName = (folderPath as NSString).lastPathComponent
        let parentPath = (folderPath as NSString).deletingLastPathComponent

        do {
            // Create archive with just the folder name, relative to parent
            let data = try NSData(tgzContainingFiles: [folderName],
                                  relativeToPath: parentPath,
                                  includeExtendedAttrs: false)
            DLog("pasteBase64EncodedArchive: created archive of \(data.count) bytes")
            let base64 = data.stringWithBase64Encoding(withLineBreak: "\r")
            pasteBase64WithConfirmationIfNeeded(base64)
        } catch {
            RLog("pasteBase64EncodedArchive: failed to create archive: \(error)")
            showError(String(format: NSLocalizedString("Could not create archive of “%@”: %@", tableName: "Pasting", comment: "Pasting: archive error"), folderName, error.localizedDescription))
        }
    }

    private func pasteBase64WithConfirmationIfNeeded(_ base64: String) {
        let threshold = 10_000
        if base64.count <= threshold {
            delegate?.nonTextPasteHelper(self, pasteString:base64)
            return
        }

        let warning = iTermWarning()
        warning.title = String(format: NSLocalizedString("OK to paste %@ bytes of base64-encoded data?", tableName: "Pasting", comment: "Pasting: large base64 warning title"), base64.count.formatted())
        warning.actionLabels = [NSLocalizedString("OK", tableName: "Pasting", comment: "Pasting: large base64 OK button"), NSLocalizedString("Cancel", tableName: "Pasting", comment: "Pasting: large base64 cancel button")]
        warning.identifier = "NoSyncPasteLargeBase64"
        warning.warningType = .kiTermWarningTypePermanentlySilenceable
        warning.heading = NSLocalizedString("Large Paste", tableName: "Pasting", comment: "Pasting: large paste heading")
        warning.cancelLabel = NSLocalizedString("Cancel", tableName: "Pasting", comment: "Pasting: large base64 cancel label")
        warning.window = delegate?.nonTextPasteHelperWindow(self)

        warning.runModalAsync { [weak self] selection, _ in
            guard let self = self else { return }
            if selection == .kiTermWarningSelection0 {
                self.delegate?.nonTextPasteHelper(self, pasteString: base64)
            }
        }
    }

    private func pasteFileAsText(_ path: String) {
        let filename = (path as NSString).lastPathComponent
        guard let data = FileManager.default.contents(atPath: path) else {
            showError(String(format: NSLocalizedString("Could not read file “%@”.", tableName: "Pasting", comment: "Pasting: read file error"), filename))
            return
        }
        guard let text = String(data: data, encoding: .utf8) else {
            showError(String(format: NSLocalizedString("File “%@” is not valid UTF-8 text.", tableName: "Pasting", comment: "Pasting: not utf8 error"), filename))
            return
        }
        delegate?.nonTextPasteHelper(self, pasteString: text)
    }

    private func saveTempFileAndPastePath(imageData: Data, fileExtension: String) {
        DLog("saveTempFileAndPastePath: \(imageData.count) bytes, extension=\(fileExtension)")
        guard let tempPath = saveImageToTempFile(imageData: imageData, fileExtension: fileExtension) else {
            DLog("saveTempFileAndPastePath: failed to save temp file")
            return
        }
        let escapedPath = tempPath.quotedStringForPaste()
        DLog("saveTempFileAndPastePath: pasting path \(escapedPath)")
        delegate?.nonTextPasteHelper(self, pasteString: escapedPath)
    }
}
