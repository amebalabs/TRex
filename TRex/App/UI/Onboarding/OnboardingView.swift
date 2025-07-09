import KeyboardShortcuts
import SwiftUI
import TRexCore

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showContent = false
    
    var body: some View {
        PagerView(pageCount: 5, currentIndex: $currentPage) {
            WelcomeView()
            FeatureHighlightView()
            PermissionsView()
            ShortcutView().environmentObject(Preferences.shared)
            FinishView()
        }
        .frame(width: 500, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct WelcomeView: View {
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("mac_256")
                .resizable()
                .renderingMode(.original)
                .frame(width: 180, height: 180)
                .scaleEffect(animateIcon ? 1.0 : 0.8)
                .opacity(animateIcon ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: animateIcon)
            
            VStack(spacing: 15) {
                Text("Welcome to TRex")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .multilineTextAlignment(.center)
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateText)
                
                Text("The intelligent text extraction tool for macOS")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateText)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 50)
        .onAppear {
            animateIcon = true
            animateText = true
        }
    }
}

struct FeatureHighlightView: View {
    @State private var animateFeatures = false
    
    let features = [
        ("rectangle.and.text.magnifyingglass", "Text Recognition", "Extract text from any part of your screen instantly"),
        ("qrcode", "QR & Barcode", "Scan QR codes and barcodes directly from your screen"),
        ("globe", "Multi-Language", "Support for 14+ languages with Vision framework"),
        ("bolt.fill", "Lightning Fast", "Native macOS performance with instant results")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Powerful Features")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Everything you need for text extraction")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            
            Spacer(minLength: 20)
            
            VStack(alignment: .leading, spacing: 25) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    HStack(alignment: .top, spacing: 20) {
                        Spacer()
                        Image(systemName: feature.0)
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.1)
                                .font(.headline)
                            Text(feature.2)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(animateFeatures ? 1.0 : 0.0)
                    .offset(x: animateFeatures ? 0 : -30)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: animateFeatures)
                }
            }
            .padding(.horizontal, 50)
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer(minLength: 20)
        }
        .onAppear {
            animateFeatures = true
        }
    }
}

struct PermissionsView: View {
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .opacity(animateContent ? 1.0 : 0.0)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateContent)
                .padding(.top, 40)
            
            Text("Screen Recording Permission")
                .font(.system(size: 28, weight: .bold))
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
            
            VStack(spacing: 15) {
                Text("TRex needs screen recording permission to capture text from your screen.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                
                Text("You'll be prompted to grant this permission when you first use TRex.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 30)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Your privacy is protected")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Text is only captured when you trigger it")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No data is stored or transmitted")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding(.horizontal, 60)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
            
            Spacer()
        }
        .onAppear {
            animateContent = true
        }
    }
}

struct ShortcutView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @State private var animateContent = false
    let width: CGFloat = 140
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Customize Your Experience")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 30)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5), value: animateContent)
            
            VStack(spacing: 20) {
                GroupBox {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.blue)
                            Text("Preferences")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ToggleView(label: "Startup", secondLabel: "Start at Login",
                                   state: $launchAtLogin.isEnabled,
                                   width: width)
                        
                        ToggleView(label: "Sounds",
                                   secondLabel: "Play Capture Sound",
                                   state: $preferences.captureSound,
                                   width: width)
                        
                        ToggleView(label: "Notifications",
                                   secondLabel: "Show Recognized Text",
                                   state: $preferences.resultNotification,
                                   width: width)
                        
                        ToggleView(label: "Menu Bar", secondLabel: "Show Icon",
                                   state: $preferences.showMenuBarIcon,
                                   width: width)
                    }
                    .padding(10)
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
                
                GroupBox {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "keyboard.fill")
                                .foregroundColor(.blue)
                            Text("Keyboard Shortcuts")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Capture from Screen:")
                                .frame(width: 150, alignment: .trailing)
                            KeyboardShortcuts.Recorder(for: .captureScreen)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Capture from Clipboard:")
                                .frame(width: 150, alignment: .trailing)
                            KeyboardShortcuts.Recorder(for: .captureClipboard)
                            Spacer()
                        }
                    }
                    .padding(10)
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .onAppear {
            animateContent = true
        }
    }
}

struct FinishView: View {
    @State private var animateCheckmark = false
    @State private var animateContent = false
    @State private var animateDinos = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer(minLength: 20)
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateCheckmark)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.0)
                    .rotationEffect(.degrees(animateCheckmark ? 0 : -180))
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: animateCheckmark)
            }
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
                
                Text("TRex is ready to help you extract text")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)
            }
            
            VStack(spacing: 15) {
                Text("Quick Tips:")
                    .font(.headline)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
                
                VStack(alignment: .center, spacing: 10) {
                    HStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "menubar.arrow.up.rectangle")
                            .frame(width: 20)
                            .foregroundColor(.secondary)
                        Text("Look for the TRex icon in your menu bar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "keyboard")
                            .frame(width: 20)
                            .foregroundColor(.secondary)
                        Text("Use keyboard shortcuts for quick capture")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "gearshape")
                            .frame(width: 20)
                            .foregroundColor(.secondary)
                        Text("Check preferences for more options")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: 300)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: animateContent)
            }
            
            Text("🦖 🦖 🦖")
                .font(.system(size: 36))
                .opacity(animateDinos ? 1.0 : 0.0)
                .scaleEffect(animateDinos ? 1.0 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.8), value: animateDinos)
            
            Spacer(minLength: 20)
        }
        .onAppear {
            animateCheckmark = true
            animateContent = true
            animateDinos = true
        }
    }
}

