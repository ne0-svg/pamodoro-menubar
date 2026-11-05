import SwiftUI

/// 表盘背景里的水银：一个不规则、缓慢流动的液团 + 一颗绕行的卫星液滴。
/// 边缘保持柔化（不出现硬轮廓），靠形变和位移体现「液体」。
///
/// 性能说明（2026-11-05 实测）：`isActive` 为 false 时不建立 `TimelineView` 调度。
/// NSPopover 收起后 SwiftUI 视图仍然存活，逐帧动画会一直跑下去；
/// 实测把液体整个关掉 CPU 几乎不变，所以真正贵的是整块面板的高频重排，
/// 这里只是顺手把「看不见时的无效渲染」省掉。
struct DialLiquid: View {

    /// 面板是否可见
    var isActive: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if isActive {
                TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                    droplet(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                // 面板收起：只画一帧静态画面，不驱动时间轴
                droplet(at: 0)
            }
        }
        .clipShape(Circle())
        .allowsHitTesting(false)
    }

    private func droplet(at t: TimeInterval) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let dialRadius = min(size.width, size.height) / 2
            let dark = colorScheme == .dark

            let body = dark ? Color(white: 0.94) : Color(red: 0.44, green: 0.51, blue: 0.63)
            let alpha: Double = dark ? 0.34 : 0.46

            // 主液团：漂移 + 不规则形变
            let cx = center.x + CGFloat(sin(t * 0.21) * dialRadius * 0.16)
            let cy = center.y + CGFloat(cos(t * 0.17) * dialRadius * 0.14)
            let baseR = dialRadius * 0.46

            var path = Path()
            let steps = 180
            for i in 0...steps {
                let angle = Double(i) / Double(steps) * 2 * Double.pi
                let wobble = 1.0
                    + 0.12 * sin(2 * angle + t * 0.9)
                    + 0.08 * sin(3 * angle - t * 0.7)
                    + 0.05 * sin(5 * angle + t * 1.3)
                let r = baseR * wobble
                let point = CGPoint(x: cx + CGFloat(cos(angle) * r),
                                    y: cy + CGFloat(sin(angle) * r))
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()

            let bodyGradient = Gradient(colors: [
                body.opacity(alpha),
                body.opacity(alpha * 0.55),
                body.opacity(0.0),
            ])
            context.fill(path, with: .radialGradient(bodyGradient,
                                                     center: CGPoint(x: cx, y: cy),
                                                     startRadius: 0,
                                                     endRadius: baseR * 1.18))

            // 卫星液滴：绕着主液团缓慢绕行
            let satelliteRadius = baseR * (0.20 + 0.04 * sin(t * 0.5))
            let sx = cx + CGFloat(cos(t * 0.31) * baseR * 0.92)
            let sy = cy + CGFloat(sin(t * 0.27) * baseR * 0.92)
            let satelliteGradient = Gradient(colors: [
                body.opacity(alpha * 0.9),
                body.opacity(0.0),
            ])
            context.fill(Path(ellipseIn: CGRect(x: sx - satelliteRadius,
                                                y: sy - satelliteRadius,
                                                width: satelliteRadius * 2,
                                                height: satelliteRadius * 2)),
                         with: .radialGradient(satelliteGradient,
                                               center: CGPoint(x: sx, y: sy),
                                               startRadius: 0,
                                               endRadius: satelliteRadius))

            // 高光：跟随主液团缓慢移动，增加水银的镜面感
            var highlight = context
            highlight.addFilter(.blur(radius: 4))
            let hlRadius = baseR * 0.30
            let hlCenter = CGPoint(x: cx - baseR * 0.30, y: cy - baseR * 0.28)
            let hlGradient = Gradient(colors: [
                Color.white.opacity(dark ? 0.16 : 0.55),
                Color.white.opacity(0.0),
            ])
            highlight.fill(Path(ellipseIn: CGRect(x: hlCenter.x - hlRadius,
                                                  y: hlCenter.y - hlRadius,
                                                  width: hlRadius * 2,
                                                  height: hlRadius * 2)),
                           with: .radialGradient(hlGradient,
                                                 center: hlCenter,
                                                 startRadius: 0,
                                                 endRadius: hlRadius))
        }
        .blur(radius: 3)
    }
}
