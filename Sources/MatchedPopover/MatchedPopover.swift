import SwiftUI

// MARK: - Matched Popover (Reusable)

public extension View {
    /// Apply this once on a common parent (usually a screen root) to enable matched popovers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct PopoverView: View {
    ///     enum PopoverTarget: String {
    ///         case view1
    ///         case view2
    ///         case view3
    ///
    ///         var anchor: UnitPoint {
    ///             switch self {
    ///             case .view1: .leading
    ///             case .view2: .top
    ///             case .view3: .bottom
    ///             }
    ///         }
    ///     }
    ///
    ///     @State private var selection: PopoverTarget?
    ///
    ///     var body: some View {
    ///         VStack(spacing: 40) {
    ///             HStack {
    ///                 Spacer()
    ///                 button(.view1)
    ///                     .matchedPopoverSource(
    ///                         id: PopoverTarget.view1,
    ///                         anchor: PopoverTarget.view1.anchor
    ///                     )
    ///                     .padding()
    ///             }
    ///
    ///             button(.view2)
    ///                 .matchedPopoverSource(
    ///                     id: PopoverTarget.view2,
    ///                     anchor: PopoverTarget.view2.anchor
    ///                 )
    ///
    ///             button(.view3)
    ///                 .matchedPopoverSource(
    ///                     id: PopoverTarget.view3,
    ///                     anchor: PopoverTarget.view3.anchor
    ///                 )
    ///         }
    ///         .frame(maxHeight: .infinity)
    ///         .ignoresSafeArea()
    ///         .matchedPopover(
    ///             selection: $selection,
    ///             anchor: { $0.anchor }
    ///         ) { id in
    ///             Text("Popover for \(String(describing: id))")
    ///                 .padding()
    ///                 .glassEffect()
    ///                 .padding()
    ///                 .fontWeight(.semibold)
    ///                 .fontDesign(.rounded)
    ///         }
    ///     }
    ///
    ///     private func button(_ target: PopoverTarget) -> some View {
    ///         Button(target.rawValue) {
    ///             selection = (selection == target) ? nil : target
    ///         }
    ///         .buttonStyle(.borderedProminent)
    ///     }
    /// }
    /// ```
    func matchedPopover<ID: Hashable, Popover: View>(
        selection: Binding<ID?>,
        anchor: @escaping (ID) -> UnitPoint = { _ in .top },
        @ViewBuilder popover: @escaping (ID) -> Popover
    ) -> some View {
        modifier(
            MatchedPopoverContainerModifier(
                selection: selection,
                sourceAnchor: anchor,
                popover: popover
            )
        )
    }
    
    /// Apply this to any view that should act as a popover target (anchor only).
    ///
    ///  ## Example
    ///
    /// ```swift
    /// struct PopoverView: View {
    ///     enum PopoverTarget: String {
    ///         case view1
    ///         case view2
    ///         case view3
    ///
    ///         var anchor: UnitPoint {
    ///             switch self {
    ///             case .view1: .leading
    ///             case .view2: .top
    ///             case .view3: .bottom
    ///             }
    ///         }
    ///     }
    ///
    ///     @State private var selection: PopoverTarget?
    ///
    ///     var body: some View {
    ///         VStack(spacing: 40) {
    ///             HStack {
    ///                 Spacer()
    ///                 button(.view1)
    ///                     .matchedPopoverSource(
    ///                         id: PopoverTarget.view1,
    ///                         anchor: PopoverTarget.view1.anchor
    ///                     )
    ///                     .padding()
    ///             }
    ///
    ///             button(.view2)
    ///                 .matchedPopoverSource(
    ///                     id: PopoverTarget.view2,
    ///                     anchor: PopoverTarget.view2.anchor
    ///                 )
    ///
    ///             button(.view3)
    ///                 .matchedPopoverSource(
    ///                     id: PopoverTarget.view3,
    ///                     anchor: PopoverTarget.view3.anchor
    ///                 )
    ///         }
    ///         .frame(maxHeight: .infinity)
    ///         .ignoresSafeArea()
    ///         .matchedPopover(
    ///             selection: $selection,
    ///             anchor: { $0.anchor }
    ///         ) { id in
    ///             Text("Popover for \(String(describing: id))")
    ///                 .padding()
    ///                 .glassEffect()
    ///                 .padding()
    ///                 .fontWeight(.semibold)
    ///                 .fontDesign(.rounded)
    ///         }
    ///     }
    ///
    ///     private func button(_ target: PopoverTarget) -> some View {
    ///         Button(target.rawValue) {
    ///             selection = (selection == target) ? nil : target
    ///         }
    ///         .buttonStyle(.borderedProminent)
    ///     }
    /// }
    /// ```
    func matchedPopoverSource<ID: Hashable>(
        id: ID,
        anchor: UnitPoint = .bottom
    ) -> some View {
        modifier(
            MatchedPopoverSourceModifier(
                id: id,
                sourceAnchor: anchor
            )
        )
    }
}

/// Source modifier that attaches a view to the shared namespace.
/// Use it on any "anchor" view that should open/drive the popover.
private struct MatchedPopoverSourceModifier<ID: Hashable>: ViewModifier {
    
    let id: ID
    let sourceAnchor: UnitPoint
    
    @Environment(\.matchedPopoverNamespace) private var ns
    
    func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(
                id: id,
                in: ns ?? Namespace().wrappedValue,
                anchor: sourceAnchor
            )
    }
}

/// Container modifier that:
/// - Creates a shared `Namespace`
/// - Draws the popover overlay
/// - Injects the namespace + a selection setter into the environment
private struct MatchedPopoverContainerModifier<ID: Hashable, Popover: View>: ViewModifier {
    
    /// External source of truth (what should be shown).
    @Binding var selection: ID?
    
    /// Anchor used by the *source* view for matched-geometry positioning.
    /// The popover anchor is derived as `sourceAnchor(id).opposite`.
    let sourceAnchor: (ID) -> UnitPoint
    
    /// Builds the popover content.
    @ViewBuilder var popover: (ID) -> Popover
    
    /// Internally presented id (what is currently rendered in the overlay).
    @State private var presented: ID? = nil
    
    @Namespace private var ns
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
                .overlay {
                    // Full-screen tap-catcher: tap anywhere to dismiss.
                    // Placed ABOVE the content and BELOW the popover (popover is added later in the ZStack).
                    if presented != nil {
                        Color.clear
                            .ignoresSafeArea()
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation { selection = nil }
                            }
                    }
                }
            
            if let id = presented {
                popover(id)
                    .matchedGeometryEffect(
                        id: id,
                        in: ns,
                        properties: .position,
                        anchor: sourceAnchor(id).opposite,
                        isSource: false
                    )
                    .transition(
                        .opacity.combined(with: .scale.combined(with: .blurReplace))
                        .animation(.bouncy(duration: 0.3))
                    )
            }
        }
        .environment(\.matchedPopoverNamespace, ns)
        .onAppear {
            // Keep internal state in sync on first render.
            presented = selection
        }
        .onChange(of: selection) { _, newValue in
            applySelection(newValue)
        }
    }
    
    private func applySelection(_ newValue: ID?) {
        guard let newValue else {
            withAnimation {
                presented = nil
            }
            return
        }
        
        // If nothing is shown, present immediately.
        guard let current = presented else {
            withAnimation {
                presented = newValue
            }
            return
        }
        
        // If same, no-op.
        if current == newValue { return }
        
        // Always hide first, then show the new one.
        withAnimation {
            presented = nil
        } completion: {
            withAnimation {
                presented = newValue
            }
        }
    }
}

private extension UnitPoint {
    /// Returns an opposite anchor suitable for pairing a source anchor with a popover anchor.
    /// For example: `.bottom` -> `.top`, `.topLeading` -> `.bottomTrailing`.
    var opposite: UnitPoint {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        case .topLeading: return .bottomTrailing
        case .topTrailing: return .bottomLeading
        case .bottomLeading: return .topTrailing
        case .bottomTrailing: return .topLeading
        case .center: return .center
        default:
            // For custom anchors, we can't reliably infer an opposite.
            // Fall back to `.center`.
            return .center
        }
    }
}

// MARK: - Environment

private extension EnvironmentValues {
    /// Shared namespace for `matchedGeometryEffect` between sources and the overlay popover.
    @Entry var matchedPopoverNamespace: Namespace.ID? = nil
}

// MARK: - Demo

#Preview {
    struct PopoverView: View {
        
        enum PopoverTarget: String {
            case view1
            case view2
            case view3
            
            var anchor: UnitPoint {
                switch self {
                case .view1: .leading
                case .view2: .top
                case .view3: .bottom
                }
            }
        }
        
        @State private var selection: PopoverTarget?
        
        var body: some View {
            VStack(spacing: 40) {
                HStack {
                    Spacer()
                    button(.view1)
                        .matchedPopoverSource(
                            id: PopoverTarget.view1,
                            anchor: PopoverTarget.view1.anchor
                        )
                        .padding()
                }
                
                button(.view2)
                    .matchedPopoverSource(
                        id: PopoverTarget.view2,
                        anchor: PopoverTarget.view2.anchor
                    )
                
                button(.view3)
                    .matchedPopoverSource(
                        id: PopoverTarget.view3,
                        anchor: PopoverTarget.view3.anchor
                    )
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea()
            .matchedPopover(
                selection: $selection,
                anchor: { $0.anchor }
            ) { id in
                Text("Popover: \(String(describing: id))")
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 16))
                    .padding()
            }
        }
        
        private func button(_ target: PopoverTarget) -> some View {
            Button(target.rawValue) {
                selection = (selection == target) ? nil : target
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    return PopoverView()
}
