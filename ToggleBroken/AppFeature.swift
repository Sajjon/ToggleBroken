//
//  ContentView.swift
//  ToggleBroken
//
//  Created by Alexander Cyon on 2022-03-15.
//


import ComposableArchitecture
import SwiftUI

private let readMe = """
`Toggle` with `toggleStyle` fails to read `isOn`, when the Toggle
is put inside a custom `FullScreen` View (see code) when storing its `content`
as a function (as opposed to as a value) and when the Toggle is pass and
`isOn` binding created with TCA pattern `viewStore.binding(get:send)`.
"""

/// This view breaks toggles using TCA in combination with toggleStyle. but it can be fixed!
///
/// If we replace the stored closure: `let makeContent: () -> Content` with
/// just `let content: Content` which we set (calling `makeContent`) inside init,
/// everything works!
///
/// Based on https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-full-screen-modal-view-using-fullscreencover
/// Wrapping content in this forces any modally presented screen to take up full screen.
public struct ForceFullScreen<Content>: View where Content: View {
	
	public let makeContent: () -> Content
	
	/// SwiftUI's view seems to be marking their init as`@inlinable` and letting
	/// content building function be `@ViewBuilder`. However, we do not know if
	/// SwiftUI stores functions or values since SwiftUI is not open source.
	@inlinable public init(
		@ViewBuilder makeContent: @escaping () -> Content
	) {
		self.makeContent = makeContent
	}
	
	public var body: some View {
		ZStack {
			Color.black.edgesIgnoringSafeArea(.all)
			makeContent()
					.padding()
		}
	}
}

public struct CheckboxToggleStyle: ToggleStyle {
	public init() {}
	public func makeBody(configuration: Configuration) -> some View {
		HStack(alignment: .center, spacing: 16) {
			Image(
				systemName: configuration.isOn ? "checkmark.square" : "square"
			)
			.resizable()
			.frame(width: 22, height: 22)
			.foregroundColor(Color.teal)
			.onTapGesture {
				withAnimation {
					configuration.isOn.toggle()
				}
			}
			
			configuration.label
			Spacer()
		}
	}
}

struct AppState: Equatable {
	var isLoveStarFoxChecked: Bool = true
	var isLoveStreetFighterChecked: Bool = true
}
enum AppAction: Equatable {
	case isLoveStarFoxToggled
	case isLoveStreetFighterToggled
}
struct AppEnvironment {
	init() {}
}
let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, _ in
	switch action {
		
	case .isLoveStarFoxToggled:
		state.isLoveStarFoxChecked.toggle()
		return .none
		
	case .isLoveStreetFighterToggled:
		state.isLoveStreetFighterChecked.toggle()
		return .none
	}
}.debug()

struct AppView: View {
	let store = Store(
		initialState: AppState(),
		reducer: appReducer,
		environment: AppEnvironment()
	)
	
	@State var isForcingFullScreen = true
	
	@State var lovesMetroid = true
	@State var lovesCastlevania = true
	
	var body: some View {
		WithViewStore(store) { viewStore in
			if isForcingFullScreen {
				ForceFullScreen {
					contentWithViewStore(viewStore)
				}
			} else {
				contentWithViewStore(viewStore)
					.padding()
			}
		}
	}
	
	@ViewBuilder
	func contentWithViewStore(_ viewStore: ViewStore<AppState, AppAction>) -> some View {
		let separator = Text("\(String.init(repeating: "=", count: 32))")
		let thinSeparator = Text("\(String.init(repeating: "~", count: 32))")
		VStack {
			Text(readMe).font(.footnote)
			
			Toggle("Wrap in `ForceFullScreen`", isOn: $isForcingFullScreen)
			
			separator
			Text("DEMO OF TOGGLES")
			separator
			Spacer()
			
			Section(
				content: {
					VStack {
						Toggle(isOn: $lovesMetroid) {
							Text("Loves Metroid")
						}
						
						Toggle(isOn: $lovesCastlevania) {
							Text("Loves Castlevania")
						}.toggleStyle(CheckboxToggleStyle())
					}
				},
				header: {
					VStack {
						thinSeparator
						Text("Vanilla SwiftUI").font(.title)
						Text("Using @State and isOn: $theBool`").font(.caption)
						Text("All toggles ALWAYS work.").font(.caption)
						thinSeparator
					}
				}
			)
			
			Section(
				content: {
					VStack {
						
						Toggle(isOn: viewStore.binding(get: \.isLoveStarFoxChecked, send: AppAction.isLoveStarFoxToggled)) {
							Text("Loves StarFox")
						}
						
						VStack(alignment: .leading, spacing: 0) {
							Text(isForcingFullScreen ? "UI doesn't update, turn off 'Wrap in Fullscreen'" : "Can toggle, turn on 'Wrap in Fullscreen' to see bug.")
								.foregroundColor(isForcingFullScreen ? Color.orange : Color.blue)
								.font(.footnote)
							
							Toggle(isOn: viewStore.binding(get: \.isLoveStreetFighterChecked, send: AppAction.isLoveStreetFighterToggled)) {
								Text("Loves Street Fighter")
							}.toggleStyle(CheckboxToggleStyle())
						}
						.padding()
						.border(isForcingFullScreen ? Color.orange : Color.blue, width: 3)
					}
					
				},
				header: {
					VStack {
						thinSeparator
						Text("TCA").font(.title)
						Text("Toggles with `isOn: viewStore.binding(get:set)`").font(.caption)
						Text("'Loves StarFox' toggle works, but 'Loves Street Fighter' does not update UI (but state), it uses `toggleStyle` and when wrapped in `ForceFullScreen` with content from function. If content is computed in init of ForceFullScreen, it works!").font(.caption)
						thinSeparator
					}
				}
			)
		}.foregroundColor(.teal)
	}
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
		AppView()
    }
}
