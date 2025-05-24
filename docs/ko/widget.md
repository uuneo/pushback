## 위젯 내 설정 업데이트 주소, GET 요청 방식으로 다음 형식의 내용을 반환해야 합니다
```Json
{
  "large" : { // 대형 위젯
    "result" : [ 
      {
        "group" : "총계",
        "lines" : [
          13495
        ],
        "result" : [ // 데이터 길이 고정되지 않음
          {
            "name" : "예시1",
            "sort" : 0,
            "unity" : 1000,
            "value" : 10999
          },
          // ...  나머지 동일한 형식
        ],
        "sort" : 0,
        "type" : "pie"
      },
      {
        "group" : "예시1",
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
           // ...  나머지 동일한 형식
        ],
        "sort" : 1
      },
       // ...  나머지 동일한 형식
    ],
    "subTitle" : "총 64건 수신",
    "title" : "PUSHBACK"
  },
  "lock" : { // 잠금 화면 위젯
    "subTitle" : "총 64건 수신",
    "title" : "PUSHBACK"
  },
  "medium" : { // 중형 위젯
    "result" : [ // 배열 길이 6
      {
        "name" : "총계",
        "value" : 18
      },
     // 배열 길이 6, 나머지 2개 데이터 동일
    ],
    "subTitle" : "총 64건 수신",
    "title" : "PUSHBACK"
  },
  "small" : {// 소형 위젯
    "result" : [  // 배열 길이 3
      {
        "name" : "총계",
        "value" : 18
      },
     // 배열 길이 3, 나머지 2개 데이터 동일
    ],
    "subTitle" : "총 64건 수신",
    "title" : "PUSHBACK"
  }
}


```