//
//  ChangeEmailKeyView.swift
//  pushback
//
//  Created by He Cho on 2024/10/13.
//


import SwiftUI

struct ChangeKeyWithEmailView: View {
	@EnvironmentObject private var manager:PushBackManager
	@State var appear = false
	@State var appearBackground = false
	@State var viewState = CGSize.zero
 
   
	
	var drag: some Gesture {
		DragGesture()
			.onChanged { value in
				viewState = value.translation
			}
			.onEnded { value in
				if value.translation.height > 300 {
					dismissModal()
				} else {
					withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
						viewState = .zero
					}
				}
			}
	}
	var body: some View {
		ZStack {
			Rectangle()
				.fill(.ultraThinMaterial)
				.opacity(appear ? 1 : 0)
				.ignoresSafeArea()
			
			
			GeometryReader { proxy in
				ChnageKeyCenterView()
					.rotationEffect(.degrees(viewState.width / 40))
					.rotation3DEffect(.degrees(viewState.height / 20), axis: (x: 1, y: 0, z: 0), perspective: 1)
					.shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 30)
					.padding(20)
					.offset(x: viewState.width, y: viewState.height)
					.gesture(drag)
					.frame(maxHeight: .infinity, alignment: .center)
					.offset(y: appear ? 0 : proxy.size.height)
					.background(
						Image("Blob 1").offset(x: 170, y: -60)
							.opacity(appearBackground ? 1 : 0)
							.offset(y: appearBackground ? -10 : 0)
							.blur(radius: appearBackground ? 0 : 40)
							.hueRotation(.degrees(viewState.width / 5))
					)
			}
			
			VStack{
				HStack{
					Spacer()
					Button {
						dismissModal()
					} label: {
						Image(systemName: "xmark")
							.font(.system(size: 17, weight: .bold))
							.foregroundColor(.secondary)
							.padding(8)
							.background(.ultraThinMaterial, in: Circle())
					}
					.padding()
					.offset(x: appear ? 0 : 100)
				}
				Spacer()
			}
			
			
			
		   
			
			
		}
		
		.onAppear {
			withAnimation(.spring()) {
				appear = true
			}
			withAnimation(.easeOut(duration: 2)) {
				appearBackground = true
			}
		}
		.onDisappear {
			withAnimation(.spring()) {
				appear = false
			}
			withAnimation(.easeOut(duration: 1)) {
				appearBackground = true
			}
		}
		
	}
	
	
	func dismissModal() {
		withAnimation {
			appear = false
			appearBackground = false
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			manager.fullPage = .none
		}
  
	}
}

#Preview {
	ChangeKeyWithEmailView()
}
