//
//  PushToTalkView.swift
//  pushme
//
//  Created by lynn on 2025/7/18.
//
import SwiftUI
import AVFAudio
import Combine
import Defaults


struct PushToTalkView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var ispress:Bool = false
    @StateObject private var talk = talkManager.shared
    
    
    @State private var pindao:Int = 0
    @State private var buttonType:TalkButtonType = .call
    
    @State private var historyNumber:Int = 0
    
    @State private var prefixTem:Int = 0
    @State private var suffixTem:Int = 0
    
    @Default(.talkChannel) var talkChannel
    
    
    @State private var isCancel:Bool = false
    
    @State private var showChannelList:Bool = false
    @State private var showVoiceList:Bool = false
    
    @State private var offset:CGFloat = 0
    var buttonColor:Color{
        ispress && isCancel ? .red : talkType.color
    }
    
    var talkType:TalkType{
        ispress && isCancel ? TalkType.cancel : talk.talkType
    }
    
    private  let throttler5 = Throttler(delay: 0.5)

    
    var body: some View {
        VStack{
            ZStack{
                
                LinearGradient(
                    colors: [Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.4, green: 0.8, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.5, green: 1, blue: 0, alpha: 1))],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .if(true){view in
                    Group{
                        if ISPAD{
                            view
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 20)
                                )
                        }else{
                            view.clipShape(  UnevenRoundedRectangle(topLeadingRadius: 50, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 50)
                            )
                        }
                    }
                }
                .padding(9)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.gray.opacity(0.3), lineWidth: 10)
                
                VStack{
                    Spacer(minLength: 0)
                    HStack{
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .if(talk.talkType == .listen) { view in
                                VStack{
                                    Text(verbatim: "P-P")
                                        .foregroundStyle(.white)
                                    
                                    Text(verbatim: "\(min(Int(talk.micLevel * 100 / 10), 99))")
                                        .font(.title3)
                                }.transition(.opacity)
                            }.frame(width: 50)
                        
                        Spacer()
                        
                        showPrefixAndSuffix()
                            .if(talk.talkType == .listen){ _ in
                                Text(verbatim: "\(formattedElapsedTime(talk.elapsedTime))")
                                    .font(.numberStyle(size: 60))
                                    .fontWeight(.black)
                            }
                        
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.title)
                            .VButton { _ in
                                self.showChannelList.toggle()
                                return true
                            }
                        
                    }
                    .frame(height: 60)
                    
                    HStack{
                        Spacer()
                        if !talk.active{
                            Text(verbatim: TalkType.close.title)
                        }else{
                            Text(verbatim: talkType.title)
                        }
                        
                        Spacer()
                    }
                    .frame(height: 35)
                    .font(.title3)
                    
                    HStack{
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50)
                            .padding(3)
                            .environment(\.colorScheme, talk.active ? .light : .dark)
                            .VButton { _ in
                                self.showVoiceList.toggle()
                                return true
                            }
                        Spacer()
                    }
                    .frame(height: 80)
                    Spacer(minLength: 0)
                    VStack{
                        VolumePeakView(micLevel: talk.micLevel)
                    }.frame(width: self.windowWidth - 70, height: 5)
                        .padding(.bottom, 10)
                    
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                .padding(.top, 60)
                
            }
            .frame(height: 300)
            HStack(spacing: 20){
                
                Button{
                    talk.joinChannel()
                    Haptic.impact()
                }label: {
                    Text( talk.active ? "结束服务" : "开启服务")
                        .font(.title3)
                        .symbolEffect(.replace)
                        .fontWeight(.black)
                        .padding(3)
                        .padding(.horizontal, 10)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(talk.active ? Color.red : Color.green)
                        )
                }
                Spacer()
                Button{
                    talk.playVoice()
                    Haptic.impact()
                }label: {
                    Text("PLAYER")
                        .symbolEffect(.replace)
                        .padding(3)
                }
                Spacer()
                if !ISPAD{
                    Button{
                        AppManager.shared.page = AppManager.shared.oldPage
                        Haptic.impact()
                    }label: {
                        Text("返回")
                            .foregroundStyle(.white)
                            .padding(3)
                        
                    }
                    
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            Spacer(minLength: 0)
            
            bottonViews()
            Spacer(minLength: 0)
        }
        .background(.background)
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(.dark)
        .customTalkSheet(show: $showVoiceList,
                         size: CGSize(width: windowWidth, height: windowHeight - 300)
        ) { PTTVoiceListView() }
        .customTalkSheet(show: $showChannelList,
                         size: CGSize(width: windowWidth, height: windowHeight - 300)
        ) {  PTTChannelListView() }
        
        
    }
    
    @ViewBuilder
    func bottonViews() -> some View{
        if buttonType != .call {
            RotateButtonView {
                dotColor($0, $1)
            } rotate: {changeTalkChannel($0) }
                .padding(.top )
                .frame(width: ISPAD ? windowWidth / 2 : windowWidth,
                       height: ISPAD ? windowWidth / 2 : windowWidth)
                .overlay(alignment: .topLeading) {
                    HStack{
                        Button {
                            withAnimation {
                                self.buttonType = .call
                            }
                            
                            Haptic.impact()
                        } label: {
                            Image(systemName: "arrow.backward")
                                .font(.largeTitle)
                            
                            
                        }
                        .transition(.move(edge: .leading))
                        .padding(.trailing, 20)
                        if buttonType == .suffix{
                            Stepper(value: $talkChannel.suffix, in: 1...999, step: 100
                            ) {
                                pickerButtonType()
                            }
                        }else{
                            Stepper(value: $talkChannel.prefix, in: 10...9999, step: 1000
                            ) {
                                pickerButtonType()
                            }
                        }
                        
                        
                        
                    }.padding(.horizontal)
                    
                    
                }
        }else{
            GeometryReader { proxy in
                let size = proxy.size
                ZStack{
                    Circle()
                        .fill(buttonColor.gradient)
                        .frame(width: size.width / 2, height: size.width / 2)
                        .blur(radius:20)
                    
                    Circle()
                        .stroke(buttonColor.gradient, lineWidth: 50)
                        .padding(50)
                        .blur(radius: 10)
                    
                    Image("voice")
                        .resizable()
                        .renderingMode(ispress ? .template : .original)
                        .frame(width: size.width, height: size.width)
                        .foregroundStyle(.black)
                        .scaleEffect(ispress ? 0.95 : 1)
                    
                    Circle()
                        .stroke(buttonColor.gradient, lineWidth: 20)
                        .padding(35)
                        .blur(radius: 10)
                    Circle()
                        .stroke(buttonColor, lineWidth: 15)
                        .padding(30)
                    
                    Text(verbatim: "PTT")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(ispress ? buttonColor  : .white)
                        .scaleEffect(ispress ? 1.2  : 1)
                }
                .pbutton($isCancel,$ispress,
                         onBegan: startRecording,
                         onEnded: endRecording,
                         onCancelled: cancelRecording)
                
                
            }
            .frame(width: ISPAD ? windowWidth / 2 : windowWidth, height: ISPAD ? windowWidth / 2 : windowWidth)
            .animation(Animation.easeInOut(duration: 0.1), value: ispress)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
         
            
        }
            
    }
    
    @ViewBuilder
    func showPrefixAndSuffix() -> some View{
        HStack(alignment: .bottom, spacing: 0) {
            Text(verbatim: "\(prefixTem == 0 ? talkChannel.prefix : prefixTem)")
                .foregroundStyle(buttonType == .prefix ? .red : .primary)
                .VButton { _ in
                    withAnimation {
                        self.buttonType = self.buttonType == .prefix ? .call : .prefix
                    }
                    
                    return true
                }
            
            Text(verbatim: ".")
            
            Text(verbatim: "\(suffixTem == 0 ? talkChannel.suffix : suffixTem)")
            //                                .contentTransition(.numericText())
                .foregroundStyle(buttonType == .suffix ? .red : .primary)
                .VButton { _ in
                    withAnimation {
                        self.buttonType = self.buttonType == .suffix ? .call : .suffix
                    }
                    return true
                }
        }
        .font(.numberStyle(size: 60))
        .fontWeight(.black)
    }
    
    @ViewBuilder
    func pickerButtonType()-> some View{
        Picker(selection: $buttonType) {
            ForEach(TalkButtonType.allCases, id: \.self) { item in
                if item != .call{
                    Text(item.rawValue)
                        .tag(item)
                }
                
            }
        }label:{
            Text(verbatim: "")
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 150)
        
    }
    
    func startRecording(){
        guard talk.talkType == .space else { return }
        talk.talkType = .ready
        Haptic.impact(.rigid)
        talk.setCategoryForPlayAndRecord()
        talk.prepareEngine()
        
        talk.playTips(.cbegin){
            if !isCancel{
                
                talk.startAudioEngine()
            }
        }
    }
    
    func endRecording(){
  
        talk.stopEngine(){
            talk.playTips(.pttnotifyend)
            Haptic.notify(.success)
        }
        
        
    }
    
    func cancelRecording(){
        talk.stopEngine(){
            talk.playTips(.bottle)
            Haptic.notify(.error)
        }
        
    }

    func changeTalkChannel(_ angle: Int) {
        if angle == 0 {
            switch buttonType {
            case .prefix where prefixTem != 0:
                talkChannel.prefix = prefixTem
                prefixTem = 0
            case .suffix where suffixTem != 0:
                talkChannel.suffix = suffixTem
                suffixTem = 0
            default:
                break
            }
            return
        }
        
        let value = abs(angle / 360)
        let number: Int = {
            if value == 0 {
                return angle / 10
            } else if angle < 0 {
                return (angle + 360) / 3 - 36
            } else {
                return (angle - 360) / 3 + 36
            }
        }()
        
        guard number != historyNumber else { return }
        historyNumber = number
        Haptic.selection()
        
        switch buttonType {
        case .prefix:
            prefixTem = max(10, min(9999, number + talkChannel.prefix))
        case .suffix:
            suffixTem = max(1, min(999, number + talkChannel.suffix))
        case .call:  break
        }
    }
    
    func btnStatus(_ isUP: Bool = true)->Bool{
        if prefixTem == 0 && suffixTem == 0{
            return false
        }
        switch buttonType {
        case .prefix:
            let status = prefixTem > talkChannel.prefix
            return isUP ? status : !status
        case .suffix:
            let status = suffixTem > talkChannel.suffix
            return isUP ? status : !status
        case .call:
            return false
        }
    }
    
    func formattedElapsedTime(_ elapsedTime: TimeInterval) -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let fraction = Int((elapsedTime - floor(elapsedTime)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, fraction)
    }
    
    func dotColor(_ upNumber:Int = 0, _ angle: Int) -> Color{
        
        if buttonType == .suffix && (suffixTem >= 999 || suffixTem <= 1) && suffixTem > 0{
            return upNumber == 0 ? .gray : .red
        }else if buttonType == .prefix && (prefixTem >= 9999 || prefixTem <= 10) && prefixTem > 0{
            return upNumber == 0 ? .gray : .red
        }
        
        
        let colors: [Color] = [.gray, .green, .cyan, .blue, .yellow, .orange, .red]
        let number = abs(Int(angle / 360)) + upNumber
        let index = number % colors.count
        return colors[index]
    }
}



#Preview {
    PushToTalkView()
}



