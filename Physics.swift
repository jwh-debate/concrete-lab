import Foundation

struct Material: Codable, Equatable {
    var name: String
    var compressiveMPa: Double
    var tensileMPa: Double
    var modulusGPa: Double
    var poisson: Double
    var ageDays: Double

    var valid: Bool {
        compressiveMPa > 0 && tensileMPa > 0 && modulusGPa > 0 && poisson > -1 && poisson < 0.5 && ageDays > 0
    }
}

struct Scenario: Codable, Equatable {
    var diameterMM: Double = 100
    var lengthMM: Double = 200
    var axialKN: Double = 120
    var torqueNm: Double = 250
    var loadFraction: Double = 1
    var mpc: Material = Material(name: "Magnesium phosphate", compressiveMPa: 45, tensileMPa: 4, modulusGPa: 25, poisson: 0.20, ageDays: 7)
    var opc: Material = Material(name: "Portland", compressiveMPa: 35, tensileMPa: 3, modulusGPa: 30, poisson: 0.20, ageDays: 28)

    var valid: Bool {
        diameterMM > 0 && lengthMM > 0 && axialKN >= 0 && torqueNm >= 0 &&
        loadFraction >= 0 && loadFraction <= 4 && mpc.valid && opc.valid
    }
}

struct Result {
    let compressionMPa: Double
    let shearMPa: Double
    let principalTensionMPa: Double
    let principalCompressionMPa: Double
    let shorteningMM: Double
    let twistDegrees: Double
    let utilization: Double
    let axialCapacityKN: Double
    let pureTorsionCapacityNm: Double

    var reachesCriterion: Bool { utilization >= 1 }
}

enum Physics {
    // SI internally: N, m, Pa. Input strengths are MPa and modulus is GPa.
    static func evaluate(_ material: Material, scenario: Scenario, fraction: Double? = nil) -> Result? {
        guard scenario.valid, fraction.map({ $0 >= 0 }) ?? true else { return nil }
        let f = fraction ?? scenario.loadFraction
        let radius = scenario.diameterMM / 2_000
        let length = scenario.lengthMM / 1_000
        let area = Double.pi * radius * radius
        let polar = Double.pi * pow(radius, 4) / 2
        let force = scenario.axialKN * 1_000 * f
        let torque = scenario.torqueNm * f
        let sigma = force / area
        let tau = torque * radius / polar
        let principalRadius = hypot(sigma / 2, tau)
        let tension = -sigma / 2 + principalRadius
        let compression = sigma / 2 + principalRadius
        let e = material.modulusGPa * 1e9
        let g = e / (2 * (1 + material.poisson))
        let shortening = force * length / (area * e) * 1_000
        let twist = torque * length / (g * polar) * 180 / Double.pi
        let utilization = max(tension / (material.tensileMPa * 1e6), compression / (material.compressiveMPa * 1e6))
        return Result(
            compressionMPa: sigma / 1e6,
            shearMPa: tau / 1e6,
            principalTensionMPa: tension / 1e6,
            principalCompressionMPa: compression / 1e6,
            shorteningMM: shortening,
            twistDegrees: twist,
            utilization: utilization,
            axialCapacityKN: material.compressiveMPa * 1e6 * area / 1_000,
            pureTorsionCapacityNm: material.tensileMPa * 1e6 * polar / radius
        )
    }

    static func onsetFraction(_ material: Material, scenario: Scenario) -> Double? {
        guard scenario.valid else { return nil }
        guard (scenario.axialKN > 0 || scenario.torqueNm > 0) else { return nil }
        var lower = 0.0
        var upper = 1.0
        while upper < 1_000_000_000, (evaluate(material, scenario: scenario, fraction: upper)?.utilization ?? 0) < 1 {
            upper *= 2
        }
        guard (evaluate(material, scenario: scenario, fraction: upper)?.utilization ?? 0) >= 1 else { return nil }
        for _ in 0..<70 {
            let mid = (lower + upper) / 2
            if (evaluate(material, scenario: scenario, fraction: mid)?.utilization ?? 0) >= 1 { upper = mid }
            else { lower = mid }
        }
        return upper
    }
}
