import SwiftUI
import UIKit

@main
struct SaverApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

enum Phase: Equatable {
    case idle, working(String), done, failed(String)
}

struct ContentView: View {
    @AppStorage("serverURL") private var server = Config.server
    @AppStorage("serverKey") private var apiKey = Config.apiKey
    @State private var link = ""
    @State private var phase = Phase.idle
    @State private var showSettings = false
    @FocusState private var editing: Bool

    private var busy: Bool { if case .working = phase { true } else { false } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    linkField
                    downloadButton
                    status
                    tips
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .animation(.spring(duration: 0.4), value: phase)
                .animation(.spring(duration: 0.3), value: link.isEmpty)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { Backdrop() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ajustes", systemImage: "gearshape") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(server: $server, apiKey: $apiKey)
            }
        }
        .tint(.brandViolet)
        .sensoryFeedback(trigger: phase, feedback)
    }

    func feedback(_ old: Phase, _ new: Phase) -> SensoryFeedback? {
        switch new {
        case .done: return .success
        case .failed: return .error
        default: return nil
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            AppMark()
            Text("Saver")
                .font(.largeTitle.bold())
            Text("Guarda vídeos de TikTok, X e Instagram sin marca de agua y en máxima calidad.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var linkField: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .foregroundStyle(.secondary)
            TextField("Pega aquí el enlace", text: $link)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($editing)
                .onSubmit(start)
            if link.isEmpty {
                Button("Pegar", systemImage: "doc.on.clipboard") {
                    link = UIPasteboard.general.url?.absoluteString ?? UIPasteboard.general.string ?? ""
                }
                .font(.subheadline.weight(.semibold))
                .glassButton()
                .transition(.scale.combined(with: .opacity))
            } else {
                Button("Borrar", systemImage: "xmark.circle.fill") { link = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.tertiary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .frame(minHeight: 60)
        .glassCard()
    }

    private var downloadButton: some View {
        Button(action: start) {
            Label(busy ? "Descargando…" : "Descargar", systemImage: "arrow.down.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .glassButton(prominent: true)
        .controlSize(.large)
        .disabled(busy || link.isEmpty)
    }

    @ViewBuilder private var status: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .working(let text):
            HStack(spacing: 12) {
                ProgressView()
                Text(text)
            }
            .statusCard()
        case .done:
            HStack(spacing: 12) {
                Label("Guardado en Fotos", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: phase)
                Spacer()
                Link("Abrir Fotos", destination: URL(string: "photos-redirect://")!)
                    .font(.subheadline.weight(.semibold))
            }
            .statusCard()
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .statusCard()
        }
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Tip(symbol: "square.and.arrow.up", title: "Lo más rápido",
                text: "En TikTok, X o Instagram pulsa Compartir → Saver y se guarda solo.")
            Divider()
            Tip(symbol: "photo.on.rectangle", title: "Carruseles",
                text: "Si la publicación tiene varias fotos o vídeos, se guardan todos.")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    func start() {
        guard !busy, !link.isEmpty else { return }
        editing = false
        Task { await download() }
    }

    func download() async {
        do {
            guard let url = firstURL(in: link) else { throw Failure("Eso no parece un enlace.") }
            try await Downloader.save(link: url, server: server, apiKey: apiKey) { phase = .working($0) }
            phase = .done
            link = ""
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

private struct Tip: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

private extension View {
    func statusCard() -> some View {
        padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 20)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct SettingsView: View {
    @Binding var server: String
    @Binding var apiKey: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Config.server, text: $server)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("API key (opcional)", text: $apiKey)
                } header: {
                    Text("Servidor cobalt")
                } footer: {
                    Text("El menú Compartir usa siempre el servidor con el que se compiló la app.")
                }
                Section {
                    LabeledContent("Versión", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
