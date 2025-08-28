import SwiftUI
import UIKit

// MARK: - ProgressBar Component
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color(red: 0.0, green: 0.48, blue: 1.0) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)
                    if step < totalSteps - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - WelcomeStep
struct WelcomeStep: View {
    @State private var animateIcon = false
    @State private var showText = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Clean app icon
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0)) // iOS Blue
                    .rotationEffect(.degrees(animateIcon ? 3 : -3))
                    .animation(
                        .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
            }
            
            VStack(spacing: 20) {
                Text("Write-It-Down")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(showText ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.3), value: showText)
                
                Text("Simple. Organized. Yours.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: showText)
                
                VStack(spacing: 12) {
                    Text("Capture your thoughts with beautiful notes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Text("Start free with 10 notes")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Upgrade for unlimited")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    }
                }
                .opacity(showText ? 1 : 0)
                .animation(.easeIn(duration: 0.8).delay(0.7), value: showText)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Core value props
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    Text("Organize")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    Text("Create")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: "icloud.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    Text("Sync")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .opacity(showText ? 1 : 0)
            .animation(.easeIn(duration: 0.8).delay(1.0), value: showText)
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
            showText = true
        }
    }
}

struct FeatureIcon: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - CoreFeaturesDemo
struct CoreFeaturesDemo: View {
    @State private var selectedNote = 0
    @State private var showDemo = false
    
    // Use actual app categories from StyleManager
    private let demoCategories = Array(StyleManager.defaultCategories.prefix(4))
    
    private var demoNotes: [(String, String, Color, String)] {
        let noteTexts = [
            "Reading my favorite novel...",
            "New recipe to try tonight...",
            "Beautiful sunny morning...",
            "Watched an amazing film..."
        ]
        
        return demoCategories.enumerated().map { index, category in
            (
                category.name,
                category.symbol,
                StyleManager.color(from: category.color),
                noteTexts[index]
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Your Notes, Organized")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Start with built-in categories")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                // Demo note cards
                ForEach(0..<demoNotes.count, id: \.self) { index in
                    let note = demoNotes[index]
                    HStack(spacing: 12) {
                        Circle()
                            .fill(note.2)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: note.1)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.0)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(note.3)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .scaleEffect(showDemo ? 1.0 : 0.9)
                    .opacity(showDemo ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: showDemo)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("4 default categories included")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.28))
                    Text("Create custom categories with Premium")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                showDemo = true
            }
        }
    }
}

// MARK: - RichTextEditingDemo
struct RichTextEditingDemo: View {
    @State private var currentStyle = "normal"
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Express Yourself")
                .font(.largeTitle)
                .bold()
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                    if showResult {
                        AttributedTextPreview(attributedText: createDemoText())
                            .padding()
                    } else {
                        Text("Tap the formatting options below")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                HStack(spacing: 20) {
                    FormatButton(icon: "bold", label: "Bold") {
                        currentStyle = "bold"
                        showResult = true
                    }
                    FormatButton(icon: "italic", label: "Italic") {
                        currentStyle = "italic"
                        showResult = true
                    }
                    FormatButton(icon: "textformat.size", label: "Size") {
                        currentStyle = "size"
                        showResult = true
                    }
                    FormatButton(icon: "paintpalette", label: "Color") {
                        currentStyle = "color"
                        showResult = true
                    }
                    FormatButton(icon: "photo", label: "Image") {
                        currentStyle = "image"
                        showResult = true
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            Text("Format your notes with rich text styling, colors, and images")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Spacer()
        }
    }
    
    func createDemoText() -> NSAttributedString {
        let mutableString = NSMutableAttributedString()
        switch currentStyle {
        case "bold":
            mutableString.append(NSAttributedString(
                string: "This text is bold!",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
            ))
        case "italic":
            mutableString.append(NSAttributedString(
                string: "This text is italic!",
                attributes: [
                    .font: UIFont.italicSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
            ))
        case "size":
            mutableString.append(NSAttributedString(
                string: "Big ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 32),
                    .foregroundColor: UIColor.label
                ]
            ))
            mutableString.append(NSAttributedString(
                string: "and ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20),
                    .foregroundColor: UIColor.label
                ]
            ))
            mutableString.append(NSAttributedString(
                string: "small",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
            ))
        case "color":
            mutableString.append(NSAttributedString(
                string: "Colorful ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.systemBlue
                ]
            ))
            mutableString.append(NSAttributedString(
                string: "text!",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.systemPurple
                ]
            ))
        case "image":
            mutableString.append(NSAttributedString(
                string: "Notes with images! 📸",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
            ))
        default:
            mutableString.append(NSAttributedString(string: "Tap a format option"))
        }
        return mutableString
    }
}

struct FormatButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.primary)
        }
    }
}

struct AttributedTextPreview: View {
    let attributedText: NSAttributedString
    
    var body: some View {
        Text(AttributedString(attributedText))
    }
}

// MARK: - LocationAndMetadataDemo
struct LocationAndMetadataDemo: View {
    @State private var showLocation = false
    @State private var showDate = false
    @State private var showWeather = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Add Context")
                .font(.largeTitle)
                .bold()
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.white)
                            )
                        Text("My Travel Memory")
                            .font(.headline)
                        Spacer()
                    }
                    Text("Had an amazing coffee at this little café...")
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        if showLocation {
                            MetadataTag(
                                icon: "mappin",
                                text: "San Francisco, CA",
                                color: .red
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        if showDate {
                            MetadataTag(
                                icon: "calendar",
                                text: "June 20, 2025",
                                color: .blue
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        if showWeather {
                            MetadataTag(
                                icon: "sun.max.fill",
                                text: "Sunny",
                                color: .orange
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                HStack(spacing: 16) {
                    MetadataButton(
                        icon: "location.fill",
                        label: "Location",
                        isActive: showLocation
                    ) {
                        withAnimation(.spring()) {
                            showLocation.toggle()
                        }
                    }
                    MetadataButton(
                        icon: "calendar",
                        label: "Date",
                        isActive: showDate
                    ) {
                        withAnimation(.spring().delay(0.1)) {
                            showDate.toggle()
                        }
                    }
                    MetadataButton(
                        icon: "cloud.sun.fill",
                        label: "Weather",
                        isActive: showWeather
                    ) {
                        withAnimation(.spring().delay(0.2)) {
                            showWeather.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal)
            Text("Tag your notes with location, date, and weather to create rich memories")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { showLocation = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { showDate = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showWeather = true }
            }
        }
    }
}

struct MetadataTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(20)
    }
}

struct MetadataButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : .blue)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isActive ? Color.blue : Color.blue.opacity(0.15))
                    )
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - PublicSharingDemo
struct PublicSharingDemo: View {
    @State private var isPublic = false
    @State private var isAnonymous = false
    @State private var showShared = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Share Your Ideas")
                .font(.largeTitle)
                .bold()
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "quote.bubble.fill")
                                    .foregroundColor(.white)
                            )
                        Text("My Brilliant Idea")
                            .font(.headline)
                        Spacer()
                        if showShared {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .transition(.scale)
                        }
                    }
                    Text("What if we could make the world a better place by...")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isPublic ? Color.blue : Color.clear, lineWidth: 2)
                )
                VStack(spacing: 16) {
                    Toggle(isOn: $isPublic) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            Text("Make Public")
                                .font(.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: isPublic) { _, newValue in
                        withAnimation {
                            showShared = newValue
                            if !newValue {
                                isAnonymous = false
                            }
                        }
                    }
                    if isPublic {
                        Toggle(isOn: $isAnonymous) {
                            HStack {
                                Image(systemName: "person.fill.questionmark")
                                    .foregroundColor(.gray)
                                Text("Post Anonymously")
                                    .font(.body)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .gray))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
                if showShared {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                            Text("Your note will be visible in the public feed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("0")
                                    .font(.caption)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("0")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal)
            Text("Share your notes publicly and connect with others. You can always keep them private or post anonymously.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Spacer()
            Button(action: {}) {
                Text("Start Writing!")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
        }
    }
}

// MARK: - PremiumOverviewStep
struct PremiumOverviewStep: View {
    @State private var showFeatures = false
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Choose Your Plan")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Start free, upgrade when ready")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Free tier
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Free")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("$0")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        OnboardingFeatureRow(text: "10 notes limit", included: true)
                        OnboardingFeatureRow(text: "4 default categories", included: true)
                        OnboardingFeatureRow(text: "Basic text editing", included: true)
                        OnboardingFeatureRow(text: "Local storage only", included: true)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Premium tier
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Premium")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("Everything you need")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$11.99")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                            Text("per year")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        OnboardingFeatureRow(text: "Unlimited notes", included: true, isPremium: true)
                        OnboardingFeatureRow(text: "Custom categories", included: true, isPremium: true)
                        OnboardingFeatureRow(text: "Rich text & images", included: true, isPremium: true)
                        OnboardingFeatureRow(text: "Location & weather tags", included: true, isPremium: true)
                        OnboardingFeatureRow(text: "Cloud sync", included: true, isPremium: true)
                        OnboardingFeatureRow(text: "Public sharing", included: true, isPremium: true)
                    }
                }
                .padding()
                .background(
                    Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.0, green: 0.48, blue: 1.0), lineWidth: 2)
                )
                .cornerRadius(12)
                .scaleEffect(showFeatures ? 1.0 : 0.98)
                .animation(.spring(response: 0.6).delay(0.2), value: showFeatures)
            }
            .padding(.horizontal)
            
            Text("Try free first • Cancel anytime • No commitments")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                showFeatures = true
            }
        }
    }
}

// MARK: - GetStartedStep
struct GetStartedStep: View {
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6).delay(0.2), value: showContent)
                
                VStack(spacing: 16) {
                    Text("Ready to Start Writing?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Create your first note and experience the joy of organized thoughts")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.8).delay(0.4), value: showContent)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Your data stays private")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Start with 10 free notes")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("No account required to begin")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.8).delay(0.6), value: showContent)
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Text("Tap 'Get Started' to begin your writing journey")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("You can always upgrade to Premium later")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.8).delay(0.8), value: showContent)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let text: String
    let included: Bool
    var isPremium: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(included ? (isPremium ? Color(red: 0.0, green: 0.48, blue: 1.0) : .green) : .gray)
                .font(.system(size: 16))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(included ? .primary : .secondary)
            
            Spacer()
        }
    }
}
