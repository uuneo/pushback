## Widget Update Address Settings, GET request method should return the following format
```Json
{
  "large" : { // Large widget
    "result" : [ 
      {
        "group" : "Total",
        "lines" : [
          13495
        ],
        "result" : [ // Variable data length
          {
            "name" : "Example 1",
            "sort" : 0,
            "unity" : 1000,
            "value" : 10999
          },
          // ...  remaining items follow the same pattern
        ],
        "sort" : 0,
        "type" : "pie"
      },
      {
        "group" : "Example 1",
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
           // ...  remaining items follow the same pattern
        ],
        "sort" : 1
      },
       // ...  remaining items follow the same pattern
    ],
    "subTitle" : "Total received 64 items",
    "title" : "PUSHBACK"
  },
  "lock" : { // Lock screen widget
    "subTitle" : "Total received 64 items",
    "title" : "PUSHBACK"
  },
  "medium" : { // Medium widget
    "result" : [ // Array length 6
      {
        "name" : "Total",
        "value" : 18
      },
     // Array length 6, remaining 2 items follow the same pattern
    ],
    "subTitle" : "Total received 64 items",
    "title" : "PUSHBACK"
  },
  "small" : {// Small widget
    "result" : [  // Array length 3
      {
        "name" : "Total",
        "value" : 18
      },
     // Array length 3, remaining 2 items follow the same pattern
    ],
    "subTitle" : "Total received 64 items",
    "title" : "PUSHBACK"
  }
}


```