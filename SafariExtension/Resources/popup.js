document.addEventListener("DOMContentLoaded", () => {
	// Load saved options and set up initial state
	loadOptions();
});



function loadOptions() {
	browser.storage.sync.get("config", function (result) {

		let keyList = document.getElementById("key-list")
		let keyResult = result.config.keys || []

		keyResult.forEach((keyValue, index) => {
			const listItem = document.createElement("li");
			listItem.textContent = keyValue;

			const removeBtn = document.createElement("button");
			removeBtn.type = "button";
			removeBtn.textContent = "x";
			removeBtn.className = "removeBtn";
			removeBtn.addEventListener("click", () => {
				keyList.removeChild(listItem);
			});

			listItem.appendChild(removeBtn);
			keyList.appendChild(listItem);
		})


		// 处理获取到的 result
		console.log(result);
		document.getElementById("url").value = result.config.url || "https://push.uuneo.com"
		document.getElementById("sound").value = result.config.sound || "success"
		document.getElementById("group").value = result.config.group || "Safari"
		document.getElementById("level").value = result.config.level || "active"

	});
}

document.getElementById("add-key").addEventListener("click", () => {
	const keyInput = document.getElementById("key-input");
	const keyList = document.getElementById("key-list");
	const keyValue = keyInput.value.trim();

	if (!keyValue) {
		message("Invalid key");
		return;
	}

	const existingKeys = Array.from(keyList.children).map(
														  (li) => li.firstChild.textContent
														  );
	if (existingKeys.includes(keyValue)) {
		message("key repeat");
		return;
	}

	const listItem = document.createElement("li");
	listItem.textContent = keyValue;

	const removeBtn = document.createElement("button");
	removeBtn.type = "button";
	removeBtn.textContent = "X";
	removeBtn.addEventListener("click", () => {
		keyList.removeChild(listItem);
	});
	removeBtn.className = "removeBtn";
	listItem.appendChild(removeBtn);
	keyList.appendChild(listItem);
	keyInput.value = "";
});

document.getElementById("config-form").addEventListener("submit", (e) => {
	e.preventDefault();
	const keys = Array.from(document.getElementById("key-list").children).map(
																			  (li) => li.firstChild.textContent
																			  );
	const config = {
		url: document.getElementById("url").value,
		keys: keys,
		sound: document.getElementById("sound").value,
		group: document.getElementById("group").value,
		level: document.getElementById("level").value,
	};
	browser.storage.sync.set({
		config: config,
	});
	message("Save OK!");
});



function message(msg) {
	const popup = document.getElementById("iframe-container");

	// 设置消息内容并显示弹窗
	popup.textContent = msg;
	popup.style.display = "block";

	// 1秒后自动隐藏弹窗
	setTimeout(() => {
		popup.style.display = "none";
	}, 1000); // 1000 毫秒 = 1 秒
}
