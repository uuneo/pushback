//
//  ImageCacheView.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//

import SwiftUI
import Defaults



struct ImageCacheView: View {

	@EnvironmentObject private var manager:PushbackManager
	@Default(.photoName) var photoName
	@Default(.images) var images
	@State private var isSelect:Bool = false
	@State private var selectImageArr:[ImageCacheModel] = []
	@State private var showEditPhotoName:Bool = false
	@State private var alart:AlertData?

	@FocusState private var nameFieldIsFocused

	@State private var draggImage:String?

	@State private var imageDetail:ImageCacheModel?

	@State private var imagesData:[Image] = []

	@State private var dragSelectionRect = CGRect.zero

	enum AlertType{
		case delte
		case save
	}

	struct AlertData:Identifiable {
		var id: UUID = UUID()
		var title:String
		var message:String
		var btn:String
		var mode:AlertType
	}

	var columns:[GridItem]{
		if ISPAD{
			Array(repeating: GridItem(spacing: 2), count: 6)
		}else{
			Array(repeating: GridItem(spacing: 2), count: 3)
		}
	}

	var imageSize:CGSize{
		let width = Int(UIScreen.main.bounds.width) / columns.count - 10;
		return CGSize(width: width, height: width)
	}


	var body: some View {

		NavigationStack{

			ScrollView(.vertical, showsIndicators: false){
				LazyVGrid(columns: columns, spacing: 10) {
					PhotoPickerView(draggImage: $draggImage, imageSize: imageSize)

					ForEach( images, id: \.id){ item  in

						uAsyncImage(imageCache: item, size: imageSize) { draggImage = $0}
							.frame(width: imageSize.width,height: imageSize.height)
							.overlay(alignment: .bottomTrailing) {
								if selectImageArr.contains(item){
									Image(systemName: "checkmark.circle")
										.symbolRenderingMode(.palette)
										.foregroundStyle( .green, Color.primary)
										.blendMode(.hardLight)
										.font(.largeTitle)
										.frame(width: 35, height: 35, alignment: .center)
										.background(.ultraThinMaterial)
										.clipShape(Circle())
										.padding(.trailing, 10)
										.padding(.bottom, 10)
								}
							}
							.clipShape(RoundedRectangle(cornerRadius: 10))
							.contentShape((RoundedRectangle(cornerRadius: 10)))
							.onTapGesture {
								if isSelect{
									if selectImageArr.contains(where: {$0 == item}){
										selectImageArr.removeAll(where: {$0 == item})
									}else{
										self.selectImageArr.append(item)
									}

								}else{
									self.imageDetail = item
								}
							}
							.animation(.snappy, value: images)
							.shadow(radius: 3)


					}
				}
				.padding(.horizontal, 10)

			}
			.padding(.bottom, 50)
			.toolbar { toolbarContent() }
			.alert(item: $alart) { value in
				Alert(title: Text(value.title), message: Text(value.message), primaryButton: .cancel(), secondaryButton: .destructive(Text(value.btn), action: {
					switch value.mode{
						case .delte:
							Task.detached {

								if await selectImageArr.count == 0{
									await ImageManager.deleteFilesNotInList(all: true)
								}else{
									for item in await selectImageArr{
										_ = await ImageManager.deleteImage(for: item)
										DispatchQueue.main.asyncAfter(deadline: .now() + 2){
											NotificationCenter.default.post(name: .imageUpdate, object: nil, userInfo: ["name": item])
										}
									}
								}
								await MainActor.run {
									self.selectImageArr = []
								}
								Toast.shared.present(title: value.message, symbol: "photo.badge.checkmark")
							}
						case .save:
							self.saveImage(self.selectImageArr)
					}
					self.isSelect.toggle()
				}))
			}
		}
		.fullScreenCover(item: $imageDetail, content: { item in
			ImageDetailView(image: item,imageUrl: $imageDetail )
				.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
				.background(.ultraThinMaterial)
				.ignoresSafeArea()
				.transition(.slide)
		})
		
	}






	@ToolbarContentBuilder
	private func toolbarContent() -> some ToolbarContent{
		ToolbarItem(placement: .topBarTrailing) {
			Button {
				self.isSelect.toggle()
				self.selectImageArr = []
			} label: {
				Text( isSelect  ? String(localized: "取消") : String(localized: "选择"))
			}.disabled(images.count == 0)
		}

		if isSelect && images.count > 2{
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					if images.count == selectImageArr.count{
						self.selectImageArr = []
					}else{
						self.selectImageArr = images
					}

				} label: {
					Text( images.count == selectImageArr.count ? String(localized:  "取消全选") : String(localized: "全选"))
				}
			}
		}

		if isSelect {
			ToolbarItem(placement: .bottomBar) {
				HStack{

					ShareLink(items: imagesData, subject: Text( "图片"), message: Text( "图片")) { value in
						SharePreview( String(format: String(localized:  "%d张图片"), imagesData.count) , image: value)
					} label: {
						Image(systemName:  "square.and.arrow.up")
					}.disabled(selectImageArr.count == 0 || images.count == 0)



					Spacer()
					Text( selectImageArr.count == 0 ? String(localized: "选择图片") : String(format: String(localized:  "已选择%d张图片"), selectImageArr.count))
						.animation(.snappy, value: selectImageArr.count)
					Spacer()
					Button {
						self.alart = .init(title: String(localized: "危险操作！"), message: selectImageArr.count == 0 ? String(localized: "清空所有") : String(format: String(localized: "删除%d张图片"), selectImageArr.count), btn: String(localized: "删除"), mode: .delte)
					} label: {
						Image(systemName: imagesData.count > 0 ? "trash" : "trash.slash")
					}


					Button {
						self.alart = .init(title: String(localized:"保存图片"), message: String(format: String(localized: "保存%1$d张图片到 %2$@ 相册"), selectImageArr.count, photoName), btn: String(localized: "保存"), mode: .save)
					} label: {
						Image(systemName:  imagesData.count > 0 ? "externaldrive.badge.plus" : "externaldrive.badge.questionmark")
					}.disabled(selectImageArr.count == 0 || images.count == 0)
				}

				.onChange(of: selectImageArr) { newValue in
					loadSharkImages(images: newValue)
				}

			}

		}


	}


	func saveImage(_ items:[ImageCacheModel]){

		Task.detached(priority: .background) {
			for item in items{
				if let fileUrl = item.localPath,
				   let image = UIImage(contentsOfFile: fileUrl.path)
				{
					await image.bat_save(intoAlbum: self.photoName) { success, status in
						debugPrint(success,status)
					}
				}else{
					debugPrint("save errorr")
				}


			}

			await MainActor.run {
				self.selectImageArr = []
			}
		}


	}


	func loadSharkImages(images: [ImageCacheModel]){
		var results:[Image] = []
		Task.detached(priority: .background) {

			for item in images{
				if let fileUrl = item.localPath,
				   let uiimage = UIImage(contentsOfFile: fileUrl.path)
				{
					results.append(Image(uiImage: uiimage))

				}
			}
			await MainActor.run {
				self.imagesData = results
			}
		}
	}






}





#Preview {
	ImageCacheView()
		.environmentObject(PushbackManager.shared)
}
