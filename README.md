![Swift](https://github.com/markiv/Fondue/workflows/Swift/badge.svg)

# Fondue 🫕

A library of delightfully light extensions to simplify working with SwiftUI and Combine in real-world apps.

## Literal URLs
`URL` is now `ExpressibleByStringLiteral`, so we can conveniently express them like this:

```swift
let url: URL = "https://server.domain/path"
```

We've deliberately restricted this to *literal* strings, since it's reasonable to expect that they're as free of typos as your code. 😉

## URL Parameters
We've taught URL to deal with query parameters like a dictionary[^1]:

```swift
url.parameters["query"] = "fondue"
```

[^1]: Strictly speaking, URLs can have multiple parameters with the same name (e.g. `a=1&a=2`), and some server-side frameworks gather these into arrays. But in many real-life projects, we think of each parameter as uniquely-named. If this is also your case, you might find it more convenient to treat query parameters just like a dictionary.


## URL & URLRequest Modifiers
Inspired by SwiftUI's extensive use of modifiers, we've given a few to URL and URLRequest:

```swift
let base: URL = "https://server.domain/api"
let url = base.with(parameters: ["query": "fondue"])
 
let request = url.request(.post, path: "path")
    .adding(parameters: ["page": 1])
```

## ObservableProcessor
A convenient way to provide asynchronous data to a View. It publishes the output, busy and error states so that they can be bound to a View.

```swift
struct SomeView: View {
    @StateObject var model = ObservableProcessor { SomeAPI.get() }
    
    var body: some View {
        List(model.output ?? []) { item in
            :
        }
    }
}
```
