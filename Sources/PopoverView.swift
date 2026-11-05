import AppKit
import SwiftUI

struct PopoverView: View {

    @ObservedObject var engine: PamodoroEngine
    var onQuit: () -> Void

    private enum Field: Hashable {
        case work
        case rest
    }

    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) private var colorScheme

    /// 表盘 hover 状态（用 ObservableObject 而不是 @State：swiftc 直接编译时 SwiftUI 宏插件不可用）
    private final class HoverState: ObservableObject {
        @Published var isHovering = false
    }

    @ObservedObject private var hover = HoverState()
    @ObservedObject private var flash = ResetFlash()

    private var tint: Color { .accentColor }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 14)

            ring
                .padding(.top, 10)

            primaryButton
                .padding(.horizontal, 18)
                .padding(.top, 14)

            secondaryButtons
                .padding(.horizontal, 18)
                .padding(.top, 8)

            Divider()
                .padding(.top, 14)
                .padding(.horizontal, 18)

            settings
                .padding(.horizontal, 18)
                .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 18)

            footer
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .frame(width: 300)
        .onAppear { focusedField = nil }
        .onDisappear {
            focusedField = nil
            PopoverCursor.reset()
        }
    }

    // MARK: - 头部

    private var header: some View {
        HStack(alignment: .center, spacing: 7) {
            titleText
            statusLight

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 11, weight: .medium))
                Text("今日 \(engine.completedToday) 个")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
        }
    }

    /// 刻字效果的标题：深色字面 + 下缘高光 + 上缘暗影
    private var titleText: some View {
        Text("Pamodoro")
            .font(.system(size: 13, weight: .semibold))
            .kerning(1.1)
            .foregroundStyle(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.70), Color(white: 0.90)]
                        : [Color(white: 0.30), Color(white: 0.48)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: colorScheme == .dark
                    ? Color.black.opacity(0.85)
                    : Color.white.opacity(0.95),
                    radius: 0.6, x: 0, y: 0.9)
            .shadow(color: colorScheme == .dark
                    ? Color.white.opacity(0.14)
                    : Color.black.opacity(0.22),
                    radius: 0.5, x: 0, y: -0.8)
    }

    /// 运行状态灯：计时中绿、暂停/待机红
    private var statusLight: some View {
        let color: Color = engine.isRunning ? Color(red: 0.18, green: 0.72, blue: 0.36)
                                            : Color(red: 0.94, green: 0.26, blue: 0.24)
        return ZStack {
            Circle()
                .fill(color.opacity(0.22))
                .frame(width: 13, height: 13)
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
        .animation(.easeInOut(duration: 0.25), value: engine.isRunning)
    }

    // MARK: - 环形计时（点击表盘 = 开始 / 暂停 / 继续）

    private var ring: some View {
        Button(action: startOrPause) {
            ringBody
        }
        .buttonStyle(RingPressStyle())
        .help("点击表盘：开始 / 暂停 / 继续")
        .onHover { hovering in
            hover.isHovering = hovering
            PopoverCursor.set(hovering)
        }
    }

    private var ringBody: some View {
        ZStack {
            Circle()
                .fill(Color(nsColor: .textBackgroundColor))

            if ProcessInfo.processInfo.environment["POMODORO_NO_LIQUID"] == nil {
                DialLiquid()
            }

            Circle()
                .stroke(Color.primary.opacity(hover.isHovering ? 0.14 : 0.09), lineWidth: 10)

            if engine.progress > 0.002 {
                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(tint,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: engine.progress)
            }

            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(engine.timeText)
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .fixedSize()
                    Text(".\(engine.fractionText)")
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .opacity(0.55)
                        .fixedSize()
                }
                .foregroundStyle(tint)

                Text(hover.isHovering ? engine.ringHint : engine.stateCaption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 170, height: 170)
        .contentShape(Circle())
        .scaleEffect(hover.isHovering ? 1.012 : 1)
        .animation(.easeOut(duration: 0.15), value: hover.isHovering)
    }

    /// 按下时轻微缩一下，给点击反馈
    private struct RingPressStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .opacity(configuration.isPressed ? 0.92 : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }

    /// 开始 / 暂停 / 继续（每次点击都有单音反馈）
    private func startOrPause() {
        SoundFX.shared.click()
        engine.primaryAction()
    }

    // MARK: - 主操作

    private var primaryButton: some View {
        Button(action: startOrPause) {
            Label(engine.primaryTitle, systemImage: engine.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .clipShape(Capsule())
    }

    private var secondaryButtons: some View {
        HStack(spacing: 10) {
            Button {
                SoundFX.shared.click()
                engine.reset()
            } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .clipShape(Capsule())

            Button {
                SoundFX.shared.click()
                engine.skip()
            } label: {
                Label("跳过", systemImage: "forward.end")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .clipShape(Capsule())
        }
    }

    // MARK: - 设置

    private var settings: some View {
        VStack(spacing: 0) {
            row("计时时长") {
                minutesEditor(workMinutesBinding, field: .work, step: 5)
            }

            row("休息时长") {
                minutesEditor(restMinutesBinding, field: .rest)
            }

            row("自动循环") {
                Toggle("", isOn: $engine.autoLoop)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }

            row("循环次数") {
                HStack(spacing: 6) {
                    Text(engine.autoLoop ? "\(engine.completedRounds)/\(engine.roundLimit) 轮"
                                         : "\(engine.roundLimit) 轮")
                        .font(.system(size: 12))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Stepper("", value: roundLimitBinding, in: 1...99)
                        .labelsHidden()
                        .controlSize(.small)
                }
                .help("自动循环最多跑几轮，跑满后自动停止")
            }
        }
    }

    private func row<Content: View>(_ title: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            content()
        }
        .frame(height: 34)
    }

    /// 任意分钟输入：输入框（可直接键入）+ 步进器（±1 分钟），范围 1–180
    private func minutesEditor(_ binding: Binding<Int>, field: Field, step: Int = 1) -> some View {
        HStack(spacing: 6) {
            TextField("", value: binding, format: .number)
                .focused($focusedField, equals: field)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 50)
                .labelsHidden()

            Text("分钟")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Stepper("", value: binding, in: 1...180, step: step)
                .labelsHidden()
                .controlSize(.small)
        }
        .help("1–180 分钟，可直接输入任意数值")
    }

    private var roundLimitBinding: Binding<Int> {
        Binding(
            get: { engine.roundLimit },
            set: { engine.roundLimit = min(99, max(1, $0)) }
        )
    }

    private var workMinutesBinding: Binding<Int> {
        Binding(
            get: { engine.workMinutes },
            set: { engine.workMinutes = min(180, max(1, $0)) }
        )
    }

    private var restMinutesBinding: Binding<Int> {
        Binding(
            get: { engine.restMinutes },
            set: { engine.restMinutes = min(180, max(1, $0)) }
        )
    }

    // MARK: - 底部

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                SoundFX.shared.click()
                engine.resetCounters()
                flash.didReset = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    flash.didReset = false
                }
            } label: {
                Label(flash.didReset ? "已重置" : "重置计数",
                      systemImage: flash.didReset ? "checkmark" : "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .clipShape(Capsule())
            .help("清零循环轮数与今日完成数")

            Spacer(minLength: 0)

            Button(action: onQuit) {
                Label("退出", systemImage: "power")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .clipShape(Capsule())
        }
    }
}

/// 「重置计数」按钮的短暂确认态（用 ObservableObject 代替 @State：swiftc 直接编译时宏插件不可用）
final class ResetFlash: ObservableObject {
    @Published var didReset = false
}

/// 表盘 hover 的光标管理。
/// `NSCursor.push/pop` 必须成对：面板是 `.transient`，鼠标停在表盘上时点别处会让面板直接消失，
/// `onHover(false)` 不会触发，于是手型光标一直挂在栈上。这里记一个开关，并在面板关闭时强制复位。
enum PopoverCursor {

    private static var isPushed = false

    static func set(_ hovering: Bool) {
        if hovering, !isPushed {
            NSCursor.pointingHand.push()
            isPushed = true
        } else if !hovering, isPushed {
            NSCursor.pop()
            isPushed = false
        }
    }

    /// 面板关闭时调用：无论 hover 有没有正常退出，都把光标还原
    static func reset() {
        guard isPushed else { return }
        NSCursor.pop()
        isPushed = false
        NSCursor.arrow.set()
    }
}
