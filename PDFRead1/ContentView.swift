//
//  ContentView.swift
//  PDFRead1
//
//  Created by Shravya Nayani on 4/19/25.
//

import SwiftUI
import PDFKit
import AVFoundation
import UniformTypeIdentifiers
import WebKit

struct ContentView: View {
    @StateObject private var pdfViewModel = PDFViewModel()
    @State private var showDonationDialog = false
    @State private var excludeText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("PDF Voice Reader")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button(action: {
                pdfViewModel.showDocumentPicker = true
            }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Select PDF File")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .sheet(isPresented: $pdfViewModel.showDocumentPicker) {
                DocumentPicker(pdfURL: $pdfViewModel.pdfURL, pdfFileName: $pdfViewModel.pdfFileName)
            }
            
            if !pdfViewModel.pdfFileName.isEmpty {
                Text("Selected file: \(pdfViewModel.pdfFileName)")
                    .font(.subheadline)
            }
            
            HStack {
                Text("Page #")
                TextField("1", text: $pdfViewModel.pageNumberText)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: pdfViewModel.pageNumberText) { newValue in
                        if let pageNumber = Int(newValue), pageNumber > 0 {
                            pdfViewModel.currentPage = pageNumber - 1
                        }
                    }
                
                Text("Reading Speed")
                Picker("", selection: $pdfViewModel.selectedRate) {
                    ForEach(pdfViewModel.availableRates, id: \.self) { rate in
                        Text("\(rate, specifier: "%.2f")x").tag(rate)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: pdfViewModel.selectedRate) { newValue in
                    pdfViewModel.updateSpeechRate(newValue)
                }
            }
            
             
            HStack {
                
                Button(action: {
                    pdfViewModel.readPDF()
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Read PDF")
                    }
                    .padding()
                    .background(pdfViewModel.pdfURL != nil ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(pdfViewModel.pdfURL == nil)
                
                Button(action: {
                    pdfViewModel.togglePlayPause()
                }) {
                    HStack {
                        Image(systemName: pdfViewModel.isPlaying ? "pause.fill" : "play.fill")
                        Text(pdfViewModel.isPlaying ? "Pause" : "Play")
                    }
                    .padding()
                    .background(pdfViewModel.pdfURL != nil ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(pdfViewModel.pdfURL == nil)
            }
           
            HStack {
                
            }
            
            HStack(spacing: 20) {
                
                Button(action: {
                    pdfViewModel.previousPage()
                }) {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Previous Page")
                    }
                    .padding()
                    .background(pdfViewModel.hasPreviousPage ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!pdfViewModel.hasPreviousPage)
                
                Button(action: {
                    pdfViewModel.nextPage()
                }) {
                    HStack {
                        Image(systemName: "arrow.forward")
                        Text("Next Page")
                    }
                    .padding()
                    .background(pdfViewModel.hasNextPage ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!pdfViewModel.hasNextPage)
            }
            
             

            VStack(alignment: .leading) {
                Text("Exclude Text:")
                    .font(.headline)
                
                HStack {
                    TextField("Text to exclude", text: $excludeText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !excludeText.isEmpty {
                            pdfViewModel.addExcludeText(excludeText)
                            excludeText = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack {
                        ForEach(pdfViewModel.excludedTexts, id: \.self) { text in
                            HStack {
                                Text(text)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Button(action: {
                                    pdfViewModel.removeExcludeText(text)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status bar at the bottom of the screen
            HStack {
                Text(pdfViewModel.statusMessage)
                    .foregroundColor(pdfViewModel.isError ? .red : .green)
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .onAppear {
            pdfViewModel.loadExcludedTexts()
            checkAndShowDonationDialog()
        }
        .alert(isPresented: $showDonationDialog) {
            Alert(
                title: Text("Please donate to support this ad-free app"),
                message: Text("Thank you for using our ad-free app! We are committed to providing a completely ad-free experience. To maintain and improve the quality of our services, we rely on the support of users like you. If you find this app valuable, please consider making a voluntary contribution. \n\nYour donation, regardless of size, helps us continue development and ensures the app remains free for everyone. \n\nWe request your donation once every 30 days, and we will never charge you or show ads."),
                primaryButton: .default(Text("Donate")) {
                    pdfViewModel.openPayPalDonation()
                },
                secondaryButton: .cancel(Text("Maybe Later")) {
                    saveDonationDialogDate()
                }
            )
        }
    }
    
    private func checkAndShowDonationDialog() {
        let defaults = UserDefaults.standard
        let lastShownKey = "lastDonationDialogShown"
        
        if let lastShown = defaults.object(forKey: lastShownKey) as? Date {
            let calendar = Calendar.current
            if let daysSinceLastShown = calendar.dateComponents([.day], from: lastShown, to: Date()).day, daysSinceLastShown >= 30 {
                showDonationDialog = true
            }
        } else {
            // First time showing
            showDonationDialog = true
        }
    }
    
    private func saveDonationDialogDate() {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: "lastDonationDialogShown")
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var pdfURL: URL?
    @Binding var pdfFileName: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        
        // Request access to the document
        picker.shouldShowFileExtensions = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                // Create a copy in the app's documents directory for persistent access
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                
                // Remove any existing file
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // Copy the file
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                // Update the view model with the local URL
                DispatchQueue.main.async {
                    self.parent.pdfURL = destinationURL
                    self.parent.pdfFileName = url.lastPathComponent
                }
            } catch {
                print("Error copying file: \(error.localizedDescription)")
                
                // If copying fails, try to use the original URL directly
                DispatchQueue.main.async {
                    // Create a bookmark for persistent access
                    do {
                        let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                        UserDefaults.standard.set(bookmarkData, forKey: "pdfBookmark")
                        
                        self.parent.pdfURL = url
                        self.parent.pdfFileName = url.lastPathComponent
                    } catch {
                        print("Failed to create bookmark: \(error.localizedDescription)")
                    }
                }
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PayPalWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class PDFViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var pdfURL: URL?
    @Published var pdfFileName = ""
    @Published var pageNumberText = "1"
    @Published var currentPage = 0
    @Published var isPlaying = false
    @Published var showDocumentPicker = false
    @Published var excludedTexts: [String] = []
    @Published var selectedRate: Float = 1.0
    @Published var showPayPalView = false
    @Published var statusMessage = ""
    @Published var isError = false
    
    var availableRates: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0]
    
    private var pdfDocument: PDFDocument?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var shouldContinueToNextPage = true
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    var hasPreviousPage: Bool {
        guard let pdfDocument = pdfDocument else { return false }
        return currentPage > 0
    }
    
    var hasNextPage: Bool {
        guard let pdfDocument = pdfDocument else { return false }
        return currentPage < pdfDocument.pageCount - 1
    }
    
    func readPDF() {
        guard let url = pdfURL else { 
            updateStatus("No PDF file selected", isError: true)
            return 
        }
        
        // Check if we need to restore security-scoped resource access
        var didStartAccessing = false
        if !url.isFileURL || !FileManager.default.fileExists(atPath: url.path) {
            // Try to resolve from bookmark if needed
            if let bookmarkData = UserDefaults.standard.data(forKey: "pdfBookmark") {
                do {
                    var isStale = false
                    let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, 
                                             options: .withoutUI, 
                                             relativeTo: nil, 
                                             bookmarkDataIsStale: &isStale)
                    
                    if isStale {
                        updateStatus("PDF bookmark is stale, please select the file again", isError: true)
                        return
                    }
                    
                    // Start accessing the security-scoped resource
                    didStartAccessing = resolvedURL.startAccessingSecurityScopedResource()
                    
                    // Update the URL to the resolved one
                    pdfURL = resolvedURL
                } catch {
                    updateStatus("Failed to access PDF file: \(error.localizedDescription)", isError: true)
                    return
                }
            }
        }
        
        // Create PDF document with proper security options
        let pdfDoc = PDFDocument(url: url)
        
        // Stop accessing the security-scoped resource if needed
        if didStartAccessing {
            url.stopAccessingSecurityScopedResource()
        }
        
        if pdfDoc == nil {
            updateStatus("Failed to load PDF document. The file may be corrupted or password-protected.", isError: true)
            return
        }
        
        self.pdfDocument = pdfDoc
        
        if let pageNumber = Int(pageNumberText), pageNumber > 0 && pageNumber <= pdfDocument?.pageCount ?? 0 {
            currentPage = pageNumber - 1
        } else {
            currentPage = 0
            pageNumberText = "1"
            updateStatus("Invalid page number. Starting from page 1", isError: true)
        }
        
        updateStatus("Successfully loaded PDF with \(pdfDocument?.pageCount ?? 0) pages", isError: false)
        readCurrentPage()
    }
    
    func readCurrentPage() {
        print("-------in readCurrentPage pdfDocument.pageCount \(currentPage)")
        guard let pdfDocument = pdfDocument, currentPage < pdfDocument.pageCount else { 
            updateStatus("Invalid page number or no PDF loaded", isError: true)
            return 
        }
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        guard let page = pdfDocument.page(at: currentPage) else { 
            updateStatus("Failed to load page \(currentPage + 1)", isError: true)
            return 
        }
        
        // Extract text from the PDF page
        var pageText = page.string ?? "Empty on purpose"
        
        
        // If still empty, show an error
        if pageText.isEmpty {
            print("No text found on page \(currentPage + 1)")
            pageText = "No readable text found on this page."
            updateStatus("No readable text found on page \(currentPage + 1)", isError: true)
        } else {
            updateStatus("Reading page \(currentPage + 1) of \(pdfDocument.pageCount)", isError: false)
        }
        
        print("-------in readCurrentPage pageText =  \(pageText)")
        
        // Filter out excluded texts
        for excludedText in excludedTexts {
            pageText = pageText.replacingOccurrences(of: excludedText, with: "")
        }
        
        // Create and configure the utterance
        let utterance = AVSpeechUtterance(string: pageText)
        utterance.rate = selectedRate * AVSpeechUtteranceDefaultSpeechRate
        
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Set pitch and volume for better speech quality
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        currentUtterance = utterance
        speechSynthesizer.speak(utterance)
        isPlaying = true
        shouldContinueToNextPage = true
        
        print("Reading page \(currentPage + 1) with \(pageText.count) characters")
    }
    
    func togglePlayPause() {
        if isPlaying {
            speechSynthesizer.pauseSpeaking(at: .word)
            isPlaying = false
            shouldContinueToNextPage = false
            updateStatus("Paused reading at page \(currentPage + 1)", isError: false)
        } else {
            if speechSynthesizer.isPaused {
                speechSynthesizer.continueSpeaking()
                isPlaying = true
                shouldContinueToNextPage = true
                updateStatus("Resumed reading from page \(currentPage + 1)", isError: false)
            } else {
                readCurrentPage()
            }
        }
    }
    
    func nextPage() {
        guard hasNextPage else { 
            updateStatus("Already at the last page", isError: true)
            return 
        }
        
        currentPage += 1
        pageNumberText = "\(currentPage + 1)"
        readCurrentPage()
    }
    
    func previousPage() {
        guard hasPreviousPage else { 
            updateStatus("Already at the first page", isError: true)
            return 
        }
        
        currentPage -= 1
        pageNumberText = "\(currentPage + 1)"
        readCurrentPage()
    }
    
    func updateSpeechRate(_ rate: Float) {
        if let utterance = currentUtterance, speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            
            let newUtterance = AVSpeechUtterance(string: utterance.speechString)
            newUtterance.rate = rate * AVSpeechUtteranceDefaultSpeechRate
            newUtterance.voice = utterance.voice
            
            currentUtterance = newUtterance
            speechSynthesizer.speak(newUtterance)
            isPlaying = true
        }
    }
    
    func addExcludeText(_ text: String) {
        if !excludedTexts.contains(text) {
            excludedTexts.append(text)
            saveExcludedTexts()
        }
    }
    
    func removeExcludeText(_ text: String) {
        if let index = excludedTexts.firstIndex(of: text) {
            excludedTexts.remove(at: index)
            saveExcludedTexts()
        }
    }
    
    func saveExcludedTexts() {
        UserDefaults.standard.set(excludedTexts, forKey: "excludedTexts")
    }
    
    func loadExcludedTexts() {
        if let savedTexts = UserDefaults.standard.stringArray(forKey: "excludedTexts") {
            excludedTexts = savedTexts
        }
    }
    
    func openPayPalDonation() {
        // Replace with your actual PayPal.Me link or donation page
        if let url = URL(string: "https://www.paypal.com/ncp/payment/YNY9YC96R8LFJ") {
            UIApplication.shared.open(url)
        } else {
            updateStatus("Failed to open donation page", isError: true)
        }
    }
    
    // Helper function to update status messages
    private func updateStatus(_ message: String, isError: Bool) {
        DispatchQueue.main.async {
            self.statusMessage = message
            self.isError = isError
            
            // Auto-clear success messages after 5 seconds
            if !isError {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    // Only clear if it's still the same message
                    if self.statusMessage == message {
                        self.statusMessage = ""
                    }
                }
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Automatically move to the next page if we're at the end of the current page
        if shouldContinueToNextPage && hasNextPage {
            DispatchQueue.main.async {
                self.nextPage()
            }
        } else {
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
