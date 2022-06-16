<h1 align="center">
  <br>
  <img src="https://user-images.githubusercontent.com/130319/146201564-2bb3680e-38d1-471b-a487-25f416582d71.jpg" alt="mocap4face by alter" width="50%"></a>
  <br>
  mocap4face by <a href="https://twitter.com/alterz">alter</a>
  <br>
</h1>

mocap4face by [alter](https://twitter.com/alterz) is a free, multiplatform SDK for real time facial motion capture based on Facial Action Coding System or ([FACS](https://en.wikipedia.org/wiki/Facial_Action_Coding_System)). It provides real-time FACS-derived blendshape coefficients, and rigid head pose in 3D space from any mobile camera, webcam, photo, or video enabling live animation of 3D avatars, digital characters, and more.

After fetching the input from one of the mentioned sources, mocap4face SDK produces data in [ARKit-compatible](https://developer.apple.com/documentation/arkit/arfaceanchor/blendshapelocation) blendshapes, i.e., [morph targets](https://en.wikipedia.org/wiki/Morph_target_animation) weight values as a per-frame expression shown in the video below. Useful for, e.g., animating a 2D or 3D avatar in a way that mimics the user's facial expressions in real-time à la Apple Memoji but without the need of a hardware-based TrueDepth Camera.

With mocap4face, you can drive live avatars or NFT PFPs, build Snapchat-like lenses, AR experiences, face filters that trigger actions, VTubing apps, and more with as little energy impact and CPU/GPU use as possible. As an example, check out how the popular avatar live-streaming app [REALITY](https://reality.app/) is using our SDK.

Please star us ⭐⭐⭐ on GitHub—it motivates us a lot!

<img src="https://user-images.githubusercontent.com/130319/146201622-9356c7bb-b8fe-437a-bc26-c1089383b921.gif" width="100%">

# 📋 Table of Content

- [Tech Specs](#-tech-specs)
- [Installation](#-installation)
- [Use Cases](#-use-cases)
- [License](#-license)
- [Links](#️-links)

# 🤓 Tech Specs

- Platforms
- - iOS
- - Android
- - Web
- [3D reprojection to the input photo/video](https://studio.facemoji.co/docs/Re-projecting-3D-Faces-for-Augmented-Reality_a2d9e35a-3d9a-4fd1-b58a-51db06139d4d)
- Platform-suited API and packaging with internal optimizations
- Simultaneous back and front camera support

### ✨ Key Features
- `42` tracked facial expressions via blendshapes
- Eye tracking including eye gaze vector
- Tongue tracking
- Light & fast, just `3MB` ML model size
- `≤ ±50°` pitch, `≤ ±40°` yaw and `≤ ±30°` roll tracking coverage

### 🤳 Input

- All RGB camera
- Photo
- Video

### 📦 Output

- ARKit-compatible blendshapes
- Head position and scale in 2D and 3D
- Head rotation in world coordinates

### ⚡ Performance

- `50 FPS` on Pixel 4
- `60 FPS` on iPhone SE (1st gen)
- `90 FPS` on iPhone X or newer

# 💿 Installation

### Prerequisites

1. Create a dev account at [studio.facemoji.co](https://studio.facemoji.co)
2. Generate a unique API key for your app
3. Paste the API key to your source code

### iOS

1. Open the sample XCode project and run the demo on your iOS device
2. To use the SDK in your project, either use the bundled XCFramework directly or use the Swift Package manager (this repository also serves as a Swift PM repository)

### Android

1. Open the sample project in Android Studio and run the demo on your Android device
2. Add this repository to the list of your Maven repositories in your root `build.gradle`, for example:

```
allprojects {
    repositories {
        google()
        mavenCentral()
        // Any other repositories here...

        maven {
            name = "Facemoji"
            url = uri("https://facemoji.jfrog.io/artifactory/default-maven-local/")
        }
    }
}
```

3. To use the SDK in your project, add `implementation 'co.facemoji:mocap4face:0.3.0'` to your Gradle dependencies

### Web

1. Open the sample project under js-example in an editor of your choice
2. Run `npm install && npm run dev` to start a local server with the demo
3. Run `npm install && npm run dev_https` to start a local server with self-signed HTTPS support
4. Run `npm install @facemoji/mocap4face` in your own project to add mocap4face as a dependency

If the webcamera button is not working, you might need to use HTTPS for the local dev server.
Run `npm run dev_https` and allow the self-signed certificate in the browser to start the demo in HTTPS mode.

You can also run `npm run build` to create a production bundle of the demo app.

# 🚀 Use Cases

- AR for NFTs profile pics
- Live avatar experiences
- Snapchat-like lense
- AR experiences
- VTubing apps
- Live streaming apps
- Face filters
- AR games with facial triggers
- Beauty AR
- Virtual try-on
- Play to earn games

# ❤️ Links

- [FAQ](https://studio.facemoji.co/docs/FAQ_6b345137-5916-4017-b444-9d15398c8af0)
- [Blog post](https://studio.facemoji.co/docs/Introducing-mocap4face-SDK_a660c539-b3fb-4f0b-a38e-3f4e850a5769)
- [Facemoji Studio](https://studio.facemoji.co)
- [Twitter](https://twitter.com/alterz)
- [Discord](https://discord.gg/alterz)
- [Website](https://facemoji.co)

# 📄 License

This library is provided under the Facemoji SDK License Agreement—see [LICENSE](LICENSE.md). Also make sure to check out
our [FAQ](https://studio.facemoji.co/docs/FAQ_6b345137-5916-4017-b444-9d15398c8af0) for more details.

The sample code in this repository is provided under the [Facemoji Samples License](ios-example/LICENSE.md).

# 🙏 Notices

OSS used in mocap4face SDK:

- [Tensorflow + Tensorflow Lite](https://github.com/tensorflow/tensorflow/blob/master/LICENSE)
- [kotlinx-collections-immutable](https://github.com/Kotlin/kotlinx.collections.immutable/blob/master/LICENSE.txt)
- [kotlinx-serialization](https://github.com/Kotlin/kotlinx.serialization/blob/master/LICENSE.txt)
- [kotlinx-coroutine](https://github.com/Kotlin/kotlinx.coroutines/blob/master/LICENSE.txt)
- [benasher44/uuid](https://github.com/benasher44/uuid/blob/master/LICENSE)
- [Stately](https://github.com/touchlab/Stately/blob/main/LICENSE.txt)
- [okhttp](https://square.github.io/okhttp/#license)

Original [video](https://vimeo.com/125095515) by LaBeouf, Rönkkö & Turner.


This library transitively uses open source software, see the full list of our [OSS dependencies and license notices](license/README.md).
