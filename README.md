# Concrete Lab

A native, local macOS app for exploring the response of solid cylindrical magnesium phosphate and Portland concrete specimens under axial compression and torsion. The supplied material values are illustrative, not representative measurements.

## Use

Open `ConcreteLab.app`. Enter the geometry, applied force and torque, and measured material properties for both mixes. The load slider scales force and torque together. The chart shows a simplified failure criterion along that loading path. The **Measured data** screen converts recorded peak loads to nominal stresses. The sidebar saves and opens setup JSON files and exports a 0–400% sweep as CSV.

Appearance, accent color, spacing, text size, and equation visibility are adjustable at the bottom of the comparison screen.

## Physics and limits

The app uses SI units internally, a homogeneous isotropic linear elastic solid cylinder, and small deformation mechanics: `A = πr²`, `J = πr⁴/2`, `σ = P/A`, `τ = Tr/J`, `δ = PL/(AE)`, `θ = TL/(GJ)`, and `G = E/[2(1+ν)]`. A simplified principal stress criterion checks tensile and compressive strengths at the surface. The chart stops representing physically plausible elastic deformation after that criterion reaches 1; values beyond it are mathematical extrapolations to show the boundary. It is not a fracture model or a test-machine controller.

Measured cylinder compression testing should follow applicable laboratory standards and trained procedures. The app does not claim ASTM certification or a standardized concrete torsion method. Mix design, curing, specimen preparation, geometry, and loading conditions strongly affect measured values. Always enter properties from comparable specimens.

## Research references

- [ASTM C39/C39M-26 compression test scope](https://store.astm.org/c0039_c0039m-26.html)
- [MIT OpenCourseWare torsion of circular shafts](https://ocw.mit.edu/courses/16-01-unified-engineering-i-ii-iii-iv-fall-2005-spring-2006/1f1b4e82bae2ff8ce609bc96fe20eedb_sprh04.pdf)
- [ASCE study of magnesium phosphate concrete mix and curing variables](https://ascelibrary.com/doi/10.1061/%28ASCE%29MT.1943-5533.0004075)
- [Instron Bluehill Universal interface reference](https://instron.com/en/products/materials-testing-software/bluehill-universal/)
- [Instron Bluehill Central comparison and traceability reference](https://www.instron.com/en/products/materials-testing-software/bluehill-central/)

## Build

The included app is built for Apple silicon, macOS 14+. To rebuild from source with Xcode's Swift compiler:

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -target arm64-apple-macosx14.0 -O Physics.swift ConcreteLab.swift \
  -o ConcreteLab.app/Contents/MacOS/ConcreteLab
```
