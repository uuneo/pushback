browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log("Received request: ", request);
    if (request.greeting === "hello") return Promise.resolve({ farewell: "goodbye" });
});

// 创建右键菜单
createContextMenu();


// 创建菜单的函数
function createContextMenu() {
	const contexts = ["page", "selection", "link", "image", "video", "audio"];
	const contextDic = {
		selection: "word",
		link: "link",
		image: "image",
		video: "video"
	};


	for (let i = 0; i < contexts.length; i++) {
		const context = contexts[i];
		const title = `Pushback-[ ${contextDic[context]} ]`;
		chrome.contextMenus.create({
			title: title,
			contexts: [context],
			id: context,
		});
	}
}


// 通用的点击处理函数
chrome.contextMenus.onClicked.addListener(genericOnClick);


// 处理右键菜单点击事件
function genericOnClick(info) {
	var result = "";

	switch (info.menuItemId) {
	case "image":
		// 处理图片点击
		console.log("图片已点击，地址:", info.srcUrl);
		result = info.srcUrl;
		break;
	case "selection":
		// 处理文字点击
		console.log("选中文字已点击:", info.selectionText);
		result = info.selectionText;
		break;
	case "link":
		// 处理链接点击
		console.log("链接已点击:", info.linkUrl);
		result = info.linkUrl;
		break;
	default:
		console.log("未处理的菜单项点击事件", info);
	}
	console.log("点击结束", info)
	sendToPhone(result, info.menuItemId);

}


function sendToPhone(data, mode) {

	chrome.storage.sync.get("config", (result) => {
		let keys = result.config.keys || [];
		if (!keys || keys.length === 0) {
			return;
		}
		let url = result.config.url || "https://push.uuneo.com";
		let sound = result.config.sound || "success";
		let group = result.config.group || "Safari";
		let level = result.config.level || "active";

		let params = {
			sound: sound,
			group: group,
			level: level,
			title: "Safari+",
			body: mode,
			icon: "https://developer.apple.com/assets/elements/icons/safari-macos-11/safari-macos-11-96x96_2x.png",
		};
		// "page", "selection", "link", "image", "video", "audio"
		if (mode === "page" || mode === "link" || mode === "audio") {
			params.url = data;
		} else if (mode === "image") {
			params.image = data;
		} else if (mode === "video") {
			params.video = data;
		} else {
			params.body = data;
		}

		keys.forEach((key) => {
			makeRequest(url, key, params);
		});
	});
}




// 编写一个请求函数，使用 encodeURIComponent 对参数进行编码
function makeRequest(url, key, params) {
	let urlWithParams = url;

	// 构建查询字符串并对参数进行编码
	const encodedParams = Object.keys(params)
	.map((key) => {
		// 使用 encodeURIComponent 对键和值进行编码
		return `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`;
	})
	.join("&");

	// 拼接 URL 和查询字符串
	urlWithParams = `${url}/${key}?${encodedParams}`;

	// 发送 GET 请求
	fetch(urlWithParams, {
		method: "GET",
		mode: "no-cors",
		headers: {
			"Content-Type": "application/json",
		},
	})
	.then((response) => response.json()).then(console.log).catch(console.log);
}


