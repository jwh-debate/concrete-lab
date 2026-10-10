# Concrete Lab

A local macOS app for comparing the calculated response of solid cylindrical magnesium phosphate and Portland concrete specimens under axial compression and torsion. The starting material values are examples for exploring the app, not measurements.

## Download and install

**Requirements:** an Apple silicon Mac (M1 or newer) running macOS 14 or later.

1. [Download Concrete Lab for macOS (.dmg)](https://github.com/jwh-debate/concrete-lab/releases/latest/download/ConcreteLab-1.0-macOS-arm64.dmg).
2. Open the downloaded DMG and drag **ConcreteLab.app** onto the **Applications** shortcut in its window.
3. Eject the **Concrete Lab** disk image, then open **Concrete Lab** from Applications.

This release is **not Apple notarized**. If macOS blocks the first launch, try to open the app once, then go to **System Settings → Privacy & Security**, scroll to **Security**, and select **Open Anyway** for Concrete Lab. Confirm **Open** when prompted. Only do this for the DMG downloaded from this repository. [Apple's instructions](https://support.apple.com/en-us/102445) explain this one-app exception. You do not need to turn off Gatekeeper.

The [Releases page](https://github.com/jwh-debate/concrete-lab/releases) has the download and version details. The source files are on this repository's **Code** tab.

## Start using it

1. Open **Compare**. Enter the specimen **diameter** (mm) and **length** (mm), then the applied **axial force** (kN) and **torque** (N·m). The same geometry and load are used for both materials.
2. Replace each material's example **compression strength** (MPa), **tensile strength** (MPa), **elastic modulus** (GPa), **Poisson's ratio**, and **curing age** (days) with measured or justified values. Use specimens with comparable mix, preparation, and curing conditions.
3. Read each material's **criterion / strength** value. Below **1.0×** is below the app's idealized onset threshold; **1.0×** or more reaches or exceeds it. The chart compares both materials along the entered force and torque loading path.
4. Move **Load level** to change force and torque together. **100%** means the exact force and torque you entered; **200%** doubles both. This is an exploration control, not a test-machine control.

Use **Measured data** to enter a specimen ID, select a material, and record a measured peak compression load and/or torque. The app converts those loads to nominal stresses using the dimensions on **Compare**. It does not infer a unique tensile strength or failure mode from a combined-load test.

Use the **Workspace** buttons in the sidebar to **Save setup…** as JSON, **Open setup…** from a saved JSON file, or **Export sweep CSV…** for a 0–400% loading sweep. The controls at the bottom of **Compare** change appearance, accent color, spacing, text size, and equation visibility. **Model & sources** explains the equations in the app.

## Model and limits

The app uses SI units internally, a homogeneous isotropic linear elastic solid cylinder, and small deformation mechanics: `A = πr²`, `J = πr⁴/2`, `σ = P/A`, `τ = Tr/J`, `δ = PL/(AE)`, `θ = TL/(GJ)`, and `G = E/[2(1+ν)]`. A simplified principal stress criterion checks tensile and compressive strengths at the surface. Chart values beyond criterion **1.0** are mathematical extrapolations, not plausible elastic deformation. This is not a fracture model or a test-machine controller.

Measured cylinder compression testing should follow applicable laboratory standards and trained procedures. The app does not claim ASTM certification or a standardized concrete torsion method. Mix design, curing, specimen preparation, geometry, and loading conditions strongly affect measured values.

## Research references

- [ASTM C39/C39M-26 compression test scope](https://store.astm.org/c0039_c0039m-26.html)
- [MIT OpenCourseWare torsion of circular shafts](https://ocw.mit.edu/courses/16-01-unified-engineering-i-ii-iii-iv-fall-2005-spring-2006/1f1b4e82bae2ff8ce609bc96fe20eedb_sprh04.pdf)
- [ASCE study of magnesium phosphate concrete mix and curing variables](https://ascelibrary.com/doi/10.1061/%28ASCE%29MT.1943-5533.0004075)
- [Instron Bluehill Universal interface reference](https://instron.com/en/products/materials-testing-software/bluehill-universal/)
- [Instron Bluehill Central comparison and traceability reference](https://www.instron.com/en/products/materials-testing-software/bluehill-central/)

## Build from source

To rebuild after installing Xcode and completing its initial setup, start with an existing `ConcreteLab.app` bundle from the DMG, then run this command from the repository folder (adjust the app path if needed):

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -target arm64-apple-macosx14.0 -O Physics.swift ConcreteLab.swift \
  -o ConcreteLab.app/Contents/MacOS/ConcreteLab
```

For ordinary use, the DMG is all you need; Xcode and the source files are not required.
