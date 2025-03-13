//
// AvatarView.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//


import SwiftUI
import Defaults



struct AvatarView: View {
	
	var id:String?
	var icon:String?
    var customIcon:String = ""
	
	@Default(.appIcon) var appicon
	
	@State private var success:Bool = true
	@State private var image: UIImage?
	
	var body: some View {
		GeometryReader {
			let size = $0.size
			
			VStack{
                
               
                if let icon = icon, success, customIcon.isEmpty{
                    if let image = image {
                        // 如果已经加载了图片，则显示图片
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: size.width, height: size.height)

                    } else {
                        // 如果图片尚未加载，则显示加载中的视图
                        ProgressView()
                            .frame(width: size.width, height: size.height)
                            .onAppear{
                                loadImage(icon: icon)
                            }
                        
                    }
                }else{
                    if !customIcon.isEmpty{
                        Image(customIcon)
                            .resizable()
                            .frame(width: size.width, height: size.height)
                    }else{
                        Image(appicon.logo)
                            .resizable()
                            .frame(width: size.width, height: size.height)
                    }
                   
                }
				
				
			}
			.aspectRatio(contentMode: .fill )
			.onReceive(NotificationCenter.default.publisher(for: .imageUpdate)) { result in
				if let name = result.userInfo?["name"] as? String, name == icon {
					Log.debug("收到头像更新",name , icon ?? "")
					self.loadImage(icon: name)
					
				}
			}
			.onChange(of: icon) { value in
				self.image = nil
			}


			
		}
		
		
	}
	
	private func loadImage(icon:String ) {
		self.success = true
        
		Task.detached(priority: .background)  {
			if let localPath = await ImageManager.downloadImage(icon) {
				await MainActor.run {
					self.image = UIImage(contentsOfFile: localPath)
				}
			} else {
				await MainActor.run {
					self.success = false
				}
			}
		}
		
	}
}
