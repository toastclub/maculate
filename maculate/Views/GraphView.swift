//
//  GraphView.swift
//  maculate
//
//  Created by Evan Boehs on 11/25/24.
//

import SwiftUI
import Qalculate

struct PlotPoint: Sendable {
    let x: Double
    let y: Double
    let startsSegment: Bool
}

struct PlotData: Sendable {
    var points: [PlotPoint] = []
    var message = ""
}

private actor PlotSampler {
    static let shared = PlotSampler()

    func sample(expression: String, viewport: GraphViewport) -> PlotData {
        guard !Task.isCancelled else { return PlotData() }
        let result = sampleGraph(std.string(expression), viewport.minX, viewport.maxX, 1001)
        return PlotData(points: result.points.map {
            PlotPoint(x: $0.x, y: $0.y, startsSegment: $0.startsSegment)
        }, message: String(result.message))
    }
}

struct GraphViewport: Equatable, Sendable {
    var x = 0.0
    var y = 0.0
    var width = 20.0
    var height = 20.0

    var minX: Double { x - width / 2 }
    var maxX: Double { x + width / 2 }
    var minY: Double { y - height / 2 }
    var maxY: Double { y + height / 2 }

    func transformed(translation: CGSize = .zero, magnification: Double = 1, size: CGSize) -> Self {
        var result = self
        result.width = min(1e9, max(1e-9, width / magnification))
        result.height = min(1e9, max(1e-9, height / magnification))
        result.x = min(1e12, max(-1e12, x - translation.width / max(1, size.width) * width))
        result.y = min(1e12, max(-1e12, y + translation.height / max(1, size.height) * height))
        return result
    }
}

private struct PlotRequest: Equatable {
    let expression: String
    let viewport: GraphViewport
}

struct GraphView: View {
    let equation: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var viewport = GraphViewport()
    @State private var data = PlotData()
    @State private var isSampling = false
    @GestureState private var translation = CGSize.zero
    @GestureState private var magnification = 1.0

    private var surface: Color {
        colorScheme == .dark
            ? Color(red: 0.085, green: 0.091, blue: 0.105)
            : Color(red: 0.933, green: 0.935, blue: 0.941)
    }

    private var controlSize: CGFloat {
#if os(macOS)
        27
#else
        44
#endif
    }

    private var ink: Color {
        colorScheme == .dark
            ? Color(red: 0.65, green: 0.72, blue: 0.96)
            : Color(red: 0.29, green: 0.37, blue: 0.66)
    }

    var body: some View {
        GeometryReader { geometry in
            let displayed = viewport.transformed(translation: translation, magnification: magnification, size: geometry.size)
            Canvas { context, size in
                draw(context: context, size: size, viewport: displayed)
            }
            .onAppear { fitViewport(to: geometry.size) }
            .onChange(of: geometry.size) { _, size in fitViewport(to: size) }
            .contentShape(Rectangle())
            .gesture(DragGesture()
                .updating($translation) { value, state, _ in state = value.translation }
                .onEnded { value in
                    viewport = viewport.transformed(translation: value.translation, size: geometry.size)
                })
            .simultaneousGesture(MagnifyGesture()
                .updating($magnification) { value, state, _ in state = value.magnification }
                .onEnded { value in
                    viewport = viewport.transformed(magnification: value.magnification, size: geometry.size)
                })
            .accessibilityIdentifier("graphResult")
            .accessibilityLabel("Function graph")
            .accessibilityValue(data.message.isEmpty ? "\(data.points.count) sampled points" : data.message)
#if os(macOS)
            .accessibilityHint("Drag to pan. Pinch to zoom. Zoom and reset buttons are in the lower right.")
#else
            .accessibilityHint("Drag to pan. Pinch to zoom. The reset button is in the lower right.")
#endif
            .help("Drag to pan · Pinch to zoom")
        }
        .frame(height: 232)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(surface.shadow(.inner(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.09), radius: 3, x: 0, y: 2)))
        }
        .overlay(alignment: .center) {
            if !data.message.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 20, weight: .light))
                    Text(data.message)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                }
                .foregroundStyle(.secondary)
                .padding(20)
                .frame(maxWidth: 300)
                .background(surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 6) {
#if os(macOS)
                graphControl("Zoom out", symbol: "minus") {
                    viewport = viewport.transformed(magnification: 0.5, size: .zero)
                }
                graphControl("Zoom in", symbol: "plus") {
                    viewport = viewport.transformed(magnification: 2, size: .zero)
                }
#endif
                graphControl("Reset", symbol: "arrow.counterclockwise") {
                    viewport = GraphViewport(width: 20 * viewport.width / viewport.height)
                }
            }
            .padding(10)
        }
        .overlay(alignment: .topTrailing) {
            if isSampling {
                ProgressView().controlSize(.mini).padding(12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LinearGradient(colors: [
                    .black.opacity(colorScheme == .dark ? 0.4 : 0.13),
                    .white.opacity(colorScheme == .dark ? 0.07 : 0.8)
                ], startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
                .allowsHitTesting(false)
        }
        .onHover { isHovered = $0 }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .onChange(of: equation) { _, _ in data = PlotData() }
        .task(id: PlotRequest(expression: equation, viewport: viewport)) {
            isSampling = true
            do { try await Task.sleep(for: .milliseconds(180)) }
            catch { return }
            let sampled = await PlotSampler.shared.sample(expression: equation, viewport: viewport)
            guard !Task.isCancelled else { return }
            data = sampled
            isSampling = false
        }
    }

    private func fitViewport(to size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        viewport.width = viewport.height * size.width / size.height
    }

    private func graphControl(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(isHovered ? 0.85 : 0.65))
                .frame(width: controlSize, height: controlSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(GlassControlSurface())
        .accessibilityLabel(label)
        .help(label)
    }

    private func ticks(min: Double, max: Double) -> [Double] {
        let roughStep = (max - min) / 7
        let base = pow(10, floor(log10(roughStep)))
        let step = base * (roughStep / base < 2 ? 2 : roughStep / base < 5 ? 5 : 10)
        let start = ceil(min / step) * step
        return (0..<20).map { start + Double($0) * step }.filter { $0 <= max }
    }

    private func draw(context: GraphicsContext, size: CGSize, viewport v: GraphViewport) {
        let rect = CGRect(origin: .zero, size: size)
        func point(_ x: Double, _ y: Double) -> CGPoint {
            // Keep extreme samples within a safe drawing range before clipping.
            let px = (x - v.minX) / v.width * size.width
            let py = size.height - (y - v.minY) / v.height * size.height
            return CGPoint(x: min(1e7, max(-1e7, px)), y: min(1e7, max(-1e7, py)))
        }
        let xTicks = ticks(min: v.minX, max: v.maxX)
        let yTicks = ticks(min: v.minY, max: v.maxY)
        var grid = Path()
        for x in xTicks {
            let px = point(x, 0).x
            grid.move(to: CGPoint(x: px, y: 0))
            grid.addLine(to: CGPoint(x: px, y: size.height))
        }
        for y in yTicks {
            let py = point(0, y).y
            grid.move(to: CGPoint(x: 0, y: py))
            grid.addLine(to: CGPoint(x: size.width, y: py))
        }
        context.stroke(grid, with: .color(.primary.opacity(colorScheme == .dark ? 0.065 : 0.055)), lineWidth: 0.5)
        var axes = Path()
        let origin = point(0, 0)
        if v.minX <= 0 && v.maxX >= 0 {
            axes.move(to: CGPoint(x: origin.x, y: 0))
            axes.addLine(to: CGPoint(x: origin.x, y: size.height))
        }
        if v.minY <= 0 && v.maxY >= 0 {
            axes.move(to: CGPoint(x: 0, y: origin.y))
            axes.addLine(to: CGPoint(x: size.width, y: origin.y))
        }
        context.stroke(axes, with: .color(.primary.opacity(0.18)), lineWidth: 0.75)

        var curve = Path()
        for sample in data.points {
            let p = point(sample.x, sample.y)
            if sample.startsSegment { curve.move(to: p) }
            else { curve.addLine(to: p) }
        }
        var clipped = context
        clipped.clip(to: Path(rect))
        clipped.stroke(curve, with: .color(ink), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

        let labelY = min(size.height - controlSize - 28, max(15, origin.y + 12))
        let labelX = min(size.width - 38, max(12, origin.x + 8))
        func label(_ value: Double) -> Text {
            Text(value.formatted(.number.precision(.significantDigits(1...3))))
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.primary.opacity(0.42))
        }
        for x in xTicks where abs(x) > v.width * 1e-8 {
            let px = point(x, 0).x
            if px > 20 && px < size.width - 20 {
                context.draw(label(x), at: CGPoint(x: px, y: labelY))
            }
        }
        for y in yTicks where abs(y) > v.height * 1e-8 {
            let py = point(0, y).y
            if py > 16 && py < size.height - 38 {
                context.draw(label(y), at: CGPoint(x: labelX, y: py), anchor: .leading)
            }
        }
        if rect.insetBy(dx: 16, dy: 24).contains(origin) {
            context.draw(label(0), at: CGPoint(x: origin.x - 10, y: origin.y + 12))
        }
    }
}

#Preview {
    GraphView(equation: "x^2")
}
