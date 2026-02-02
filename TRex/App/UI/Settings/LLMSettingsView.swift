import SwiftUI
import TRexCore

struct LLMSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @State private var showOCRAPIKeyInfo = false
    @State private var showPostProcessAPIKeyInfo = false

    private var contentHeight: CGFloat {
        var height: CGFloat = 170 // Base height for two collapsed cards + padding
        if preferences.llmEnableOCR {
            height += 330
        }
        if preferences.llmEnablePostProcessing {
            height += 280
        }
        return height
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - OCR Engine Section
                    SettingsCard {
                        SettingsCardHeader(
                            icon: "eye.circle",
                            title: "LLM OCR Engine",
                            subtitle: "Use a language model for text recognition instead of built-in OCR",
                            isOn: $preferences.llmEnableOCR,
                            onChange: { TRex.shared.initializeLLM() }
                        )

                        if preferences.llmEnableOCR {
                            SettingsDivider()

                            ProviderConfigSection(
                                provider: $preferences.llmOCRProvider,
                                apiKey: $preferences.llmOCRAPIKey,
                                customEndpoint: $preferences.llmOCRCustomEndpoint,
                                model: $preferences.llmOCRModel,
                                showAPIKeyInfo: $showOCRAPIKeyInfo,
                                apiKeyEnvVarMessage: ocrAPIKeyEnvVarMessage,
                                includeApple: false,
                                onChange: { TRex.shared.initializeLLM() }
                            )

                            SettingsDivider()

                            SettingsFormRow(label: "Prompt") {
                                TextEditor(text: $preferences.llmOCRPrompt)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(height: 72)
                                    .scrollContentBackground(.hidden)
                                    .padding(6)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                    )
                            }

                            SettingsDivider()

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Fallback to built-in OCR")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Use Apple Vision if LLM fails or times out")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $preferences.llmFallbackToBuiltIn)
                                    .toggleStyle(SwitchToggleStyle())
                                    .onChange(of: preferences.llmFallbackToBuiltIn) { _ in
                                        TRex.shared.initializeLLM()
                                    }
                            }
                        }
                    }

                    // MARK: - Post-Processing Section
                    SettingsCard {
                        SettingsCardHeader(
                            icon: "wand.and.stars",
                            title: "Post-Processing",
                            subtitle: "Refine OCR output using a language model",
                            isOn: $preferences.llmEnablePostProcessing,
                            onChange: { TRex.shared.initializeLLM() }
                        )

                        if preferences.llmEnablePostProcessing {
                            SettingsDivider()

                            ProviderConfigSection(
                                provider: $preferences.llmPostProcessProvider,
                                apiKey: $preferences.llmPostProcessAPIKey,
                                customEndpoint: $preferences.llmPostProcessCustomEndpoint,
                                model: $preferences.llmPostProcessModel,
                                showAPIKeyInfo: $showPostProcessAPIKeyInfo,
                                apiKeyEnvVarMessage: postProcessAPIKeyEnvVarMessage,
                                includeApple: true,
                                onChange: { TRex.shared.initializeLLM() }
                            )

                            SettingsDivider()

                            SettingsFormRow(label: "Prompt") {
                                VStack(alignment: .leading, spacing: 4) {
                                    TextEditor(text: $preferences.llmPostProcessPrompt)
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(height: 88)
                                        .scrollContentBackground(.hidden)
                                        .padding(6)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                        )

                                    Text("Use {text} as placeholder for captured text")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 500, height: contentHeight)
    }

    private var ocrAPIKeyEnvVarMessage: String {
        switch preferences.llmOCRProvider {
        case "OpenAI":
            return "Or set OPENAI_API_KEY environment variable"
        case "Anthropic":
            return "Or set ANTHROPIC_API_KEY environment variable"
        default:
            return ""
        }
    }

    private var postProcessAPIKeyEnvVarMessage: String {
        switch preferences.llmPostProcessProvider {
        case "OpenAI":
            return "Or set OPENAI_API_KEY environment variable"
        case "Anthropic":
            return "Or set ANTHROPIC_API_KEY environment variable"
        default:
            return ""
        }
    }
}

// MARK: - Card Container

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
}

// MARK: - Card Header

private struct SettingsCardHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: isOn) { _ in
                    onChange()
                }
        }
    }
}

// MARK: - Provider Configuration

private struct ProviderConfigSection: View {
    @Binding var provider: String
    @Binding var apiKey: String
    @Binding var customEndpoint: String
    @Binding var model: String
    @Binding var showAPIKeyInfo: Bool
    let apiKeyEnvVarMessage: String
    let includeApple: Bool
    var onChange: () -> Void

    private var needsAPIKey: Bool {
        provider != "Custom" && provider != "Apple"
    }

    private var needsModel: Bool {
        provider != "Apple"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Provider picker
            SettingsFormRow(label: "Provider") {
                Picker("", selection: $provider) {
                    Text("OpenAI").tag("OpenAI")
                    Text("Anthropic").tag("Anthropic")
                    Text("Custom").tag("Custom")
                    if includeApple {
                        Text("Apple").tag("Apple")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: provider) { _ in
                    onChange()
                }
            }

            // Apple Intelligence note
            if provider == "Apple" {
                HStack(spacing: 6) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("On-device Apple Intelligence (requires macOS 15.1+)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 70)
            }

            // API Key
            if needsAPIKey {
                SettingsFormRow(label: "API Key") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            SecureField("Enter API key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: apiKey) { _ in
                                    onChange()
                                }

                            Button(action: { showAPIKeyInfo.toggle() }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("API key can also be set via environment variable")
                        }

                        if showAPIKeyInfo, !apiKeyEnvVarMessage.isEmpty {
                            Text(apiKeyEnvVarMessage)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Custom Endpoint
            if provider == "Custom" {
                SettingsFormRow(label: "Endpoint") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("http://localhost:11434/v1", text: $customEndpoint)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: customEndpoint) { _ in
                                onChange()
                            }

                        Text("OpenAI-compatible endpoint (Ollama, LM Studio, etc.)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Model
            if needsModel {
                SettingsFormRow(label: "Model") {
                    TextField(modelPlaceholder, text: $model)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: model) { _ in
                            onChange()
                        }
                }
            }
        }
    }

    private var modelPlaceholder: String {
        switch provider {
        case "OpenAI":
            return "e.g. gpt-5.2, gpt-5"
        case "Anthropic":
            return "e.g. claude-sonnet-4-5-20250929, claude-opus-4-5-20251101"
        case "Custom":
            return "Model name"
        default:
            return "Model name"
        }
    }
}

// MARK: - Form Row

private struct SettingsFormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 56, alignment: .trailing)
                .padding(.top, 4)

            content
        }
    }
}

// MARK: - Divider

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, 2)
    }
}
