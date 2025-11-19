import SwiftUI
import TRexCore

struct LLMSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @State private var showOCRAPIKeyInfo = false
    @State private var showPostProcessAPIKeyInfo = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // LLM OCR Engine Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("LLM OCR Engine")
                                .font(.headline)

                            Spacer()

                            Toggle("", isOn: $preferences.llmEnableOCR)
                                .toggleStyle(SwitchToggleStyle())
                                .onChange(of: preferences.llmEnableOCR) { _ in
                                    TRex.shared.initializeLLM()
                                }
                        }

                        if preferences.llmEnableOCR {
                            // OCR Provider Selection
                            Text("Provider")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("", selection: $preferences.llmOCRProvider) {
                                Text("OpenAI").tag("OpenAI")
                                Text("Anthropic").tag("Anthropic")
                                Text("Custom").tag("Custom")
                                // No Apple option for OCR - doesn't support vision
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: preferences.llmOCRProvider) { _ in
                                TRex.shared.initializeLLM()
                            }

                            // API Key for OCR
                            if preferences.llmOCRProvider != "Custom" {
                                HStack {
                                    Text("API Key")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Button(action: { showOCRAPIKeyInfo.toggle() }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("API key can also be set via environment variable")
                                }

                                SecureField("Enter API key or use environment variable", text: $preferences.llmOCRAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: preferences.llmOCRAPIKey) { _ in
                                        TRex.shared.initializeLLM()
                                    }

                                if showOCRAPIKeyInfo {
                                    Text(ocrAPIKeyEnvVarMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Custom Endpoint for OCR
                            if preferences.llmOCRProvider == "Custom" {
                                Text("Custom Endpoint")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                TextField("http://localhost:11434/v1", text: $preferences.llmOCRCustomEndpoint)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: preferences.llmOCRCustomEndpoint) { _ in
                                        TRex.shared.initializeLLM()
                                    }

                                Text("OpenAI-compatible endpoint (e.g., Ollama, LM Studio)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // OCR Model
                            Text("Model")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextField("Model name (e.g., gpt-4o, claude-3-5-sonnet-20241022)", text: $preferences.llmOCRModel)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: preferences.llmOCRModel) { _ in
                                    TRex.shared.initializeLLM()
                                }

                            // OCR Prompt
                            Text("Prompt")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextEditor(text: $preferences.llmOCRPrompt)
                                .font(.system(size: 11))
                                .frame(height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        }
                    }

                    Divider()

                    // Post-Processing Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Post-Processing")
                                .font(.headline)

                            Spacer()

                            Toggle("", isOn: $preferences.llmEnablePostProcessing)
                                .toggleStyle(SwitchToggleStyle())
                                .onChange(of: preferences.llmEnablePostProcessing) { _ in
                                    TRex.shared.initializeLLM()
                                }
                        }

                        if preferences.llmEnablePostProcessing {
                            // Post-Processing Provider Selection
                            Text("Provider")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("", selection: $preferences.llmPostProcessProvider) {
                                Text("OpenAI").tag("OpenAI")
                                Text("Anthropic").tag("Anthropic")
                                Text("Custom").tag("Custom")
                                Text("Apple").tag("Apple")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: preferences.llmPostProcessProvider) { _ in
                                TRex.shared.initializeLLM()
                            }

                            // API Key for Post-Processing
                            if preferences.llmPostProcessProvider != "Custom" && preferences.llmPostProcessProvider != "Apple" {
                                HStack {
                                    Text("API Key")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Button(action: { showPostProcessAPIKeyInfo.toggle() }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("API key can also be set via environment variable")
                                }

                                SecureField("Enter API key or use environment variable", text: $preferences.llmPostProcessAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: preferences.llmPostProcessAPIKey) { _ in
                                        TRex.shared.initializeLLM()
                                    }

                                if showPostProcessAPIKeyInfo {
                                    Text(postProcessAPIKeyEnvVarMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Custom Endpoint for Post-Processing
                            if preferences.llmPostProcessProvider == "Custom" {
                                Text("Custom Endpoint")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                TextField("http://localhost:11434/v1", text: $preferences.llmPostProcessCustomEndpoint)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: preferences.llmPostProcessCustomEndpoint) { _ in
                                        TRex.shared.initializeLLM()
                                    }

                                Text("OpenAI-compatible endpoint (e.g., Ollama, LM Studio)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Apple Intelligence note
                            if preferences.llmPostProcessProvider == "Apple" {
                                Text("Using on-device Apple Intelligence (requires macOS 15.1+)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Post-Processing Model
                            if preferences.llmPostProcessProvider != "Apple" {
                                Text("Model")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                TextField("Model name (e.g., gpt-4o, claude-3-5-sonnet-20241022)", text: $preferences.llmPostProcessModel)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: preferences.llmPostProcessModel) { _ in
                                        TRex.shared.initializeLLM()
                                    }
                            }

                            // Post-Processing Prompt
                            Text("Prompt (use {text} placeholder)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextEditor(text: $preferences.llmPostProcessPrompt)
                                .font(.system(size: 11))
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        }
                    }

                    Divider()

                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Options")
                            .font(.headline)

                        Toggle("Fallback to built-in OCR on failure", isOn: $preferences.llmFallbackToBuiltIn)
                            .toggleStyle(SwitchToggleStyle())
                            .onChange(of: preferences.llmFallbackToBuiltIn) { _ in
                                TRex.shared.initializeLLM()
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 500, height: 650)
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
