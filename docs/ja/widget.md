## ウィジェット内の更新アドレス設定、GETメソッドで以下の形式のコンテンツを返す必要があります
```Json
{
  "large" : { // 大サイズウィジェット
    "result" : [ 
      {
        "group" : "合計",
        "lines" : [
          13495
        ],
        "result" : [ // データ長は可変
          {
            "name" : "サンプル1",
            "sort" : 0,
            "unity" : 1000,
            "value" : 10999
          },
          // ...  残りは上記と同様
        ],
        "sort" : 0,
        "type" : "pie"
      },
      {
        "group" : "サンプル1",
        "lines" : [
          1834
        ],
        "result" : [
          {
            "name" : "a",
            "sort" : 0,
            "unity" : 1000,
            "value" : 565
          },
           // ...  残りは上記と同様
        ],
        "sort" : 1
      },
       // ...  残りは上記と同様
    ],
    "subTitle" : "合計64件受信",
    "title" : "PUSHBACK"
  },
  "lock" : { // ロック画面ウィジェット
    "subTitle" : "合計64件受信",
    "title" : "PUSHBACK"
  },
  "medium" : { // 中サイズウィジェット
    "result" : [ // 配列長6
      {
        "name" : "合計",
        "value" : 18
      },
     // 配列長6、残り2つのデータは上記と同様
    ],
    "subTitle" : "合計64件受信",
    "title" : "PUSHBACK"
  },
  "small" : {// 小サイズウィジェット
    "result" : [  // 配列長3
      {
        "name" : "合計",
        "value" : 18
      },
     // 配列長3、残り2つのデータは上記と同様
    ],
    "subTitle" : "合計64件受信",
    "title" : "PUSHBACK"
  }
}


```