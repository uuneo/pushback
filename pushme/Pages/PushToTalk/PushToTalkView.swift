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
    @StateObject private var pttManager = PTTManager.shared
    
    @State private var pindao:Int = 0
    @State private var buttonType:TalkButtonType = .call
    
    @State private var historyNumber:Int = 0
    
    @State private var prefixTem:Int = 0
    @State private var suffixTem:Int = 0
    
    @Default(.pttChannel) var pttChannel
    @Default(.pttVibration) var  pttVibration
    @Default(.pttMusicPlay) var  pttMusicPlay
    @Default(.pttVoiceVolume) var  pttVoiceVolume
    @Default(.servers) var servers
    @Default(.pttHisChannel) var pttHisChannel
    
    @State private var showVolume:Bool = false
    @State private var isCancel:Bool = false
    
    @State private var showChannelList:Bool = false
    @State private var showVoiceList:Bool = false
    
    @State private var offset:CGFloat = 0

    var buttonColor: Color{
        if isCancel{
            return pttManager.state == .recording ?  .red : .clear
        }else{
            if ispress{
                return pttManager.state == .recording ?  .green : .orange
            }
            return .clear
        }
    }
    
    private let throttler5 = Throttler(delay: 0.5)
    
    private var topshape: some Shape{
        UnevenRoundedRectangle(topLeadingRadius: 0,
                               bottomLeadingRadius: 35,
                               bottomTrailingRadius: 35,
                               topTrailingRadius: 0)
    }
    
    @State private var isEncryption:Bool = true
    
    @State private var newMessages:Int = 0
    
    var body: some View {
        VStack{
            
            ZStack{

                topshape
                    .fill(
                        LinearGradient(
                            colors: [Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.4, green: 0.8, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.3728182146, green: 0.7853954082, blue: 0, alpha: 1))],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay{
                        if buttonType == .password || pttManager.active {
                            topshape
                                .stroke(.white, lineWidth: 5)
                                .blur(radius: 10)
                        }
                    }
                    .overlay {
                        if !pttManager.active {
                            Color.black
                                .opacity(0.1)
                        }
                        
                    }
                
                
                VStack{
                    HStack{
                        HourAndMinuteView()
                            .font(.numberStyle(size: 25))
                            
                        Spacer()
                        
                        HStack(spacing: 15){
                           
                            Image(systemName: "network" )
                                .symbolVariant(pttManager.active ? .none : .slash)
                                .symbolEffect(.replace)
                                .fontWeight(.bold)
                                .scaleEffect(1.2)
                                .if(true){view in
                                    Group{
                                        if pttManager.active{
                                            view.foregroundStyle(.white)
                                        }else{
                                            view.foregroundStyle(.red,.white)
                                        }
                                    }
                                    
                                }
                            
                            
                            ZStack{
                             
                                Image(systemName: "tray.and.arrow.up" )
                                    .foregroundStyle(.red, .white)
                                    .symbolEffect(.wiggle)
                                    .opacity( pttManager.state == .recording ? 1 : 0)
                                    .offset(x: pttManager.state == .recording ? 0 : 100)
                                    .scaleEffect(1.2)
                                    .offset(y: -3)
                                
                                var showTray:Bool{
                                    pttManager.state == .idle && newMessages <= 0
                                }
                                Image(systemName: "tray")
                                    .foregroundStyle(.white)
                                    .opacity( showTray ? 1 : 0)
                                    .offset(y: showTray ? 0 : -100)
                                    .scaleEffect(1.3)
                                
                                var showTrayFull:Bool{
                                    pttManager.state == .idle && newMessages > 0
                                }
                                Image(systemName: "tray.full")
                                    .foregroundStyle(.white)
                                    .opacity( showTrayFull ? 1 : 0)
                                    .offset(y: showTrayFull ? 0 : -100)
                                    .scaleEffect(1.3)
                                
                                Image(systemName:  "tray.and.arrow.down")
                                    .foregroundStyle(.accent, .white)
                                    .opacity(pttManager.state == .playing ? 1 : 0)
                                    .symbolEffect(.wiggle)
                                    .offset(x: pttManager.state == .playing ? 0 : 100)
                                    .scaleEffect(1.2)
                                    .offset(y: -3)
                                   
                            
                            }
                            
                            .fontWeight(.bold)
                            .animation(.default, value: pttManager.state)
                           
                        }
                        
                    }
                    .padding(.horizontal, 10)
                    .frame( height: 55)
                    .padding(.top, 5)
                    HStack{
                        
                        ChannelUsersView()
                        
                        Spacer(minLength: 0)
                       
                        
                    }
                    Spacer(minLength: 0)
                    HStack{
                        
                        ZStack{
                            Image(systemName: "airpodspro")
                                .foregroundStyle(.white)
                                .font(.title3)
                                .opacity(pttManager.state != .recording ? 1 : 0)
                                .offset(x: pttManager.state != .recording ? 0 : -50)
                                .opacity(self.showVolume ? 0 : 1)
                                .offset(y: self.showVolume ? 20 : 0)
                                .animation(.default, value: showVolume)
                                .VButton( onRelease: { _ in
                                    self.showVolume.toggle()
                                    return true
                                })
                            VStack(spacing: 5){
                                
                                Text(verbatim: String(format: "%.1f", pttManager.elapsedTime))
                                    .font(.numberStyle(size: 28))
                                    .fontWeight(.black)
                                    .lineLimit(1)
                                    .opacity(pttManager.state == .recording ? 1 : 0)
                                    .scaleEffect(pttManager.state == .recording ? 1 : 0.1)
                                    .offset(y: pttManager.state == .recording ? 0 : -30)
                                
                                Text(verbatim: "TIME")
                                    .lineLimit(1)
                                    .opacity(pttManager.state == .recording ? 1 : 0)
                                    .scaleEffect(pttManager.state == .recording ? 1 : 0.1)
                                    .offset(y: pttManager.state == .recording ? 0 : 30)
                                
                            }.foregroundStyle(.white)
                                .minimumScaleFactor(0.5)
                            
                        }.frame(width: 35)
                            .animation(.default, value: pttManager.state == .recording)
                        
                        
                        Spacer()
                        
                        showPrefixAndSuffix()
                        
                        
                        
                        Spacer()
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.title)
                            .foregroundStyle(.white)
                            .VButton { _ in
                                if pttHisChannel.count == 0{
                                    Toast.info(title: "没有历史记录")
                                    return false
                                }
                                self.showChannelList.toggle()
                                return true
                            }
                        
                        
                        
                        
                    }
                    
                    HStack{
                        
                        Spacer(minLength: 0)
                        if !pttManager.active{
                            Text("未启动监听")
                                .foregroundStyle(.white)
                        }else{
                            Text(verbatim: pttManager.state.title)
                                .foregroundStyle(.white)
                        }
                        Spacer(minLength: 0)
                        Image( "music")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(pttMusicPlay ? .black : .white.opacity(0.5))
                            .padding(.horizontal)
                            .VButton { _ in
    
                                self.pttMusicPlay.toggle()
                                return true
                            }
                        
                        Image("vibration")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(pttVibration ? .black : .white.opacity(0.5))
                            .VButton { _ in
                                self.pttVibration.toggle()
                               
                                return true
                            }
                        
                    }
                    .frame(height: 35)
                    .font(.title2)
                    .minimumScaleFactor(0.8)
                    
                    
                    HStack(alignment: .bottom){
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50)
                            .padding(3)
                            .environment(\.colorScheme, pttManager.active ? .light : .dark)
                            .VButton { _ in
                                pttManager.stopPlaying()
                                return true
                            }
                        
                        Spacer(minLength: 0)
                        
                        Picker(selection: $pttChannel.server) {
                            ForEach(servers, id: \.self){server in
                                Text(server.name)
                                    .tag(server)
                            }
                        } label: { Text("切换服务器") }
                            .tint(.black)
                            .pickerStyle(MenuPickerStyle())
                            .onAppear{
                                if pttChannel.server == nil{
                                    pttChannel.server = servers.first
                                }
                            }
                            .offset(x: 10)
                        
                    }
                    Spacer(minLength: 0)
                    VStack{
                        VolumePeakView(micLevel: pttManager.state == .idle ? 0 : pttManager.micLevel)
                    }
                    .frame( height: 5)
                    .padding(.bottom, 5)
                    
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
            }
            .frame(height: 320)
            CenterButtonsView()
            
            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(.gray.opacity(0.3))
            .frame(height: 5)
            .padding(.horizontal)
            
            bottonViews()
            
        }
        .background(.background)
        .ignoresSafeArea(.container, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .overlay{
            
            ZStack(alignment: .topLeading) {
                Color.gray.opacity(0.0001)
                    .VButton( onRelease: { _ in
                        self.showVolume.toggle()
                        return true
                    })
                CustomSlider(
                    sliderProgress: $pttVoiceVolume,
                    symbol: .init(
                        icon: "airpodspro",
                        tint: .white,
                        font: .system(size: 20),
                        padding: 20,
                        display: true,
                        alignment: .bottom
                    ),
                    axis: .vertical,
                    tint: pttVoiceVolume > 0.3 ? .green : .orange
                )
                .frame(width: 40, height:  140)
                .offset(x: 30)
            }
            .opacity(self.showVolume ? 1 : 0)
            .offset(y: self.showVolume ? 0 : -20)
            .onChange(of: pttVoiceVolume) {value in
                pttManager.setDB( Float(value) * 15)
            }
            
        }
        .animation(.default, value: showVolume)
        .environment(\.colorScheme, .dark)
        .customTalkSheet(show: $showVoiceList,
                         size: CGSize(width: windowWidth, height: windowHeight - 170)
        ) {
            
            PTTVoiceListView()
        }
        .customTalkSheet(show: $showChannelList,
                         size: CGSize(width: windowWidth, height: windowHeight - 300)
        ) {
            PTTChannelListView(){ item in
                if !pttManager.active{
                    var item = item
                    item.timestamp = .now
                    Defaults[.pttChannel] = item
                    self.buttonType = .password
                    self.showChannelList = false
                    return true
                }
                self.showChannelList = false
                return false
            }
        }
    }
    
    @ViewBuilder
    func ChannelUsersView() -> some View{
        HStack(alignment: .bottom, spacing: 0){
            
            Text(verbatim: String(format: "%02d",  pttManager.channelUsers))
                .font(.numberStyle(size: 20))
                .offset(y: 2)
                .foregroundStyle( pttManager.channelUsers > 0 ?
                                  Color.white : Color.white.opacity(0.3))
                .fontWeight(.bold)
                .tracking(3)
                .offset(y: pttManager.state == .recording ? 30 : 0)
                .opacity( pttManager.state == .recording ? 0 : 1)
                .animation(.default, value: pttManager.state)
                .animation(.default, value: pttManager.state)
            
            ForEach(Array(0...2), id: \.self) { item in
                Image(systemName: "person")
                    .if(true){ view in
                        Group{
                            if item > pttManager.channelUsers - 1{
                                view
                                    .foregroundStyle(.white.opacity(0.1))
                            }else{
                                view
                                    .foregroundStyle( .black )
                                    .symbolVariant(.fill)
                            }
                            
                        }
                    }
                    .animation(.default, value: pttManager.channelUsers)
                
            }
        }
    }
    
    @ViewBuilder
    func CenterButtonsView() -> some View{
        ZStack{
            HStack{
                Button {
                    withAnimation {
                        self.buttonType = .call
                    }
                    
                    Haptic.impact()
                } label: {
                    Image(systemName: "arrow.backward")
                        .font(.largeTitle)
                        .padding(.leading, 10)
                    
                    
                }
                .transition(.move(edge: .leading))
                .padding(.trailing, 20)
                .offset(x: buttonType ==  .prefix || buttonType == .suffix ? 0 : -100)
                .animation(.easeInOut, value: buttonType)
                Spacer()
                Picker(selection: $buttonType) {
                    ForEach(TalkButtonType.allCases, id: \.self) { item in
                        if item != .call && item != .password{
                            Text(item.rawValue)
                                .tag(item)
                        }
                        
                    }
                }label:{
                    Text(verbatim: "")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                .offset(x: buttonType == .prefix || buttonType == .suffix ? 0 : 100)
            }
            .padding(.horizontal)
            .padding(.top)
            .opacity(buttonType ==  .prefix || buttonType == .suffix ? 1 : 0)
            HStack(spacing: 20){
                
                Image(systemName: "power.circle.fill")
                    .foregroundStyle(pttManager.active ? Color.red.gradient : Color.green.gradient)
                    .font(.system(size: 50))
                    .opacity( buttonType == .call ? 1 : 0)
                    .scaleEffect(buttonType == .call ? 1 : 0.5)
                    .offset(x: buttonType == .call ? 0 : 100)
                    .VButton { _ in
                        selectServerHandler()
                        pttManager.setCategory(true, .playback,mode:  .default)
                        if pttManager.active {
                            let channel = pttHisChannel.first(where: {$0.isActive}) ?? pttChannel
                            self.pttManager.LevalChannel(channel)
                            withAnimation {
                                self.buttonType = .call
                            }
                            return true
                        }
                        withAnimation {
                            self.buttonType = .password
                        }
                        return true
                    }

                Spacer()
                
                Button{
                    self.showVoiceList.toggle()
                    Haptic.impact()
                }label:{
                    Image(systemName: "message.and.waveform")
                        .foregroundStyle(.white, .accent)
                        .font(.largeTitle)
                        .symbolEffect(.variableColor)
                }
                .offset(x: buttonType == .call ? 0 : -100)
                .scaleEffect(buttonType == .call ? 1 : 0.5)

                Spacer(minLength: 0)
                Button{
                    AppManager.shared.router = []
                    Haptic.impact()
                }label: {
                    Image(systemName: "arrow.backward")
                        .font(.largeTitle)
                        .padding(.trailing, 10)
                    
                }.offset(x: buttonType == .call ? 0 : 100)
            }
            .padding(.horizontal, 30)
            .opacity(buttonType == .call ? 1 : 0)
            .animation(.easeInOut, value: buttonType)
            
            
            HStack(spacing: 20){
                
                Button{
                    self.pttManager.JoinChannel(pttChannel)
                    withAnimation {
                        self.buttonType = .call
                    }
                    Haptic.impact()
                }label: {
                    Text( pttChannel.password.isEmpty ? "监听公共频道" : "监听私密频道")
                        .font(.title3)
                        .scaleEffect(buttonType == .password ? 1 : 0.5)
                        .fontWeight(.black)
                        .padding(5)
                        .padding(.horizontal, 10)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(pttChannel.password.isEmpty ? Color.orange :
                                        (pttChannel.password.count == 5 ? Color.green : Color.gray))
                        )
                }
                .offset(x: buttonType == .password ? 0 : -100)
                .disabled(!pttChannel.password.isEmpty && pttChannel.password.count < 5)
                Spacer()
                
                Button{
                    withAnimation {
                        self.buttonType = .call
                    }
                   
                }label: {
                    Text("取消")
                        .foregroundStyle(.white)
                        .padding(3)
                    
                }.offset(x: buttonType == .password ? 0 : 100)
            }
            .padding(.horizontal, 30)
            .opacity(buttonType == .password ? 1 : 0)
            .animation(.easeInOut, value: buttonType)
        }
    }
    
    @ViewBuilder
    func bottonViews() -> some View{
        VStack{
            Spacer(minLength: 0)
            ZStack{
                RotateButtonView {
                    dotColor($0, $1)
                } rotate: { changeTalkChannel($0) }
                    .padding(50)
                    .frame(maxWidth: ISPAD ? minSize / 2 : windowWidth, maxHeight: ISPAD ? minSize / 2 : windowWidth)
                    .scaleEffect(buttonType ==  .prefix || buttonType == .suffix  ? 1 : 0.5)
                    .opacity(buttonType ==  .prefix || buttonType == .suffix  ? 1 : 0)
                
                
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
                    .pbutton($isCancel,
                             $ispress,
                             onBegan: startRecording,
                             onEnded: endRecording,
                             onCancelled: cancelRecording)
                    .disabled(!pttManager.active)
                    
                }
                .frame(maxWidth: ISPAD ? minSize / 2 : windowWidth, maxHeight: ISPAD ? minSize / 2 : windowWidth)
                .animation(Animation.easeInOut(duration: 0.1), value: ispress)
                .scaleEffect(buttonType == .call ? 1 : 0.5)
                .opacity(buttonType == .call ? 1 : 0)
                
                NumberPadPinView()
                    .scaleEffect(buttonType == .password ? 1 : 0.5)
                    .opacity(buttonType == .password ? 1 : 0)
            }
            
            Spacer(minLength: 0)
        }
        
    }
    
    @ViewBuilder
    func showPrefixAndSuffix() -> some View{
        HStack(alignment: .bottom, spacing: 0) {
            Text(verbatim: "\(prefixTem == 0 ? pttChannel.prefix : prefixTem)")
                .foregroundStyle(buttonType == .prefix ? .red : .white)
                .contentShape(Rectangle())
                .VButton { _ in
                    withAnimation {
                        self.buttonType = self.buttonType == .prefix ? .call : .prefix
                    }
                    
                    return true
                }
            
            Text(verbatim: ".")
                .foregroundStyle(.white)
            
            Text(verbatim: "\(suffixTem == 0 ? pttChannel.suffix : suffixTem)")
                .foregroundStyle(buttonType == .suffix ? .red : .white)
                .contentShape(Rectangle())
                .VButton { _ in
                    withAnimation {
                        self.buttonType = self.buttonType == .suffix ? .call : .suffix
                    }
                    return true
                }
        }
        .font(.numberStyle(size: 70))
        .fontWeight(.black)
    }
    /// Numberpad Pin View
    @ViewBuilder
    private func NumberPadPinView() -> some View {
        VStack(spacing: 15) {
            
            HStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 50, height: 50)
                        .overlay {
                            if pttChannel.password.count > index {
                                let index = pttChannel.password.index(pttChannel.password.startIndex, offsetBy: index)
                                let string = String(pttChannel.password[index])
                                
                                Text(string)
                                    .font(.title.bold())
                                    .foregroundStyle(.black)
                            }
                        }
                }
            }
            .padding(.top, 15)
            
            GeometryReader { _ in
                LazyVGrid(columns: Array(repeating: GridItem(), count: 3), content: {
                    ForEach(1...12, id: \.self) { number in
                        if number == 10{
                            Button(action: {
                                if !pttChannel.password.isEmpty {
                                    pttChannel.password.removeLast()
                                }
                                Haptic.impact()
                            }, label: {
                                Image(systemName: "delete.backward")
                                    .font(.title)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .contentShape(.rect)
                            })
                            .tint(.white)
                        }else if number == 11 {
                            
                            Button(action: {
                                if pttChannel.password.count < 5 {
                                    pttChannel.password.append("0")
                                }
                                Haptic.impact()
                            }, label: {
                                Text("0")
                                    .font(.title)
                                    .fontWeight(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .contentShape(.rect)
                            })
                            .tint(.white)
                        }else if number == 12{
                            Button(action: {
                                pttChannel.password = ""
                                Haptic.impact()
                            }, label: {
                                Text("清除")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .contentShape(.rect)
                            })
                            .tint(.white)
                        } else {
                            Button(action: {
                                if pttChannel.password.count < 5 {
                                    pttChannel.password.append("\(number)")
                                }
                                Haptic.impact()
                            }, label: {
                                Text("\(number)")
                                    .font(.title)
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.black)
                                    .padding(.vertical, 20)
                                    .contentShape(.rect)
                            })
                            .tint(.white)
                        }
                        
                    }
                    
                    
                    
                    
                })
            }
        }
        
    }
    
    func startRecording(){
        
        
        if pttVibration{
            Haptic.impact(.heavy)
        }

        if pttMusicPlay{
            pttManager.playTips(.cbegin){
                if !isCancel{
                    pttManager.startTransmitting()
                }
            }
        }else{
            // 解决震动反馈不生效 延迟0.05启动录音
            Task{
                try await Task.sleep(for: .seconds(0.05))
                if !isCancel{
                    pttManager.startTransmitting()
                }
            }
        }
    }
    
    func endRecording(){
        
        pttManager.stopTransmitting()
        if pttMusicPlay{
            pttManager.playTips(.pttnotifyend){}
        }
        
        if pttVibration{
            Haptic.notify(.success)
        }
    }
    
    func cancelRecording(){
        
        pttManager.stopRecording(true)
        if pttMusicPlay{
            pttManager.playTips(.bottle){}
        }
        
        if pttVibration{
            Haptic.notify(.error)
        }
        
    }
    
    
    func changeTalkChannel(_ angle: Int) {
        pttChannel.password = ""
        if angle == 0 {
            switch buttonType {
            case .prefix where prefixTem != 0:
                pttChannel.prefix = prefixTem
                prefixTem = 0
            case .suffix where suffixTem != 0:
                pttChannel.suffix = suffixTem
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
            prefixTem = max(10, min(999, number + pttChannel.prefix))
        case .suffix:
            suffixTem = max(1, min(999, number + pttChannel.suffix))
        case .call, .password:  break
        }
    }
    
    func btnStatus(_ isUP: Bool = true)->Bool{
        if prefixTem == 0 && suffixTem == 0{
            return false
        }
        switch buttonType {
        case .prefix:
            let status = prefixTem > pttChannel.prefix
            return isUP ? status : !status
        case .suffix:
            let status = suffixTem > pttChannel.suffix
            return isUP ? status : !status
        case .call, .password:
            return false
        }
    }
    
    func dotColor(_ upNumber:Int = 0, _ angle: Int) -> Color{
        
        if buttonType == .suffix && (suffixTem >= 999 || suffixTem <= 1) && suffixTem > 0{
            return upNumber == 0 ? .gray : .red
        }else if buttonType == .prefix && (prefixTem >= 999 || prefixTem <= 10) && prefixTem > 0{
            return upNumber == 0 ? .gray : .red
        }
        
        
        let colors: [Color] = [.gray, .green, .cyan, .blue, .yellow, .orange, .red]
        let number = abs(Int(angle / 360)) + upNumber
        let index = number % colors.count
        return colors[index]
    }
    
    func selectServerHandler(){
        if pttChannel.server == nil{
            pttChannel.server = servers.first
        }else if let server = pttChannel.server, !servers.contains(server){
            pttChannel.server = servers.first
        }
    }
}


#Preview {
    PushToTalkView()
}

