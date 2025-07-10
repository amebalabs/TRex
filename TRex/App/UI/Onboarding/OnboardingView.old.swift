import KeyboardShortcuts
import SwiftUI
import TRexCore
import CoreGraphics

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showContent = false
    @EnvironmentObject var preferences: Preferences
    
    let totalPages = 3
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // Add space for title bar
                Spacer().frame(height: 28)
                // Content area
                ZStack {
                    if currentPage == 0 {
                        WelcomeAndFeaturesView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    
                    if currentPage == 1 {
                        SetupView()
                            .environmentObject(preferences)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    
                    if currentPage == 2 {
                        InteractiveTutorialView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .frame(maxHeight: .infinity)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
                
                // Custom navigation
                NavigationFooter(
                    currentPage: $currentPage,
                    totalPages: totalPages
                )
                .frame(maxWidth: .infinity)
                .frame(height: 100)
            }
        }
        .frame(width: 1000, height: 800)
//        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Page 1: Welcome & Features Combined
struct WelcomeAndFeaturesView: View {
    @State private var animateContent = false
    @State private var hoveredFeature: Int? = nil
    
    let features = [
        ("text.viewfinder", "Smart Text Recognition", "Extract text from any part of your screen with AI-powered accuracy", Color.blue),
        ("qrcode.viewfinder", "QR & Barcode Scanner", "Instantly decode QR codes and barcodes directly from your display", Color.purple),
        ("globe.badge.chevron.backward", "Multi-Language Support", "Recognize text in 14+ languages with automatic detection", Color.green),
        ("bolt.horizontal.circle", "Lightning Fast", "Native performance with instant results and zero lag", Color.orange)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side - Welcome
                VStack(spacing: 30) {
                Spacer()
                
                Image("mac_256")
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .rotationEffect(.degrees(animateContent ? 0 : -10))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateContent)
                
                VStack(spacing: 20) {
                    Text("Welcome to")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                    
                    Text("TRex")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    Text("Your intelligent OCR companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    ForEach(0..<3) { i in
                        Text("🦖")
                            .font(.system(size: 32))
                            .opacity(animateContent ? 1.0 : 0.0)
                            .scaleEffect(animateContent ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.5)
                                .delay(Double(i) * 0.1 + 0.8),
                                value: animateContent
                            )
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(width: geometry.size.width * 0.3)
            .padding(40)
            .clipped()
            
            Divider()
                .opacity(0.2)
            
            // Right side - Features
            VStack(alignment: .leading, spacing: 25) {
                Text("Powerful Features")
                    .font(.system(size: 32, weight: .bold))
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            FeatureCard(
                                icon: feature.0,
                                title: feature.1,
                                description: feature.2,
                                color: feature.3,
                                isHovered: hoveredFeature == index,
                                animateContent: animateContent,
                                delay: Double(index) * 0.1 + 0.6
                            )
                            .onHover { hovering in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    hoveredFeature = hovering ? index : nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
                }
            }
            .frame(width: geometry.size.width * 0.7)
            .padding(40)
        }
        }
        .onAppear {
            animateContent = true
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isHovered: Bool
    let animateContent: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(isHovered ? 0.08 : 0.05))
                .shadow(color: color.opacity(isHovered ? 0.2 : 0), radius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(x: animateContent ? 0 : 50)
        .animation(.easeOut(duration: 0.5).delay(delay), value: animateContent)
    }
}

// MARK: - Page 2: Setup (Permissions, Settings, Language)
struct SetupView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @State private var animateContent = false
    @State private var selectedLanguage: Preferences.RecongitionLanguage
    @State private var activeSection = 0
    @State private var screenRecordingPermission = false
    
    init() {
        _selectedLanguage = State(initialValue: Preferences.shared.recongitionLanguage)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Quick Setup")
                .font(.system(size: 42, weight: .bold))
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5), value: animateContent)
            
            // Section tabs
            HStack(spacing: 30) {
                SetupTab(icon: "shield.checkered", title: "Permissions", isActive: activeSection == 0)
                    .onTapGesture { withAnimation { activeSection = 0 } }
                
                SetupTab(icon: "keyboard", title: "Settings", isActive: activeSection == 1)
                    .onTapGesture { withAnimation { activeSection = 1 } }
                
                SetupTab(icon: "globe", title: "Language", isActive: activeSection == 2)
                    .onTapGesture { withAnimation { activeSection = 2 } }
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
            
            // Content area
            ZStack {
                // Permissions Section
                if activeSection == 0 {
                    VStack(spacing: 30) {
                        Image(systemName: screenRecordingPermission ? "shield.checkmark.fill" : "shield.checkered")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(colors: screenRecordingPermission ? [.green, .blue] : [.blue, .gray], startPoint: .top, endPoint: .bottom)
                            )
                        
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: screenRecordingPermission ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(screenRecordingPermission ? .green : .orange)
                                Text(screenRecordingPermission ? "Screen Recording Enabled" : "Screen Recording Required")
                                    .font(.title2.bold())
                            }
                            
                            Text(screenRecordingPermission ? "TRex has permission to capture text from your screen" : "TRex needs permission to capture text from your screen")
                                .foregroundColor(.secondary)
                            
                            if !screenRecordingPermission {
                                Button(action: {
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                                }) {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                        Text("Open System Preferences")
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue)
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("Grant permission to TRex in Privacy & Security settings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 15) {
                            PrivacyPoint(icon: "lock.fill", text: "Your privacy is protected", color: .green)
                            PrivacyPoint(icon: "hand.raised.fill", text: "Only captures when you trigger", color: .blue)
                            PrivacyPoint(icon: "externaldrive.fill", text: "No data stored or transmitted", color: .purple)
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
                
                // Settings Section (formerly Shortcuts)
                if activeSection == 1 {
                    VStack(spacing: 30) {
                        VStack(spacing: 25) {
                            ShortcutRow(
                                icon: "camera.viewfinder",
                                title: "Capture from Screen",
                                shortcut: .captureScreen
                            )
                            
                            ShortcutRow(
                                icon: "doc.on.clipboard",
                                title: "Capture from Clipboard",
                                shortcut: .captureClipboard
                            )
                        }
                        
                        Divider().padding(.horizontal, 50)
                        
                        VStack(spacing: 20) {
                            PreferenceToggle(
                                icon: "power",
                                title: "Start at Login",
                                isOn: $launchAtLogin.isEnabled
                            )
                            
                            PreferenceToggle(
                                icon: "speaker.wave.2",
                                title: "Capture Sound",
                                isOn: $preferences.captureSound
                            )
                            
                            PreferenceToggle(
                                icon: "bell",
                                title: "Show Notifications",
                                isOn: $preferences.resultNotification
                            )
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
                
                // Language Section
                if activeSection == 2 {
                    VStack(spacing: 20) {
                        LanguageGrid(selectedLanguage: $selectedLanguage, preferences: preferences)
                        
                        Toggle("Enable automatic language detection", isOn: $preferences.automaticLanguageDetection)
                            .toggleStyle(ModernToggleStyle())
                            .padding(.horizontal, 100)
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .frame(height: 350)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            
            Spacer()
        }
        .padding(50)
        .onAppear {
            animateContent = true
            preferences.recongitionLanguage = selectedLanguage
            checkScreenRecordingPermission()
        }
        .onChange(of: selectedLanguage) { newValue in
            preferences.recongitionLanguage = newValue
        }
    }
    
    func checkScreenRecordingPermission() {
        screenRecordingPermission = CGPreflightScreenCaptureAccess()
        
        // Check periodically while on this page
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let newStatus = CGPreflightScreenCaptureAccess()
            if newStatus != screenRecordingPermission {
                withAnimation {
                    screenRecordingPermission = newStatus
                }
            }
            
            // Stop timer if we're not on permissions section
            if activeSection != 0 {
                timer.invalidate()
            }
        }
    }
}

struct SetupTab: View {
    let icon: String
    let title: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(isActive ? .blue : .secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(isActive ? .primary : .secondary)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)
                .frame(height: 3)
                .opacity(isActive ? 1 : 0)
                .scaleEffect(x: isActive ? 1 : 0.5, y: 1, anchor: .center)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
        }
        .frame(width: 120)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
    }
}

struct LanguageGrid: View {
    @Binding var selectedLanguage: Preferences.RecongitionLanguage
    let preferences: Preferences
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(Preferences.RecongitionLanguage.allCases, id: \.self) { language in
                LanguageGridItem(
                    language: language,
                    isSelected: selectedLanguage == language,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedLanguage = language
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 50)
    }
}

struct LanguageGridItem: View {
    let language: Preferences.RecongitionLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom) : 
                        LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShortcutRow: View {
    let icon: String
    let title: String
    let shortcut: KeyboardShortcuts.Name
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 200, alignment: .leading)
            
            KeyboardShortcuts.Recorder(for: shortcut)
                .scaleEffect(1.1)
        }
    }
}

struct PreferenceToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 15))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 80)
    }
}

struct PrivacyPoint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 16))
        }
    }
}

// MARK: - Page 3: Interactive Tutorial
struct InteractiveTutorialView: View {
    @State private var animateContent = false
    @State private var currentStep = 0
    @State private var userInput = ""
    @State private var showSuccess = false
    @FocusState private var isTextFieldFocused: Bool
    
    let sampleText = "Welcome to TRex! 🦖\nYour text capture journey starts here."
    
    var body: some View {
        ZStack {
            if !showSuccess {
                VStack(spacing: 40) {
                    VStack(spacing: 20) {
                        Image(systemName: "hands.sparkles")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateContent)
                        
                        Text("Let's Practice!")
                            .font(.system(size: 42, weight: .bold))
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
                    }
                    
                    // Tutorial steps
                    HStack(spacing: 40) {
                        TutorialStep(
                            number: 1,
                            title: "Select Text",
                            description: "Click and drag to select the sample text",
                            isActive: currentStep >= 0,
                            isCompleted: currentStep > 0
                        )
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                        
                        TutorialStep(
                            number: 2,
                            title: "Use Shortcut",
                            description: "Press your keyboard shortcut",
                            isActive: currentStep >= 1,
                            isCompleted: currentStep > 1
                        )
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                        
                        TutorialStep(
                            number: 3,
                            title: "Paste Result",
                            description: "Paste the captured text below",
                            isActive: currentStep >= 2,
                            isCompleted: currentStep > 2
                        )
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
                    
                    // Sample text area
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            
                            Text(sampleText)
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(30)
                        }
                        .frame(height: 120)
                        .scaleEffect(currentStep == 0 ? 1.05 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                        
                        HStack(spacing: 20) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            
                            if let shortcut = KeyboardShortcuts.getShortcut(for: .captureScreen) {
                                Text(shortcut.description)
                                    .font(.system(.title3, design: .monospaced))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                            } else {
                                Text("No shortcut set")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .scaleEffect(currentStep == 1 ? 1.1 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Paste the captured text here...", text: $userInput)
                                .textFieldStyle(ModernTextFieldStyle())
                                .focused($isTextFieldFocused)
                                .scaleEffect(currentStep == 2 ? 1.02 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                                .onChange(of: userInput) { newValue in
                                    checkSuccess(newValue)
                                }
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isTextFieldFocused = true
                                    }
                                }
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Press ⌘V to paste")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
                    
                    Spacer()
                }
                .padding(50)
            } else {
                TutorialSuccessView()
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            animateContent = true
            setupClipboardMonitoring()
        }
    }
    
    func setupClipboardMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if currentStep < 2 {
                if let clipboardString = NSPasteboard.general.string(forType: .string) {
                    if clipboardString.contains("Welcome to TRex") || clipboardString.contains("🦖") {
                        withAnimation {
                            currentStep = 2
                        }
                        userInput = clipboardString
                        checkSuccess(clipboardString)
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    func checkSuccess(_ text: String) {
        let normalizedInput = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalizedInput.contains("Welcome to TRex") || 
           normalizedInput.contains("🦖") ||
           text.contains(sampleText) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showSuccess = true
            }
        }
    }
}

struct TutorialStep: View {
    let number: Int
    let title: String
    let description: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isActive ? Color.blue : Color.gray.opacity(0.2)))
                    .frame(width: 50, height: 50)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isActive ? .white : .gray)
                }
            }
            
            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isActive ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(isActive ? 1.0 : 0.5)
        .scaleEffect(isActive && !isCompleted ? 1.1 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isCompleted)
    }
}

struct TutorialSuccessView: View {
    @State private var animateElements = false
    @State private var particleAnimation = false
    
    var body: some View {
        ZStack {
            // Confetti effect
            ForEach(0..<20) { i in
                ConfettiParticle()
                    .position(
                        x: CGFloat.random(in: 100...800),
                        y: particleAnimation ? CGFloat.random(in: 500...700) : -50
                    )
                    .animation(
                        Animation.easeOut(duration: Double.random(in: 2...3))
                            .delay(Double(i) * 0.05),
                        value: particleAnimation
                    )
            }
            
            VStack(spacing: 40) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateElements ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateElements)
                    
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateElements ? 1.0 : 0.0)
                            .rotationEffect(.degrees(animateElements ? 0 : -180))
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                        
                        Text("🦖")
                            .font(.system(size: 50))
                            .scaleEffect(animateElements ? 1.0 : 0.0)
                            .animation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.5), value: animateElements)
                    }
                }
                
                VStack(spacing: 20) {
                    Text("You're a TRex Master!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
                    
                    Text("You've mastered the art of text capture")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                    
                    VStack(spacing: 15) {
                        Label("Ready to capture text from anywhere", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Your shortcuts are configured", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("TRex is ready to roar!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 18))
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                }
            }
        }
        .onAppear {
            animateElements = true
            particleAnimation = true
        }
    }
}

struct ConfettiParticle: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    let size = CGFloat.random(in: 10...20)
    let rotation = Double.random(in: 0...360)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colors.randomElement()!)
            .frame(width: size, height: size * 0.6)
            .rotationEffect(.degrees(rotation))
            .opacity(0.8)
    }
}

// MARK: - Navigation Footer
struct NavigationFooter: View {
    @Binding var currentPage: Int
    let totalPages: Int
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.05)
            
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.2)
                
                Spacer()
                
                HStack {
                    // Page indicators
                    HStack(spacing: 10) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                                .onTapGesture {
                                    withAnimation {
                                        currentPage = index
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage = max(0, currentPage - 1)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        Button(action: {
                            if currentPage == totalPages - 1 {
                                NotificationCenter.default.post(name: .closeOnboarding, object: nil)
                            } else {
                                withAnimation {
                                    currentPage = min(currentPage + 1, totalPages - 1)
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                                    .fontWeight(.semibold)
                                Image(systemName: currentPage == totalPages - 1 ? "arrow.right.circle.fill" : "chevron.right")
                            }
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: currentPage == totalPages - 1 ? [.green, .blue] : [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(currentPage == totalPages - 1 ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.horizontal, 50)
                
                Spacer()
            }
        }
    }
}

// MARK: - Custom Styles
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .padding(2)
                    .shadow(radius: 2)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(PlainTextFieldStyle())
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Visual Effect
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
