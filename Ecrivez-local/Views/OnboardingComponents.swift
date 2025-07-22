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
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
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
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(animateIcon ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(animateIcon ? 5 : -5))
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
            }
            VStack(spacing: 16) {
                Text("Welcome to Write-It-Down")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.3), value: showText)
                Text("Your thoughts, beautifully captured")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: showText)
                VStack(spacing: 8) {
                    Text("Let's take a quick tour of what you can do")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Free: 10 notes • Premium: $5/year for unlimited")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                .opacity(showText ? 1 : 0)
                .animation(.easeIn(duration: 0.8).delay(0.7), value: showText)
            }
            .padding(.horizontal, 40)
            Spacer()
            HStack(spacing: 30) {
                FeatureIcon(icon: "pencil.and.outline", label: "Rich Text")
                FeatureIcon(icon: "folder.fill", label: "Categories")
                FeatureIcon(icon: "location.fill", label: "Location")
                FeatureIcon(icon: "globe", label: "Share")
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

// MARK: - InteractiveCategoryDemo
struct InteractiveCategoryDemo: View {
    @State private var selectedCategory: String = "Ideas"
    @State private var showCategories = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Organize Your Thoughts")
                .font(.largeTitle)
                .bold()
            VStack {
                HStack {
                    Circle()
                        .fill(categoryColor(selectedCategory))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: categoryIcon(selectedCategory))
                                .foregroundColor(.white)
                        )
                    Text(selectedCategory)
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                Button("Tap to Change Category") {
                    withAnimation {
                        showCategories.toggle()
                    }
                }
                .buttonStyle(.bordered)
                if showCategories {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["Ideas", "Work", "Personal", "Travel"], id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                    showCategories = false
                                }) {
                                    VStack {
                                        Circle()
                                            .fill(categoryColor(category))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: categoryIcon(category))
                                                    .foregroundColor(.white)
                                            )
                                        Text(category)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            VStack(spacing: 8) {
                Text("Use default categories or upgrade for custom ones")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("Premium feature: Create your own categories")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    func categoryColor(_ category: String) -> Color {
        switch category {
        case "Ideas": return .blue
        case "Work": return .green
        case "Personal": return .purple
        case "Travel": return .orange
        default: return .gray
        }
    }
    
    func categoryIcon(_ category: String) -> String {
        switch category {
        case "Ideas": return "lightbulb.fill"
        case "Work": return "briefcase.fill"
        case "Personal": return "person.fill"
        case "Travel": return "airplane"
        default: return "folder.fill"
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
        VStack(spacing: 30) {
            Text("Simple & Affordable")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 24) {
                // Free tier
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Free")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("$0")
                            .font(.title3)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        OnboardingFeatureRow(text: "10 notes", included: true)
                        OnboardingFeatureRow(text: "Default categories", included: true)
                        OnboardingFeatureRow(text: "Rich text & images", included: true)
                        OnboardingFeatureRow(text: "Location tagging", included: true)
                        OnboardingFeatureRow(text: "Public sharing", included: true)
                        OnboardingFeatureRow(text: "Cloud sync", included: false)
                        OnboardingFeatureRow(text: "Custom categories", included: false)
                        OnboardingFeatureRow(text: "Unlimited notes", included: false)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Premium tier
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Premium")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("$5/year")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        OnboardingFeatureRow(text: "Everything in Free", included: true)
                        OnboardingFeatureRow(text: "Unlimited notes", included: true)
                        OnboardingFeatureRow(text: "Custom categories", included: true)
                        OnboardingFeatureRow(text: "Cloud sync", included: true)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .cornerRadius(12)
                .scaleEffect(showFeatures ? 1.02 : 1.0)
                .animation(.spring(response: 0.5), value: showFeatures)
            }
            .padding(.horizontal)
            
            Text("Start free and upgrade anytime")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                showFeatures = true
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let text: String
    let included: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(included ? .green : .gray)
                .font(.system(size: 16))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(included ? .primary : .secondary)
            
            Spacer()
        }
    }
}
