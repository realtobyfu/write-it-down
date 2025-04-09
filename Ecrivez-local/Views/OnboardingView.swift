//
//  OnboardingView.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/9/25.
//

// Create a new SwiftUI view called OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    // Sample demo note with formatted text
    @State private var demoNote = NSAttributedString(string: "My Great Idea", attributes: [
        .font: UIFont.systemFont(ofSize: 24, weight: .bold),
        .foregroundColor: UIColor.blue
    ])
    
    // Demo states
    @State private var showCategoryDemo = false
    @State private var showFormattingToolbar = false
    @State private var demoLocation: String? = "San Francisco"
    
    var body: some View {
        VStack {
            // Progress dots
            HStack {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 20)
            
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    showOnboarding = false
                }
                .padding()
            }
            
            // Content pages
            TabView(selection: $currentPage) {
                // Welcome Page
                welcomePage
                    .tag(0)
                
                // Categories Demo Page
                categoriesDemoPage
                    .tag(1)
                
                // Rich Text Editing Demo
                richTextDemoPage
                    .tag(2)
                
                // Final Page with Location and Sharing
                finalFeaturePage
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .padding()
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(currentPage == 3 ? "Get Started" : "Next") {
                    withAnimation {
                        if currentPage == 3 {
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                            showOnboarding = false
                        } else {
                            currentPage += 1
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
    
    // MARK: - Individual Pages
    
    var welcomePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .padding()
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 150, height: 150)
                )
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 150, height: 150)
                        
                        // Animated dots surrounding the main icon
                        ForEach(0..<8) { i in
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 10, height: 10)
                                .offset(x: 85 * cos(Double(i) * .pi / 4),
                                        y: 85 * sin(Double(i) * .pi / 4))
                                .opacity(0.7)
                        }
                    }
                )
                .padding(.bottom, 20)
            
            Text("Where Ideas Take Root")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("Write-It-Down helps you capture, organize, and develop your ideas before they fade away")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
            
            Text("Swipe to explore the features")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 40)
        }
        .padding()
    }
    
    var categoriesDemoPage: some View {
        VStack(spacing: 20) {
            Text("Organize with Categories")
                .font(.title)
                .bold()
                .padding(.bottom, 10)
            
            // Interactive category demo
            VStack(spacing: 15) {
                Text("Tap to see category selection")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                // Demo of the category bubbles
                Button(action: {
                    withAnimation(.spring()) {
                        showCategoryDemo.toggle()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 200)
                        
                        VStack {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Tap here")
                                .padding(.top, 8)
                        }
                    }
                }
                
                if showCategoryDemo {
                    // Simulated category bubbles
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(["Ideas", "Work", "Personal", "Travel", "Health"], id: \.self) { category in
                                categoryBubble(name: category, color: categoryColor(for: category))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .frame(height: 80)
                }
            }
            
            Text("Create custom categories with colors and icons to keep your notes organized")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
        }
        .padding()
    }
    
    var richTextDemoPage: some View {
        VStack(spacing: 20) {
            Text("Rich Text Editing")
                .font(.title)
                .bold()
                .padding(.bottom, 10)
            
            VStack {
                // Demo note editor
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 200)
                    
                    if let attributedText = try? NSAttributedString(
                        data: $demoNote.wrappedValue.data(
                            from: NSRange(location: 0, length: $demoNote.wrappedValue.length),
                            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                        ) ?? Data(),
                        options: [.documentType: NSAttributedString.DocumentType.rtf],
                        documentAttributes: nil
                    ) {
                        Text(AttributedString(attributedText))
                            .padding()
                    }
                }
                
                Button(action: {
                    withAnimation {
                        showFormattingToolbar.toggle()
                    }
                }) {
                    Text("Tap to see formatting options")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                if showFormattingToolbar {
                    // Simulated formatting toolbar
                    HStack(spacing: 20) {
                        ForEach(["bold", "italic", "underline", "textformat.size", "photo"], id: \.self) { tool in
                            Button(action: {
                                updateDemoText(tool: tool)
                            }) {
                                Image(systemName: tool)
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            Text("Format your notes with styles, colors, and add images for the perfect capture of your thoughts")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 10)
        }
        .padding()
    }
    
    var finalFeaturePage: some View {
        VStack(spacing: 20) {
            Text("Everything You Need")
                .font(.title)
                .bold()
                .padding(.bottom, 10)
            
            // Location demo
            VStack(alignment: .leading, spacing: 10) {
                Text("Location Tagging")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.red)
                    Text(demoLocation ?? "Add location")
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Sharing demo
            VStack(alignment: .leading, spacing: 10) {
                Text("Share Your Ideas")
                    .font(.headline)
                
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Text("Ready to start capturing brilliance?")
                .font(.headline)
                .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    func categoryBubble(name: String, color: Color) -> some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: categoryIcon(for: name))
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(.caption)
        }
    }
    
    func categoryColor(for name: String) -> Color {
        switch name {
        case "Ideas": return .blue
        case "Work": return .green
        case "Personal": return .purple
        case "Travel": return .orange
        case "Health": return .red
        default: return .gray
        }
    }
    
    func categoryIcon(for name: String) -> String {
        switch name {
        case "Ideas": return "lightbulb.fill"
        case "Work": return "briefcase.fill"
        case "Personal": return "person.fill"
        case "Travel": return "airplane"
        case "Health": return "heart.fill"
        default: return "folder.fill"
        }
    }
    
    func updateDemoText(tool: String) {
        // Simulate format changes to the demo text
        let mutableAttrStr = NSMutableAttributedString(attributedString: demoNote)
        let range = NSRange(location: 0, length: demoNote.length)
        
        switch tool {
        case "bold":
            let font = UIFont.boldSystemFont(ofSize: 24)
            mutableAttrStr.addAttribute(.font, value: font, range: range)
        case "italic":
            let font = UIFont.italicSystemFont(ofSize: 24)
            mutableAttrStr.addAttribute(.font, value: font, range: range)
        case "underline":
            mutableAttrStr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        case "textformat.size":
            // Cycle through some colors
            let colors: [UIColor] = [.blue, .red, .purple, .green]
            let currentColor = mutableAttrStr.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? .blue
            let currentIndex = colors.firstIndex(where: { $0.description == currentColor.description }) ?? 0
            let nextIndex = (currentIndex + 1) % colors.count
            mutableAttrStr.addAttribute(.foregroundColor, value: colors[nextIndex], range: range)
        case "photo":
            // Simulating adding an image - just add an emoji in this demo
            mutableAttrStr.mutableString.append(" 📸")
        default:
            break
        }
        
        demoNote = mutableAttrStr
    }
}
