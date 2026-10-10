import SwiftUI
import Charts
import AppKit

@main
struct ConcreteLabApp: App {
    var body: some Scene {
        WindowGroup("Concrete Lab") { LabView() }
            .defaultSize(width: 1320, height: 850)
        Settings { Text("Appearance and units are available in the main window.").padding() }
    }
}

private enum Screen: String, CaseIterable { case comparison = "Compare", measured = "Measured data", method = "Model & sources" }
private enum Accent: String, CaseIterable { case teal = "Teal", orange = "Orange", violet = "Violet" 
    var color: Color { switch self { case .teal: .mint; case .orange: .orange; case .violet: .purple } }
}

struct LabView: View {
    @State private var scenario = Scenario()
    @State private var screen: Screen = .comparison
    @State private var selectedMaterial = 0
    @State private var measuredAxialKN = 0.0
    @State private var measuredTorqueNm = 0.0
    @State private var specimenID = ""
    @State private var status = ""
    @AppStorage("appearance") private var appearance = "Dark"
    @AppStorage("accent") private var accentName = "Teal"
    @AppStorage("compact") private var compact = false
    @AppStorage("largeText") private var largeText = false
    @AppStorage("showEquations") private var showEquations = true

    private var accent: Color { Accent(rawValue: accentName)?.color ?? .mint }
    private var mpcResult: Result? { Physics.evaluate(scenario.mpc, scenario: scenario) }
    private var opcResult: Result? { Physics.evaluate(scenario.opc, scenario: scenario) }
    private var inset: CGFloat { compact ? 12 : 20 }

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 235)
            Rectangle().fill(.white.opacity(0.09)).frame(width: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: compact ? 14 : 22) {
                    header
                    if screen == .comparison { comparison }
                    else if screen == .measured { measuredView }
                    else { methodView }
                }
                .frame(maxWidth: 1150, alignment: .leading)
                .padding(compact ? 18 : 28)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(appearance == "Dark" ? .dark : .light)
        .font(.system(size: largeText ? 15 : 13))
        .tint(accent)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 10) {
                Image(systemName: "circle.hexagongrid.fill").font(.title2).foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 0) {
                    Text("CONCRETE LAB").font(.system(size: 14, weight: .heavy, design: .rounded))
                    Text("Material comparison").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(.top, 12)
            VStack(spacing: 5) {
                ForEach(Screen.allCases, id: \.self) { item in
                    Button { screen = item } label: {
                        HStack {
                            Image(systemName: item == .comparison ? "chart.xyaxis.line" : item == .measured ? "ruler" : "book.closed")
                                .frame(width: 22)
                            Text(item.rawValue)
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 11)
                        .background(screen == item ? accent.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                Text("WORKSPACE").font(.caption.bold()).foregroundStyle(.secondary)
                Button("Save setup…", systemImage: "square.and.arrow.down") { saveSetup() }
                Button("Open setup…", systemImage: "folder") { openSetup() }
                Button("Export sweep CSV…", systemImage: "tablecells") { exportCSV() }
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            }.buttonStyle(.borderless)
            Spacer()
            Text("Research tool · SI units")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(screen == .comparison ? "Strength comparison" : screen == .measured ? "Measured test data" : "Model and references")
                    .font(.system(size: largeText ? 31 : 28, weight: .bold, design: .rounded))
                Text(screen == .comparison ? "Explore axial compression, torsion, and their combined stress in a solid cylinder." :
                        screen == .measured ? "Turn observed peak force and torque into nominal stresses." :
                        "Equations, assumptions, limits, and research behind this app.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label("LOCAL SIMULATION", systemImage: "circle.dotted")
                .font(.caption.bold()).foregroundStyle(accent)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(accent.opacity(0.12), in: Capsule())
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: compact ? 14 : 20) {
            if !scenario.valid { warning("Enter positive material properties and specimen dimensions. Loads must be nonnegative; Poisson’s ratio must be between −1 and 0.5.") }
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 16) {
                    card("Specimen & applied load", icon: "cylinder.split.1x2") {
                        field("Diameter", value: $scenario.diameterMM, unit: "mm")
                        field("Length", value: $scenario.lengthMM, unit: "mm")
                        Divider()
                        field("Axial force", value: $scenario.axialKN, unit: "kN")
                        field("Torque", value: $scenario.torqueNm, unit: "N·m")
                        HStack { Text("Load level"); Spacer(); Text("\(Int(scenario.loadFraction * 100))%").monospacedDigit().foregroundStyle(accent) }
                        Slider(value: $scenario.loadFraction, in: 0...4, step: 0.01)
                        Text("100% uses the entered force and torque. Move the slider to explore the same loading path.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    card("Magnesium phosphate concrete", icon: "square.fill") { materialFields($scenario.mpc) }
                    card("Portland concrete", icon: "square.fill") { materialFields($scenario.opc) }
                }.frame(width: 340)
                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        resultCard("MAGNESIUM PHOSPHATE", result: mpcResult, color: accent)
                        resultCard("PORTLAND", result: opcResult, color: .blue)
                    }
                    card("Failure criterion along the loading path", icon: "chart.xyaxis.line") {
                        if scenario.valid {
                            utilizationChart.frame(height: 220)
                            HStack(spacing: 18) {
                                Label("Magnesium phosphate", systemImage: "line.diagonal").foregroundStyle(accent)
                                Label("Portland", systemImage: "line.diagonal").foregroundStyle(.blue)
                                Spacer()
                                Text("1.0 = idealized onset").foregroundStyle(.secondary)
                            }.font(.caption)
                        } else { Text("Correct the inputs to see the chart.").foregroundStyle(.secondary) }
                    }
                    card("Comparison at the selected load", icon: "equal.square") {
                        HStack(spacing: 0) {
                            metricColumn("Axial stress", mpcResult?.compressionMPa, opcResult?.compressionMPa, "MPa")
                            metricColumn("Surface shear", mpcResult?.shearMPa, opcResult?.shearMPa, "MPa")
                            metricColumn("Shortening", mpcResult?.shorteningMM, opcResult?.shorteningMM, "mm")
                            metricColumn("Twist", mpcResult?.twistDegrees, opcResult?.twistDegrees, "°")
                        }
                        Divider()
                        Text("Same geometry and load are applied to both materials. Strengths and stiffnesses are independent inputs; neither material is assumed inherently stronger.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    warning("Illustrative starting values only. Replace them with properties measured for each mix and curing age before drawing conclusions. This is a first-pass model, not a physical test or structural design approval.")
                }.frame(maxWidth: .infinity)
            }
            appearanceCard
        }
    }

    private func materialFields(_ material: Binding<Material>) -> some View {
        Group {
            field("Compression strength", value: material.compressiveMPa, unit: "MPa")
            field("Tensile strength", value: material.tensileMPa, unit: "MPa")
            field("Elastic modulus", value: material.modulusGPa, unit: "GPa")
            field("Poisson’s ratio", value: material.poisson, unit: "")
            field("Curing age", value: material.ageDays, unit: "days")
        }
    }

    private func field(_ title: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            TextField(title, value: value, format: .number.precision(.fractionLength(0...3)))
                .multilineTextAlignment(.trailing).frame(width: 82)
                .textFieldStyle(.roundedBorder)
            Text(unit).foregroundStyle(.tertiary).frame(width: 36, alignment: .leading)
        }
    }

    private func resultCard(_ title: String, result: Result?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption.bold()).foregroundStyle(color)
            Text(result.map { String(format: "%.2f×", $0.utilization) } ?? "—")
                .font(.system(size: 32, weight: .bold, design: .rounded)).monospacedDigit()
            Text(result == nil ? "Invalid inputs" : result!.reachesCriterion ? "At or beyond idealized onset" : "Below idealized onset")
                .font(.caption).foregroundStyle(result?.reachesCriterion == true ? .orange : .secondary)
            Divider()
            HStack { Text("Axial-only capacity"); Spacer(); Text(result.map { String(format: "%.0f kN", $0.axialCapacityKN) } ?? "—") }
            HStack { Text("Torsion-only estimate"); Spacer(); Text(result.map { String(format: "%.0f N·m", $0.pureTorsionCapacityNm) } ?? "—") }
            HStack { Text("Path onset"); Spacer(); Text(onsetText(title == "PORTLAND" ? scenario.opc : scenario.mpc)) }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(inset)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3)))
    }

    private func onsetText(_ material: Material) -> String {
        guard let value = Physics.onsetFraction(material, scenario: scenario) else { return "—" }
        return String(format: "%.0f%%", value * 100)
    }

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let fraction: Double
        let utilization: Double
        let material: String
    }
    private var chartPoints: [ChartPoint] {
        stride(from: 0.0, through: 4.0, by: 0.05).flatMap { f -> [ChartPoint] in
            guard let a = Physics.evaluate(scenario.mpc, scenario: scenario, fraction: f),
                  let b = Physics.evaluate(scenario.opc, scenario: scenario, fraction: f) else { return [] }
            return [ChartPoint(fraction: f * 100, utilization: a.utilization, material: "MPC"),
                    ChartPoint(fraction: f * 100, utilization: b.utilization, material: "Portland")]
        }
    }
    private var utilizationChart: some View {
        Chart {
            RuleMark(y: .value("Onset", 1)).foregroundStyle(.orange.opacity(0.65)).lineStyle(StrokeStyle(dash: [4, 4]))
            RuleMark(x: .value("Selected", scenario.loadFraction * 100)).foregroundStyle(.secondary.opacity(0.55)).lineStyle(StrokeStyle(dash: [4, 4]))
            ForEach(chartPoints) { point in
                LineMark(x: .value("Load %", point.fraction), y: .value("Utilization", point.utilization), series: .value("Material", point.material))
                    .foregroundStyle(point.material == "MPC" ? accent : .blue)
                    .interpolationMethod(.linear)
            }
        }
        .chartXScale(domain: 0...400)
        .chartXAxisLabel("Applied loading path (%)")
        .chartYAxisLabel("Criterion / strength")
    }

    private func metricColumn(_ title: String, _ first: Double?, _ second: Double?, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(first.map { String(format: "%.3f %@", $0, unit) } ?? "—").foregroundStyle(accent)
            Text(second.map { String(format: "%.3f %@", $0, unit) } ?? "—").foregroundStyle(.blue)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var measuredView: some View {
        HStack(alignment: .top, spacing: 16) {
            card("Enter observed peak loads", icon: "pencil.line") {
                TextField("Specimen ID", text: $specimenID).textFieldStyle(.roundedBorder)
                Picker("Material", selection: $selectedMaterial) { Text("Magnesium phosphate").tag(0); Text("Portland").tag(1) }
                field("Peak axial load", value: $measuredAxialKN, unit: "kN")
                field("Peak torque", value: $measuredTorqueNm, unit: "N·m")
                Text("Use the specimen dimensions on the Compare screen. One or both measured loads may be entered.")
                    .font(.caption).foregroundStyle(.secondary)
            }.frame(width: 370)
            card("Calculated nominal stresses", icon: "function") {
                let observed = observedResult
                metricRow("Axial compression", observed?.compressionMPa, "MPa")
                metricRow("Maximum surface shear", observed?.shearMPa, "MPa")
                metricRow("Principal tension", observed?.principalTensionMPa, "MPa")
                metricRow("Principal compression", observed?.principalCompressionMPa, "MPa")
                Divider()
                Text("Observed failure does not identify a unique tensile strength under combined loading. Report the actual failure mode, setup, age, and raw instrument data with these calculations.")
                    .foregroundStyle(.secondary).font(.caption)
            }.frame(maxWidth: .infinity)
        }
    }

    private var observedResult: Result? {
        guard measuredAxialKN >= 0, measuredTorqueNm >= 0 else { return nil }
        var observed = scenario
        observed.axialKN = measuredAxialKN
        observed.torqueNm = measuredTorqueNm
        observed.loadFraction = 1
        return Physics.evaluate(selectedMaterial == 0 ? scenario.mpc : scenario.opc, scenario: observed)
    }

    private func metricRow(_ name: String, _ value: Double?, _ unit: String) -> some View {
        HStack { Text(name); Spacer(); Text(value.map { String(format: "%.3f %@", $0, unit) } ?? "—").monospacedDigit().foregroundStyle(accent) }
    }

    private var methodView: some View {
        VStack(alignment: .leading, spacing: 16) {
            card("What the app calculates", icon: "sum") {
                Text("For a uniform solid circular cylinder, A = πr² and J = πr⁴/2. Axial compression is P/A; maximum surface shear is Tr/J. Elastic shortening is PL/(AE), and twist is TL/(GJ), where G = E/[2(1 + ν)].")
                if showEquations {
                    Text("The surface principal stresses combine axial compression and torsional shear: σ₁ = −σ/2 + √[(σ/2)² + τ²]; the compression magnitude is σ/2 + √[(σ/2)² + τ²]. The displayed criterion is max(σ₁/fₜ, |σ₃|/f꜀).")
                }
                Text("The criterion is a transparent, simplified brittle onset estimate. It does not model cracking, confinement, nonlinear stiffness, strain rate, end friction, aggregate scale, size effects, fatigue, reinforcement, or post-peak response.")
            }
            card("Test interpretation", icon: "checkmark.seal") {
                Text("ASTM C39/C39M-26 addresses measured compressive strength of cylindrical concrete specimens. This software does not execute or certify an ASTM test. The torsion estimate uses circular-shaft mechanics; it is not labeled as a standard concrete torsion test.")
                Text("Magnesium phosphate and Portland concrete vary with mix design, specimen preparation, and curing age. Enter properties from comparable specimens; the initial values are only for exploring the interface.")
            }
            card("Research and app references", icon: "link") {
                source("ASTM C39/C39M-26 · compression test scope", "https://store.astm.org/c0039_c0039m-26.html")
                source("MIT OpenCourseWare · torsion of round shafts", "https://ocw.mit.edu/courses/16-01-unified-engineering-i-ii-iii-iv-fall-2005-spring-2006/1f1b4e82bae2ff8ce609bc96fe20eedb_sprh04.pdf")
                source("ASCE · MPC concrete mix and age effects", "https://ascelibrary.com/doi/10.1061/%28ASCE%29MT.1943-5533.0004075")
                source("Instron Bluehill Universal · guided methods and quick tests", "https://instron.com/en/products/materials-testing-software/bluehill-universal/")
                source("Instron Bluehill Central · traceable comparisons", "https://www.instron.com/en/products/materials-testing-software/bluehill-central/")
            }
        }
    }

    private func source(_ title: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) { Label(title, systemImage: "arrow.up.right").frame(maxWidth: .infinity, alignment: .leading) }
    }

    private var appearanceCard: some View {
        card("Personalize workspace", icon: "paintpalette") {
            HStack(spacing: 24) {
                Picker("Appearance", selection: $appearance) { Text("Dark").tag("Dark"); Text("Light").tag("Light") }.frame(width: 190)
                Picker("Accent", selection: $accentName) { ForEach(Accent.allCases, id: \.self) { Text($0.rawValue).tag($0.rawValue) } }.frame(width: 180)
                Toggle("Compact", isOn: $compact)
                Toggle("Larger text", isOn: $largeText)
                Toggle("Equations", isOn: $showEquations)
            }
        }
    }

    private func card<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon).font(.system(size: largeText ? 17 : 15, weight: .semibold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(inset)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.primary.opacity(0.08)))
    }

    private func warning(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .font(.caption).foregroundStyle(.orange)
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }

    private func saveSetup() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "concrete-setup.json"; panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try JSONEncoder().encode(scenario).write(to: url); status = "Saved setup." }
        catch { status = "Save failed: \(error.localizedDescription)" }
    }

    private func openSetup() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let loaded = try JSONDecoder().decode(Scenario.self, from: Data(contentsOf: url))
            guard loaded.valid else { status = "File has invalid values."; return }
            scenario = loaded; status = "Opened setup."
        } catch { status = "Open failed: \(error.localizedDescription)" }
    }

    private func exportCSV() {
        guard scenario.valid else { status = "Correct inputs before exporting."; return }
        let panel = NSSavePanel(); panel.nameFieldStringValue = "concrete-sweep.csv"; panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var lines = ["material,load_percent,axial_kN,torque_Nm,axial_stress_MPa,surface_shear_MPa,principal_tension_MPa,principal_compression_MPa,shortening_mm,twist_deg,criterion_ratio"]
        for material in [scenario.mpc, scenario.opc] {
            for step in 0...400 {
                let f = Double(step) / 100
                guard let r = Physics.evaluate(material, scenario: scenario, fraction: f) else { continue }
                let name = "\"\(material.name.replacingOccurrences(of: "\"", with: "\"\""))\""
                lines.append([name, "\(step)", "\(scenario.axialKN * f)", "\(scenario.torqueNm * f)", "\(r.compressionMPa)", "\(r.shearMPa)", "\(r.principalTensionMPa)", "\(r.principalCompressionMPa)", "\(r.shorteningMM)", "\(r.twistDegrees)", "\(r.utilization)"].joined(separator: ","))
            }
        }
        do { try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8); status = "Exported 802 rows." }
        catch { status = "Export failed: \(error.localizedDescription)" }
    }
}
