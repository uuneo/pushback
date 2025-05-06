//
//  SpeakSettingsView.swift
//  pushback
//
//  Created by lynn on 2025/5/14.
//
import SwiftUI
import Defaults

struct SpeakSettingsView:View {
    @Default(.ttsConfig) var voiceConfig
  
    @Default(.voiceList) var voiceList
    
    @Default(.voicesAutoSpeak) var voicesAutoSpeak
    @Default(.voicesAutoPreloading) var voicesAutoPreloading
    
    var groupedVoices: [String: [VoiceManager.MicrosoftVoice]] {
        if searchText.isEmpty {
            return Dictionary(grouping: voiceList, by: { $0.locale })
        } else {
            let query = searchText.lowercased()

            let results = voiceList.filter { voice in
                voice.displayName.lowercased().contains(query)
                || voice.localName.lowercased().contains(query)
                || voice.shortName.lowercased().contains(query)
                || voice.gender.lowercased().contains(query)
                || voice.locale.lowercased().contains(query)
                || voice.localeName.lowercased().contains(query)
            }

            return Dictionary(grouping: results, by: { $0.locale })
        }
    }

    
    @State private var showVoiceSelect:Bool = false
    @State private var showFormatSelect:Bool = false
    @State private var searchText:String = ""
    var body: some View {
        Form{
            
            Section {
                Toggle(isOn: $voicesAutoSpeak) {
                    Label("自动播放", systemImage: "memories")
                }
                
                Toggle(isOn: $voicesAutoPreloading) {
                    Label("提前生成", systemImage: "arrow.down.square")
                }
            }header:{
                Text("下拉自动播放语音")
            }footer: {
                Text("提前生成会影响推送时效")
            }
            .textCase(.none)
            
            
            Section("语音服务区域") {
                baseRegionField
            }
            .textCase(.none)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            
            Section("默认语音") {
                baseVoiceField
                    .pressEvents( onRelease: { _ in
                        self.showVoiceSelect.toggle()
                        return true
                    })
            }
            .textCase(.none)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            
            Section("默认语速，范围 -100 到 100") {
                baseRateField
            }
            .textCase(.none)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            
            Section("默认语调，范围 -100 到 100") {
                basePitchField
            }
            .textCase(.none)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            Section("默认音频格式") {
                baseFormatField
                    .pressEvents(onRelease: {_ in
                        showFormatSelect.toggle()
                        return true
                    })
            }
            .textCase(.none)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
        
        }
        .navigationTitle("语音配置")
        .sheet(isPresented: $showVoiceSelect) { VoiceSelectView() }
        .sheet(isPresented: $showFormatSelect) {
            NavigationStack{
                Picker("选择格式", selection: $voiceConfig.defaultFormat) {
                    ForEach(VoiceManager.AudioFormat.allCases, id: \.rawValue) { item in
                        Text("\(item.rawValue)")
                            .foregroundStyle(voiceConfig.defaultFormat == item ? .green : .gray)
                            .tag(item)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("默认音频格式")
                .navigationBarTitleDisplayMode(.inline)
            }.presentationDetents([.height(300)])
               
        }
        
    }
    
    @ViewBuilder
    func VoiceSelectView() -> some View{
        NavigationStack{
            ScrollViewReader {  proxy in
                ScrollView{
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedVoices.keys.sorted(), id: \.self ){locale in
                            
                            Section {
                                ForEach(groupedVoices[locale]!,id: \.id){ item in
                                    HStack{
                                        Text("\(item.localName)")
                                            .padding(.horizontal)
                                            .fontWeight(item.shortName == voiceConfig.defaultVoice ? .bold : .light)
                                        Text("(\(item.gender))")
                                        Spacer()
                                    }
                                    .padding(20)
                                    .background(
                                        item.shortName == voiceConfig.defaultVoice ? Color.green : Color.gray.opacity(0.1)
                                    )
                                    .id(item.shortName)
                                    .pressEvents(onRelease: { _ in
                                        voiceConfig.defaultVoice = item.shortName
                                        self.showVoiceSelect.toggle()
                                        return true
                                    })
                                    
                                }
                            } header: {
                                HStack{
                                    Spacer()
                                    Text(locale)
                                        .fontWeight(.black)
                                        .padding(.trailing)
                                        .foregroundStyle(.orange)
                                        .blendMode(.difference)
                                }
                            }
                            
                            
                        }
                    }
                    if voiceList.count == 0{
                        ProgressView {
                            Label("加载中", systemImage: "ellipsis")
                        }
                    }
                }
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                    }
                }
                .task(priority: .background, {
                    do{
                        let client = try VoiceManager()
                        _ = try await client.listVoices()
                        withAnimation {
                            proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                        }
                    }catch{
                        debugPrint(error)
                    }
                })
                .navigationTitle("选择语音模型")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Image(systemName: "gobackward")
                            .pressEvents(onRelease: {_ in
                                Defaults.reset(.voiceList)
                                Task{
                                    do{
                                        let client = try VoiceManager()
                                        _ = try await client.listVoices()
                                        
                                        withAnimation {
                                            proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                                        }
                                        
                                    }catch{
                                        debugPrint(error)
                                    }
                                }
                                return true
                            })
                    }
                }
            }
            .searchable(text: $searchText)
            
        }
    }
    
    private var baseRegionField: some View {
        TextField("Region", text: $voiceConfig.region)
            .autocapitalization(.none)
            .customField(
                icon: "atom"
            )
    }
    
    private var baseVoiceField: some View {
        TextField("Voice", text: $voiceConfig.defaultVoice)
            .autocapitalization(.none)
            .disabled(true)
            .customField(
                icon: "speaker.wave.2.bubble.left"
            )
    }
    
    private var baseRateField: some View {
        TextField("Rate", text: $voiceConfig.defaultRate)
            .autocapitalization(.none)
            .customField(
                icon: speedIcon(voiceConfig.defaultRate)
            ).onChange(of: voiceConfig.defaultRate) { newValue in
                voiceConfig.defaultRate = inputHandler(newValue)
            }
    }
    
    private var basePitchField: some View {
        TextField("Pitch", text: $voiceConfig.defaultPitch)
            .autocapitalization(.none)
            .customField(
                icon: speedIcon(voiceConfig.defaultPitch)
            )
            .onChange(of: voiceConfig.defaultPitch) { newValue in
                voiceConfig.defaultPitch = inputHandler(newValue)
            }
    }
    
    private var baseFormatField: some View {
        TextField("Format", text: Binding(get: {  voiceConfig.defaultFormat.rawValue }, set: { _ in}))
            .autocapitalization(.none)
            .disabled(true)
            .customField(
                icon: "paintbrush"
            )
    }
    
    func speedIcon(_ newValue:String)->String{
        
        
        if let value = Int(newValue) {
            if value < -50{
                return "gauge.low"
            }else if value > 50{
                return "gauge.high"
            }else{
                return "gauge.medium"
            }
        }
        return "gauge.medium"
    }
    
    func inputHandler(_ newValue:String)-> String{
        // 允许中间输入为 "-"
        if newValue == "-" { return  newValue }
        
        if let value = Int(newValue) {
            return String(min(max(value, -100), 100))
        } else {
           return  String(newValue.contains("-") ? -1 : 0)
        }
    }
    
}
