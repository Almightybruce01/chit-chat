import SwiftUI

struct AIStudioSetupView: View {
    @AppStorage("chitchat.ai.endpoint") private var endpoint = ""
    @AppStorage("chitchat.ai.model") private var model = "gpt-4o-mini"
    @AppStorage("chitchat.ai.key") private var apiKey = ""

    @State private var testOutput = ""
    @State private var generatedUIBrief = ""
    @State private var isTesting = false
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            EliteBackground()
            ScrollView {
                VStack(spacing: 12) {
                    FuturisticSectionHeader(
                        title: "AI Studio Setup",
                        subtitle: "Configure your API endpoint and generate UI sprint briefs."
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    EliteSectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Connection")
                                .font(TypeTokens.title)
                            TextField("Endpoint (OpenAI-compatible chat completions URL)", text: $endpoint)
                                .textFieldStyle(EliteTextFieldStyle())
                            TextField("Model", text: $model)
                                .textFieldStyle(EliteTextFieldStyle())
                            SecureField("API Key (optional for local gateways)", text: $apiKey)
                                .textFieldStyle(EliteTextFieldStyle())
                            HStack {
                                Button(isTesting ? "Testing..." : "Test Connection") {
                                    Task { await testConnection() }
                                }
                                .buttonStyle(NeonPrimaryButtonStyle())
                                .disabled(isTesting)
                                Button("Use OpenAI Default") {
                                    endpoint = "https://api.openai.com/v1/chat/completions"
                                    if model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        model = "gpt-4o-mini"
                                    }
                                }
                                .buttonStyle(.bordered)
                                if !testOutput.isEmpty {
                                    Text(testOutput)
                                        .font(.caption)
                                }
                            }
                        }
                    }

                    EliteSectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Setup Checklist")
                                .font(TypeTokens.title)
                            checklistRow("1. Add endpoint URL")
                            checklistRow("2. Set model name")
                            checklistRow("3. Add API key")
                            checklistRow("4. Tap Test Connection")
                            checklistRow("5. Generate Sprint Brief")
                        }
                    }

                    EliteSectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AI UI Sprint Helper")
                                .font(TypeTokens.title)
                            Text("Generate a premium sprint brief for backgrounds, component cleanup, interaction polish, and visual consistency.")
                                .font(TypeTokens.caption)
                                .foregroundStyle(.secondary)
                            Button(isGenerating ? "Generating..." : "Generate Sprint Brief") {
                                Task { await generateSprintBrief() }
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                            .disabled(isGenerating)
                            if !generatedUIBrief.isEmpty {
                                Text(generatedUIBrief)
                                    .font(.footnote)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .padding(.horizontal, LayoutTokens.screenHorizontal)
                .padding(.top, 10)
            }
        }
        .navigationTitle("AI Studio")
    }

    @MainActor
    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }
        do {
            let result = try await AIStudioService.shared.testConnection(config: config)
            testOutput = "Connected: \(result.prefix(120))"
        } catch {
            testOutput = "Failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func generateSprintBrief() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let prompt = """
            Write a concise mobile UI sprint brief with sections:
            1) Background and motion
            2) Contrast and readability
            3) Feed/reels polish
            4) Profile/DM polish
            5) QA checklist
            """
            let result = try await AIStudioService.shared.generateText(prompt: prompt, config: config)
            generatedUIBrief = result
        } catch {
            generatedUIBrief = "Generation failed: \(error.localizedDescription)"
        }
    }

    private var config: AIStudioConfig {
        AIStudioConfig(endpoint: endpoint, model: model, apiKey: apiKey)
    }

    @ViewBuilder
    private func checklistRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(BrandPalette.neonGreen)
            Text(text)
                .font(TypeTokens.caption)
        }
    }
}
